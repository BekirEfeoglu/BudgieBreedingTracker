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
```dart
AppLogger.debug(tag, message);                  // Geliştirme — production'da gizli
AppLogger.info(tag, message);                   // Operasyonel
AppLogger.warning(message);                     // Bozulmuş durum, retry edilebilir
AppLogger.error(message, error, stackTrace);    // Otomatik Sentry breadcrumb
```

`tag` kuralı: kaynağı kimliklendir — `'BirdRepository'`, `'SyncService'`, `'AuthProvider'`, `'GeneticsEngine'`. Aynı tag boyunca filtreleme kolaylaşır.

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
| Performance ölçümü | `debug('perf', ...)` |

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

## Performance İzleri
- Drift query timing: `Stopwatch()..start()` + `AppLogger.debug('perf', 'queryName: ${sw.elapsed}')`
- Sentry performance monitoring şu an pasif (cost) — sadece kritik akışlar
- Startup time: `lib/main.dart` içinde phase log'la (splash → home arası)

## PII / Veri Koruma
- Asla log/Sentry'ye **password, token, MFA kodu, refresh token** yazma
- Email log'lanabilir (debug only) ama Sentry production'da maskeyle
- Telefon, doğum tarihi, konum: redact
- Bird/egg verisi: Sentry'ye giderken sadece `id` — kullanıcının özel kuş bilgileri korunur
- Ödeme bilgisi (RevenueCat): asla yerel log/Sentry'ye düşmez

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

## Test
```dart
test('sync failure logs and reports to sentry', () async {
  when(() => mockRemote.upsert(any())).thenThrow(Exception('boom'));

  await expectLater(
    repository.syncToRemote(),
    throwsA(isA<Exception>()),
  );

  // AppLogger.error çağrılmış olmalı (mock fixture ile doğrula)
  // Sentry.captureException çağrılmış olmalı
});
```

> **İlgili**: error-handling.md (exception hierarchy), security.md (PII), edge-functions.md (server logging)
