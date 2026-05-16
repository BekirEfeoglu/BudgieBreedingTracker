# Stabilization Audit - 2026-05-16

Bu dokuman, stabilizasyon planindaki genis audit maddelerinin mevcut `main`
durumuna gore sonucunu kaydeder. Kod degisikligi gerektiren kucuk bulgular
ayni calismada duzeltildi; buyuk refactor ve golden genisletme isleri ayri
PR'lara bolunmelidir.

## Edge Function Invocation Matrix

| Function | Dart invoker | Test coverage / server reference | Sonuc |
| --- | --- | --- | --- |
| `system-health` | `EdgeFunctionClient.checkSystemHealth()` | `edge_function_client_test.dart`, `admin_health_providers_test.dart` | Kullaniliyor; admin health flow tarafindan wrapper uzerinden erisiliyor. |
| `mfa-lockout` | `EdgeFunctionClient.checkMfaLockout()`, `recordMfaFailure()`, `resetMfaLockout()` | Function unit testleri ve `mfa_lockouts` migration notlari | Kullaniliyor; MFA brute-force state'i edge function uzerinden yonetiliyor. |
| `revoke-oauth-token` | `AuthActions._revokeOAuthTokenIfPossible()` direct invoke | `auth_oauth_methods_test.dart` | Kullaniliyor; OAuth logout temizligi best-effort calisiyor. |
| `send-push` | `EdgeFunctionClient.sendPush()` | `edge_function_client_test.dart`, FCM token migration/index notlari | Kullaniliyor; push gonderimi wrapper uzerinden mevcut. |
| `sync-premium-status` | `syncPremiumStatusThroughEdgeFunction()` | `premium_sync_rpc_test.dart`, premium hardening migrations | Kullaniliyor; RevenueCat premium sync server-side dogrulaniyor. |
| `validate-free-tier-limit` | `FreeTierLimitService.validateServerSide()` | `free_tier_limit_service_test.dart`, marketplace form server validation referansi | Kullaniliyor; premium/free tier limit kontrolu server-side. |
| `moderate-content` | `ContentModerationService` | `content_moderation_service_test.dart`, post edit rescan migration notu | Kullaniliyor; metin moderasyonu client ve DB-side akislarda referansli. |
| `scan-image-safety` | `EdgeFunctionClient.scanImageSafety()`, `ImageSafetyService` | Function unit testleri ve image safety service referansi | Kullaniliyor; medya guvenligi icin wrapper mevcut. |

Sonuc: Deploy edilmis 8 function icin tamamen yetim function bulunmadi. Davranis
degisikligi gerektiren yeni invocation eklenmedi.

## AsyncValue Sweep

Komut:

```bash
rg -n "\.when\(" lib/features -g '*.dart' | cut -d: -f1 | sort -u | while read f; do if ! rg -q "loading:" "$f" || ! rg -q "error:" "$f"; then echo "$f"; fi; done
```

Sonuc: Eksik `loading:` veya `error:` branch bulunan feature dosyasi yok.
`SizedBox.shrink()` kullanan bazi admin/monitoring alanlari bilincli sessiz
durum olarak birakildi; kullaniciya gorunur ana akislarda `LoadingState`,
`ErrorState` veya yerel skeleton pattern'leri mevcut.

## E2E Harness Lifecycle

Komut:

```bash
dart analyze test/helpers/e2e_test_harness.dart
```

Sonuc: Sorun bulunmadi. Harness `appDatabaseProvider` override'inda
`ref.onDispose(db.close)` kullaniyor ve `ProviderContainer` icin
`addTearDown(container.dispose)` kayitli. Ayrica explicit kirik
`AppDatabase.close` referansi bulunmadi.

## ListView Spot-Check

| Dosya | Karar |
| --- | --- |
| `lib/features/profile/widgets/profile_skeleton.dart` | Sabit skeleton layout; `ListView.builder` gerekmiyor. |
| `lib/features/marketplace/widgets/marketplace_image_picker.dart` | En fazla 3 gorsel; horizontal `ListView` sabit kucuk liste olarak uygun. |
| `lib/features/admin/screens/admin_users_screen_list.dart` | Bos durum icin tek elemanli `ListView`; veri listesi zaten `ListView.separated`. |

Sonuc: Buyuyen veri listesi icin non-builder kullanim tespit edilmedi.

## Online Insert Retry-Safety

| Akis | Mevcut durum | Karar |
| --- | --- | --- |
| Community post | Repository create akisi client-side id ile insert ediyor. | Tekrar denemede ayni id korunmadigi icin remote-source seviyesinde upsert davranis degisikligi getirebilir; ayri idempotency tasarimi gerekir. |
| Community comment | Repository create akisi client-side id ile insert ediyor. | Ayni nedenle davranis degisikligi yapilmadi. |
| Feedback | Repository feedback id uretip insert ediyor; DB trigger founder notification yaratir. | Upsert, notification trigger semantigini degistirebilir; ayri idempotency token tasarimi gerekir. |
| Marketplace listing | Create caller data'sindan row doner; listing create yan etkileri ve storage baglantilari var. | Davranis degisikligi yapilmadi. |
| Messaging | `MessageRemoteSource.insert()` zaten `upsert(... onConflict: 'id')` kullaniyor. | Uyumlu. |
| Gamification XP ledger | Append-only XP transaction ledger. | `insert()` bilincli; upsert ledger semantigini bozabilir. |

Sonuc: Mesajlasma zaten upsert pattern'inde. Diger online-only insert akislari
icin guvenli gecis, repository disindan gelen stable idempotency key gerektirir;
bu calismada davranis degistirilmedi.

## Buyuk Dosya Refactor Backlog

Ilk aday:

- `lib/domain/services/local_ai/local_ai_service.dart`

Onerilen ayrim:

- provider routing / backend secimi
- model discovery ve cache
- prompt olusturma
- maliyet/rate guard
- request/response parse ve error mapping

Bu refactor ayri PR olmali; test kapsami local AI service unit testleriyle
once mevcut davranisi sabitlemeli.

## Golden Coverage Backlog

Mevcut golden altyapisi `test/golden/` altinda aktif. Yeni ekran golden'lari ayri
PR'larda eklenmeli:

- Home
- Bird list
- Bird form
- Genetics compare
- Admin dashboard

Her ekran icin hedef matris: `tr/en/de` ve `light/dark`. Almanca uzun kelime
overflow riski snapshot ve test failure diff'leriyle ozellikle incelenmeli.

## AI Provider Marka Isimleri

`Ollama` ve `OpenRouter` marka adlari cevrilmeyecek. Mevcut
`verify_code_quality.py` l10n checker'i `Text('...')` marka adlarini taramiyor;
bu nedenle ek ignore veya l10n key gerekmiyor.
