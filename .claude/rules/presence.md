# Presence (Online / Last-Seen)

`UserPresenceService` (`lib/domain/services/presence/`) kullanıcı oturumlarının aktiflik durumunu ve kurulu uygulama sürümünü `user_sessions` tablosu üzerinden yönetir. **Bugünkü tek tüketici admin panelidir** (online kullanıcı görünürlüğü ve build benimsenmesi); kullanıcı-yüzü online rozeti / last-seen UI'ı SHIPPED DEĞİLDİR (bkz. § Unshipped Tasarım Hedefleri). Typing indicator presence'ın değil messaging'in parçasıdır (`typingIndicatorProvider`, messaging.md).

## Stack (gerçek)
| Katman | Bileşen |
|--------|---------|
| Service | `UserPresenceService` — `startSession` / `heartbeat` / `endSession` |
| Controller | `UserPresenceController` (`user_presence_providers.dart`) — `markActive(userId)` / `markInactive()` |
| Constants | `user_presence_constants.dart` (heartbeat/threshold/TTL) |
| Storage | `user_sessions` tablosu — düz PostgREST upsert; `app_version` nullable ve `version+build` biçiminde (realtime channel/`track` YOK) |
| Tüketici | SADECE admin panel (online eşik hesabı + 30 günlük platform/build dağılımı) |

## Presence Model (gerçek)
State boolean'dır: **active / inactive** (`UserPresenceState`). `away`, `invisible` gibi ara durumlar YOKTUR. "Online" türetilmiş bir değerdir: son heartbeat `onlineThreshold` içindeyse online sayılır (query-time hesap, `admin_models.dart`).

## Heartbeat
- Session-tabanlı: `startSession(userId)` → periyodik `heartbeat(...)` (Timer, `UserPresenceController`) → `endSession(...)`
- Gerçek sabitler `user_presence_constants.dart`: `heartbeatInterval = 2 dk` · `onlineThreshold = 5 dk` · `sessionTtl = 10 dk` — dokümanda süre yazarken BU sabitlere bak, ezbere değer yazma
- Mekanizma: `user_sessions` upsert (PostgREST) — Supabase realtime `track` payload'ı KULLANILMAZ
- `startSession`, `package_info_plus` ile kurulu sürümü `app_version` alanına
  `semantic-version+build-number` biçiminde yazar. Metadata okunamazsa presence
  fail-open devam eder; eski istemcilerin null satırları telemetri coverage'a dahildir.
- App background → `markInactive()` (session biter); foreground → `markActive(userId)` + immediate update
- Logout: `markInactive()` → `endSession()` zinciri (auth.md logout zinciri adım 4 — sticky online engeli)

## TTL & Cleanup
- Son heartbeat `onlineThreshold`'dan (5 dk) eskiyse offline say; session satırı `sessionTtl` (10 dk) sonra temizlenebilir
- Cleanup query-time filter ile (threshold sabitleriyle — hardcoded saniye YOK)

## Battery Optimization
- Heartbeat sadece foreground (background'da bandwidth + battery israfı)
- Background fetch ile presence sync YAPMA (iOS BGTaskScheduler farklı amaçla)
- Throttle: heartbeat aralığı `heartbeatInterval` (2 dk) altına düşürülmez (rapid foreground/background toggle koruması)

## Edge Cases
- iOS app suspended: heartbeat durur, threshold dolunca offline görünür
- Push notification ile app açılırsa: presence resume `markActive` ile (app lifecycle hook)
- Multi-device: en son heartbeat eden cihaz "online" sayılır

## Unshipped Tasarım Hedefleri (known-gaps.md'de kayıtlı — shipped sanma)
- **Privacy/visibility ayarı** (`presence_visibility`: everyone/contacts/nobody, `invisible` modu, `setVisibility()`) — kod tabanında YOK
- **Kullanıcı-yüzü UI göstergeleri** (conversation list yeşil nokta, profile "Çevrimiçi / Az önce görüldü", thread header status) — YOK; tek görünürlük admin paneli
- **Last-seen relative-format yüzeyi** — presence'a bağlı last-seen UI yok (relative-time l10n anahtarları `common.*` başka yüzeylerde kullanılıyor)
- Bunlardan biri eklenirse: bu rule + known-gaps.md + messaging.md birlikte güncellenmeli; `invisible` modu eklenirse server-side yazımın da susturulması ZORUNLU (client-only flag = leak)

## Testing
- Unit: threshold hesabı (son heartbeat + `onlineThreshold` karşılaştırması), `markActive`/`markInactive` state geçişleri
- Integration: heartbeat send + admin presence read round-trip
- Edge: background → foreground transition (lifecycle event mock)

## Sentry & Logging
- Presence update event'leri Sentry'ye GİTMEZ (gürültü)
- Heartbeat fail (network) → `AppLogger.debug` (üretimde gizli)
- `endSession` hatası → `AppLogger.error` (tek log — double-log etme, 2026-07-13 fix)

## Anti-Patterns
1. Background'da heartbeat (battery drain, iOS API misuse)
2. Last-seen'i client clock'tan hesaplamak (timezone bug — server timestamp)
3. Feed'de online badge göstermek (privacy — tasarım kararı)
4. Logout'ta `markInactive()`/`endSession()` atlamak (sticky online görünür)
5. Heartbeat'i `setState` ile UI thread'inde hesaplamak (jank)
6. Online eşiğini heartbeat aralığından kısa yapmak (flicker — gerçek oran: 2 dk beat / 5 dk threshold, `user_presence_constants.dart`)
7. Multi-device'ta tüm session'ları "online" saymak (en son heartbeat tek doğru)
8. Typing indicator'ı DB'ye yazmak (messaging.md — realtime ephemeral)
9. Unshipped visibility/UI hedeflerini shipped varsayıp üzerine kod kurmak (known-gaps.md kontrolü zorunlu)

> **İlgili**: messaging.md (typing, DM), admin.md (online kullanıcı görünürlüğü), auth.md (logout zinciri), notifications.md (push wake → presence resume), obsidian-brain/known-gaps.md
