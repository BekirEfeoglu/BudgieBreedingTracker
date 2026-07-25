# Observability

Logging, error tracking, breadcrumbs ve analytics tek yerden yönetilir. Her hata bir kullanıcı; her sessiz hata kaybedilen güven.

## Stack
| Katman | Araç | Amaç |
|--------|------|------|
| Yapısal log | `AppLogger` | Geliştirme + production debug izleri |
| Hata izleme | Sentry (`sentry_flutter ^9.0.0`) | Üretim hata yakalama, breadcrumb, performance |
| Analytics | (yok — gelecek) | Kullanıcı davranışı |
| Edge fn log | Supabase Dashboard | Sunucu tarafı edge function trace |

## AppLogger API
Tüm metodlar tek `String message` parametresi alır — `tag` diye ayrı bir parametre YOK (`lib/core/utils/logger.dart`):
```dart
AppLogger.debug(message);                       // Geliştirme — production'da gizli
AppLogger.info(message);                        // Operasyonel
AppLogger.warning(message);                      // Bozulmuş durum, retry edilebilir
AppLogger.error(message, error, stackTrace);    // Otomatik Sentry breadcrumb
```

Kaynak tanımlama kuralı: `[Bracket]` prefix'i mesajın İÇİNE göm — `AppLogger.warning('[SyncOrchestrator] retry attempt failed')`. Ayrı bir `tag` argümanı geçirme (derleme hatası verir).

## Hangi Seviye Ne Zaman?
| Senaryo | Seviye |
|---------|--------|
| Provider build başlangıcı (yoğun) | `debug` (üretimde gizli) |
| Repository write success | `info` |
| Sync retry attempt | `warning` |
| Sync max retry sonrası fail | `error` + Sentry |
| Auth token refresh fail | `error` + Sentry |
| Validation hata (kullanıcı kaynaklı) | `warning` (Sentry'ye gitme) |
| Beklenmeyen exception | `error` + Sentry |
| Performance ölçümü | `debug('[Perf] operation: ${elapsed}ms')` |

## Sentry Kullanımı
```dart
try {
  await criticalOperation();
} catch (e, st) {
  AppLogger.error('Sync failed', e, st);  // Otomatik breadcrumb
  await Sentry.captureException(
    e,
    stackTrace: st,
    withScope: (scope) {
      scope.setTag('feature', 'sync');
      scope.setExtra('userId', userId);
    },
  );
  rethrow;
}
```

### Sentry'ye GİDEN olaylar
- Auth/MFA başarısızlık (brute force ipucu)
- Sync conflict / data corruption
- Crash / unhandled exception
- Critical edge function failure
- Migration hatası
- **Bir güvenlik kontrolünü sessizce zayıflatan fail-open catch** (2026-07-25'te
  eklenen iki somut örnek):
  - `TwoFactorService.getFactors` hatada `[]` döner ve her çağıran bunu "bu
    kullanıcının 2. faktörü yok" diye okur (post-login MFA kontrolü, AAL2
    destructive-action guard, güvenlik skoru). Geçici bir `listFactors()`
    hatası MFA'yı görünmez kılar → `feature: auth` + `auth_method: mfa` tag'li
    `Sentry.captureException`
  - `EncryptionService.decrypt` TÜM key sürümleri tükendiğinde: ya at-rest veri
    bozulması ya da HMAC doğrulama hatası (tampering) demektir → `feature:
    encryption` tag'i + yalnız **metadata** (`payloadLength`,
    `previousKeyCount`); ciphertext ya da çözülmüş değer ASLA gönderilmez
    (encryption.md § Sentry & Logging)

### Sentry'ye GİTMEYEN olaylar
- Form validation hataları (`ValidationException`)
- Beklenen 404 / boş listeler
- Kullanıcı offline (`NetworkException`)
- Free tier limit aşımı (`FreeTierLimitException`)
- İptal edilmiş kullanıcı işlemleri

Kuralı: Hata ne kullanıcı bilgisi gerektirir ne de tasarımla beklenen — Sentry'ye gönder.

## Breadcrumb & Context
- `AppLogger.error` otomatik breadcrumb ekler
- Manuel breadcrumb: `Sentry.addBreadcrumb(Breadcrumb(message: 'User tapped sync'))`
- User context: login sonrası `Sentry.configureScope((s) => s.setUser(SentryUser(id: userId)))`
- Logout: `Sentry.configureScope((s) => s.setUser(null))` — PII sızdırma

## Tag Sözleşmesi (Sentry scope)
- `feature`: hangi feature modülü (`birds`, `genetics`, `sync`)
- `sync_phase`: `pull` / `push` / `merge`
- `entity_type`: `bird` / `egg` / `chick`
- `network`: `online` / `offline`
- `auth_method`: `email` / `google` / `apple`

