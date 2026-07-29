# App Update

Sürüm kontrolü ve güncelleme istemi. iOS'ta App Store lookup + Supabase config, Android'de Play in-app update. `lib/features/app_update/` + `lib/domain/services/app_update/`. Kontrol **fail-open**: hiçbir hata app'i bloklamaz.

## Stack
| Bileşen | Yer |
|---------|-----|
| iOS lookup | `AppStoreLookupService` (iTunes lookup API, App ID `6759828211`) |
| Android | `in_app_update ^4.2.3` → `InAppUpdateService` |
| Server config | Supabase `system_settings.app_version` satırı (min build + release notes) |
| Version model | `AppUpdateInfo` (`app_update_info.dart`) |
| UI | `AppUpdatePrompt` + `AndroidInAppUpdater` (`lib/features/app_update/widgets/`) |
| Throttle | `ResumeThrottle` (`lib/core/utils/resume_throttle.dart`) — resume'da 6h cap (performance.md) |
| Store URL | `StoreUpdateLauncher` → native kanal (`SKStoreProductViewController` / Play Store intent) + external URL fallback |

## Mounting (overlay, route DEĞİL)
`lib/app.dart` MaterialApp builder'ında sarılır: `AndroidInAppUpdater > AppUpdatePrompt > OfflineBanner > routedChild`.
- Overlay olması bilinçli: auth token refresh sırasındaki GoRouter rebuild'leri imperative `showDialog`'u kapatır — widget-tree render bunu atlatır. Prompt'u dialog'a ÇEVİRME
- `OfflineBanner` ile sıralama sabit (empty-loading-error-states.md § Offline Banner)

## Version Karşılaştırma
- Custom semver parse (`app_update_info.dart`): non-digit ayrıştırıcılarla böl, sol-sağ sayısal karşılaştır
- Öncelik: `latestBuild > 0` ise build number, değilse semver string
- **Force update**: `currentBuild < minSupportedBuild` → `isRequired=true`
- Kaynak birleşimi: App Store/Play sürümü + DB satırı; App Store sürümü daha yeniyse DB release notes ile birlikte gösterilir

## Optional vs Required
| Durum | UI | Dismiss |
|-------|----|---------|
| Optional (`!isRequired`) | iOS: dismissible banner; Android: Play native in-app update | iOS per-version state key — aynı sürüm için tekrar çıkmaz, yeni sürümde döner (persist edilmez, in-memory) |
| Required (`isRequired`) | iOS + Android tam ekran blok | Dismiss YOK — store'a gitmek tek çıkış |

`minSupportedBuild`'i yükseltmek kullanıcıları KİLİTLER — release-ops kararı, tek başına değiştirme.

## Android In-App Update
- `priority >= 4` → immediate (blocking) update flow
- `priority < 4` + `flexibleAllowed` → arka planda indir; bitince SnackBar "restart" → `completeFlexible()`
- Priority değeri Play Console'dan release'e atanır

## Hata / Offline Davranışı
- Lookup HTTP hatası, bozuk JSON, network exception → `null` döner; `AppLogger` warning, **Sentry'ye GİTMEZ** (beklenen koşul)
- DB query hatası → prompt gösterilmez, app devam eder (fail-open)
- Offline'da kontrol tetiklenmez; dismiss durumu korunur
- Update kontrolünü kritik akışa (login, sync) BAĞLAMA

## Release Notes & L10n
- DB alanları: `release_notes_tr` / `release_notes_en` / `release_notes_de`; eksik dilde best-available fallback
- L10n kategorisi `app_update.*`: `available_title`, `required_title`, `message`, `message_with_notes`, `update_now`, `later`, `download_complete`, `restart`
- Store URL: DB/lookup'tan gelen `info.storeUrl` tercih, yoksa `AppConstants` sabiti. Açılış `StoreUpdateLauncher` üzerinden yapılır: iOS önce in-app App Store product sheet, Android önce Play Store app intent, ikisi de başarısız olursa external URL fallback.
- Admin paneli `system_settings.app_version` JSON'unu iOS/Android ayrı alanlar halinde düzenleyebilir; public kalmalı çünkü startup kontrolü anon/auth client tarafından okunur.
- Admin özetinde `min_supported_build = 0` açıkça "zorunlu güncelleme kapalı"
  olarak gösterilir. Minimum build son build'i aşamaz; minimum değer
  yükseltilirken kullanıcı kilitleme riski için ayrıca onay istenir.

## Testing
- `app_update_info_test.dart` (version compare, minSupportedBuild, kaynak önceliği), `app_store_lookup_service_test.dart` (API parse + hata), `in_app_update_service_test.dart` (priority kararı, check fail), `app_update_prompt_test.dart` (optional/required render, dismiss key, notes l10n)

## Anti-Patterns
1. Update kontrolünü fail-closed yapmak (network hatası app'i kilitleyemez)
2. Prompt'u `showDialog` ile göstermek (router rebuild kapatır — overlay pattern)
3. Her resume'da throttle'sız kontrol (`ResumeThrottle` 6h zorunlu)
4. `minSupportedBuild`'i sıradan config gibi bump'lamak (kullanıcı kilitleme — release kararı)
5. Lookup hatalarını Sentry'ye göndermek (beklenen koşul — gürültü)
6. Version karşılaştırmayı string `==`/`compareTo` ile yapmak (semver parse zorunlu)
7. Optional dismiss'i kalıcı persist etmek (yeni sürümde prompt geri gelmeli)
8. Store URL'i hardcode edip `AppConstants`/DB kaynağını atlamak
9. Android'de opsiyonel DB banner göstermek (Play in-app update ile çift prompt üretir)

> **İlgili**: release-ops.md (version bump, store release), performance.md (ResumeThrottle), empty-loading-error-states.md (OfflineBanner sarmalama sırası), observability.md (Sentry'ye gitmeyen olaylar)
