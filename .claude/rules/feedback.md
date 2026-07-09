# Feedback

Uygulama içi geri bildirim: kategori seçimi, cihaz bilgisi şeffaflığı, gönderim + kullanıcının kendi geçmişi. `lib/features/feedback/`. **Online-only** — local Drift mirror yok; offline'da gönderim yapılamaz.

## Stack
| Bileşen | Yer |
|---------|-----|
| Servis | `FeedbackRemoteService` — `*Repository` DEĞİL, architecture.md online-only naming kuralına göre adlandırıldı |
| Remote source | `FeedbackRemoteSource` (`lib/data/remote/api/feedback_remote_source.dart`) |
| Tablo | `SupabaseConstants.feedbackTable` (`feedback`) |
| UI | `FeedbackScreen` (form + history tab), `FeedbackDeviceInfoSection` |
| Admin tarafı | `admin_feedback_screen.dart` — admin feature'da, burada DEĞİL (admin.md) |

## Veri Modeli
- Kolonlar: `id, user_id, type, subject, message, email?, app_version, platform, status, priority, admin_response, category, assigned_admin_id, internal_note, created_at`
- `FeedbackCategory`: `bug, feature, general` — ikonlar `LucideIcons` (generic UI, anti-pattern #24'e uygun; domain ikonu değil)
- `FeedbackStatus`: `open, in_progress, resolved, closed, unknown` — `unknown` fallback zorunlu (anti-pattern #15/#16)
- `priority`/`assigned_admin_id`/`internal_note` admin-side alanlardır; client bunları YAZMAZ

## Cihaz Bilgisi (şeffaflık sözleşmesi)
- Toplanan: platform + OS sürümü, Dart sürümü, locale, app version + build — hepsi sistem/app tanımlayıcısı
- Toplanmayan: device ID, IMEI, IP, konum — EKLEME (privacy sözleşmesi)
- `FeedbackDeviceInfoSection` gönderilecek bilgiyi kullanıcıya form İÇİNDE gösterir (expandable kart) — gizli telemetri ekleme, kullanıcı ne gittiğini görür

## Gönderim & Geçmiş
- Insert `upsert` ile (data-layer.md § Write Safety); founder bildirimi DB INSERT trigger'ı ile atomik — client ekstra çağrı yapmaz
- History tab: kullanıcının kendi kayıtları (`fetchByUser`, created_at DESC), status badge gösterir
- Admin yanıtı varsa history kartı `feedback.admin_response` göstergesiyle işaretler; detay sheet'i tam `adminResponse` metnini gösterir
- **Rate limit — shipped (2026-07-09, server-side):** `feedback` tablosunda `BEFORE INSERT` trigger (`private.enforce_feedback_rate_limit`, SECURITY DEFINER) kullanıcı başına **saatte 5** gönderimi aşınca insert'i `check_violation` + `FEEDBACK_RATE_LIMIT` marker'ıyla reddeder (migration `20260709120555`). `FeedbackRemoteSource.insert` marker'ı yakalayıp `ValidationException(code: feedback_rate_limit)` fırlatır; `FeedbackFormNotifier` bunu `feedback.rate_limited` l10n mesajına eşler ve Sentry'ye GÖNDERMEZ (beklenen kullanıcı davranışı). Client-side ön-kontrol yok — sunucu authoritative.

## UX
- Email alanı opsiyonel — anonim geri bildirime izin ver
- Submit sırasında çift gönderim guard'ı (forms-validation.md `_submitting` pattern)
- Offline: gönderim engellenir + `errors.network_unavailable`; taslağı sessizce KAYBETME
- L10n kategorisi `feedback.*` (`feedback.bug`, `feedback.feature_request`, `feedback.general`, ...)

## Testing
- `test/data/repositories/feedback_repository_test.dart` (fetchByUser, submit, email handling) + `feedback_remote_source_test.dart`
- Test dosya adı legacy (`feedback_repository_test`) — sınıf adı `FeedbackRemoteService`; yeniden adlandırma yapılacaksa ikisi birlikte

## Anti-Patterns
1. Feedback'e Drift table ekleyip `*Repository`'ye çevirmek (online-only bilinçli — tek kullanıcılı remote resource, architecture.md naming)
2. Cihaz bilgisine PII eklemek (device ID, IP, konum)
3. Kullanıcıya gösterilmeyen alan toplamak (şeffaflık kartı sözleşmesi)
4. `priority`/`internal_note` gibi admin alanlarını client'tan yazmak
5. Status switch'inde `unknown` case atlamak
6. Founder bildirimini client'tan ikinci bir çağrıyla tetiklemek (DB trigger zaten atomik)
7. Feedback içeriğini (subject/message) Sentry'ye/log'a yazmak (observability.md PII)

> **İlgili**: architecture.md § Online-First Exemption (naming), admin.md (feedback yönetimi), forms-validation.md (submit guard), observability.md (PII), localization.md (feedback kategorisi)