## Breadcrumb Budget Protection
`AppLogger.warning` her zaman Sentry breadcrumb ekler (release build'de bile) — `debug` sadece non-release'de ekler. Sentry ~100 breadcrumb tutar; caller kodunda cap olmayan bir retry loop (örn. Supabase realtime subscription, SDK sonsuz reconnect dener) her denemede `.warning` loglarsa gerçek crash context'i tükenmeden silinebilir. `RealtimeErrorLogThrottle` (`lib/core/utils/realtime_error_log_throttle.dart`) subscription başına ardışık `.warning` çağrısını sınırlar (varsayılan 5, `RealtimeSyncService.maxReconnectFailures` ile eşleşir), sonra `.debug`'a düşer; `reset()` başarılı reconnect'te budget'i geri yükler. `EventRemoteSource.subscribeToEvents` ve `CommunityPostRemoteSource.subscribeToPostChanges` içinde kullanılıyor.

## Performance İzleri
- Drift query timing: `Stopwatch()..start()` + `AppLogger.debug('perf queryName: ${sw.elapsed}')`
- Sentry performance monitoring şu an pasif (cost) — sadece kritik akışlar
- Startup time: `lib/main.dart` içinde phase log'la (splash → home arası)

## Sentry Sample Rate Budget
| Environment | `tracesSampleRate` | `replaysSessionSampleRate` |
|-------------|--------------------|-----------------------------|
| development | 1.0 (her şey) | 0.0 |
| staging | 0.5 | 0.1 |
| production | 0.1 (10%) | 0.0 (kapalı, maliyet) |

Production'da kritik hata her zaman gider (`errorSampleRate = 1.0`), sadece performance trace sample'lanır. Replay özelliği kapalı — privacy + cost. `SENTRY_ENVIRONMENT` dart-define'a göre runtime select edilir.

Enforcement: `bootstrap.dart` içindeki `sentryTracesSampleRateFor(_resolvedSentryEnv)` bu tabloyu uygular (bilinmeyen env → 0.1 fail-safe; test: `test/core/sentry_sample_rate_test.dart`). `tracesSampleRate`'i sabit değerle hardcode etme — oran değişikliği bu fonksiyon + bu tablo birlikte güncellenir.

## Structured Log Schema
Edge function `console.log` JSON formatında:
```json
{
  "ts": "2026-05-14T10:00:00Z",
  "level": "info",
  "event": "sync_completed",
  "user_id": "uuid",
  "entity_type": "birds",
  "duration_ms": 142,
  "extra": { "items_synced": 5 }
}
```
- `event` snake_case, dictionary kontrollü (`sync_started`, `sync_completed`, `sync_failed`, `auth_login`, `mfa_lockout`)
- `user_id` her zaman dahil (multi-tenant filter)
- `extra` opsiyonel meta — request body DEĞİL
- Top-level `error` field'ı failure case'lerde

## Log Retention
- Supabase Edge Function logs: 7 gün (Supabase default)
- Sentry events: 30 gün (free tier), 90 gün (paid)
- Client log'ları sadece debug build'de console'a; production'da Sentry breadcrumb (max 100 breadcrumb)
- PII içermeyen analytics: ileride external tool'a yazılabilir, şu an yok

## PII / Veri Koruma
- Asla log/Sentry'ye **password, token, MFA kodu, refresh token** yazma
- Email log'lanabilir (debug only) ama Sentry production'da maskeyle
- Telefon, doğum tarihi, konum: redact
- Bird/egg verisi: Sentry'ye giderken sadece `id` — kullanıcının özel kuş bilgileri korunur
- Ödeme bilgisi (RevenueCat): asla yerel log/Sentry'ye düşmez
- **Signed URL log'lama (2026-07-25 emsali):** private, user-scoped bucket'ların
  signed URL'i bir **bearer token**'dır (bird-photos'ta 7 gün geçerli) ve
  path'inde ham `user_id` taşır. `AppLogger.warning` release build'de Sentry
  breadcrumb yazdığı için böyle bir URL, süresi dolana kadar Sentry'den
  okunabilir kalır. `bird_detail_photos.dart` bu yüzden URL yerine **bird id +
  çıplak obje dosya adı** log'lar. Kural: bir signed/pre-signed URL'i hiçbir
  seviyede log'lama; teşhis için entity id + obje adı yeterlidir

## Edge Function Logging
- Her edge function `console.log({ event, userId, ...meta })` JSON formatında
- Hata: `console.error({ error: err.message, stack: err.stack, ...context })`
- Supabase Dashboard → Functions → Logs ile filtrelenebilir
- Asla request body'sini olduğu gibi log'lama (kullanıcı verisi sızar)

## Üretim Hata Akışı
```
1. Exception thrown
2. AppLogger.error → console (debug build) + Sentry breadcrumb
3. Sentry.captureException → Sentry dashboard
4. UI: AsyncValue.error → ErrorState widget
5. Kullanıcıya l10n mesajı gösterilir
6. Telemetry ekibi Sentry'de issue triage eder
```

## Anti-Patterns
1. `print()` kullanmak (anti-pattern #10)
2. `catch (e)` ardından sadece kullanıcı mesajı — log/Sentry yok (anti-pattern #22, #23)
3. Sentry'ye PII gönderme (password, token, email production)
4. Validation hatalarını Sentry'ye gönderme (gürültü)
5. Stack trace olmadan `AppLogger.error('error', e)` (`stackTrace` parametresi unutulmuş)
6. Tag yerine free-form string ile log filtrelemeyi imkansız kılma
7. Sentry scope'ta `userId` set ettikten sonra logout'ta clear etmemek
8. Edge function'da `console.log(req.body)` — full request body sızar
9. Cap'siz retry loop'ta `.warning` loglamak (breadcrumb bütçesi tükenir — `RealtimeErrorLogThrottle` kullan)

## Test
```dart
test('sync failure logs and reports to sentry', () async {
  when(() => mockRemote.upsert(any())).thenThrow(Exception('boom'));

  await expectLater(
    repository.push(item),
    throwsA(isA<Exception>()),
  );

  // AppLogger.error çağrılmış olmalı (mock fixture ile doğrula)
  // Sentry.captureException çağrılmış olmalı
});
```

> **İlgili**: error-handling.md (exception hierarchy), security.md (PII), edge-functions.md (server logging)
