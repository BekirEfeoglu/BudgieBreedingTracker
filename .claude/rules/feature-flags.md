# Feature Flags

Feature flag'ler üç türde: **compile-time** (dart-define), **runtime** (SharedPreferences/Remote config), **entitlement** (premium). Her birinin farklı bir kullanım amacı var.

## Compile-Time Flags (dart-define)
Sadece debug/staging build'lerde aktif, production binary'de hardcoded:
| Flag | Tür | Amaç |
|------|-----|------|
| `DEBUG_START_ROUTE` | string | Splash'i atla, direkt route'a git (`/birds`, `/genetics`) |
| `DEBUG_GENETICS_FIXTURE` | string | Genetik testleri için preset state |
| `SENTRY_ENVIRONMENT` | string | `development`/`staging`/`production` |

Kullanım:
```dart
const debugRoute = String.fromEnvironment('DEBUG_START_ROUTE');
if (debugRoute.isNotEmpty) {
  return GoRouter(initialLocation: debugRoute);
}
```

### dart-define-from-file
Local development'ta `.env` dosyası kullanılır:
```bash
flutter run --dart-define-from-file=.env
```
`.env` git'e commit edilmez (`.gitignore` zorunlu).

## Runtime Flags (SharedPreferences)
Kullanıcı tercih ayarları + dev/debug toggle'ları:
```dart
class AppPreferences {
  Future<bool> getAnalyticsEnabled();
  Future<void> setAnalyticsEnabled(bool value);
  Future<bool> getExperimentalGenetics();
}
```
- `analytics_enabled` — kullanıcı opt-in
- `notification_quiet_hours` — bildirim sessiz saatleri
- `experimental_*` — gizli geliştirici menüsünden açılır

Production'da kullanıcı bu flag'leri Settings ekranından kontrol eder.

### Sync Runtime Flags
Sync rollout/kill switch flag'leri security boundary değildir; sadece
operasyonel risk azaltmak için kullanılır. Client-side flag kapalı olsa bile
RLS ve server-side authorization değişmez.

| Flag | Default | Amaç |
|------|---------|------|
| `syncOfflineBannerEnabledProvider` | `true` | Global offline/error banner'ı testte veya rollout sırasında kapatmak |
| `syncBackgroundEnabledProvider` | `false` | Background push task'ını kontrollü açmak |
| `syncRealtimeEnabledProvider` | `false` | Foreground realtime subscription rollout'u |
| `syncRealtimeServerKillSwitchProvider` | `false` | Remote config üzerinden realtime subscription'ı global kapatmak |
| `syncRealtimeRolloutPercentProvider` | `100` | Authenticated user bucket'ı için % rollout eşiği |

Background ve realtime flag'leri production'da default kapalı başlar; ilgili
servisler eklendiğinde Settings/debug veya remote config üzerinden açılır.
Realtime subscription ancak local flag açık, server kill switch kapalı ve
deterministik user bucket'ı rollout yüzdesinin altındaysa başlar. Ramp planı:
%5 internal cohort, %25 geniş beta, %100 stable. Crash, subscription timeout
veya conflict oranı artarsa kill switch önce kapatılır, sonra fix deploy edilir.

## Server-Side Kill Switch
Bozuk bir feature production'da hemen kapatılmalı:
- Supabase `app_config` tablosu kill-switch flag'leri tutar
- App startup + her foreground'da pull
- Cache: 1 saat TTL, network'e bağımlı değil (cache hit her zaman tercih)
- Default: open (config gelmezse feature açık) — fail-open mu fail-closed mu seçimi feature'a göre

```dart
final config = ref.watch(remoteConfigProvider);
if (config.isCommunityDisabled) {
  return const FeatureDisabledScreen();
}
```

### Kill Switch'i NE ZAMAN Kullan?
- Yeni feature production'a çıktı, %1 user'da crash log artıyor → kill switch ON
- Edge function yoğunluğu yüksek, kost taşıyor → temporary OFF
- Topluluk moderasyon problemi acil → community modülü kapat

### Kill Switch ANTI-PATTERN
- Bug fix yerine kill switch ile gizleme (geçici, kalıcı çözüm gerekir)
- Tüm feature'ları flag arkasına almak (config explosion)

## Entitlement Flags (Premium)
Premium feature kontrolü `premium-revenuecat.md` rule'unda. Özet:
- Server-validated `is_premium`
- `PremiumGuard` route'larda
- `premiumGracePeriodProvider` UI level kontrol

## Experimental Features (Dev Menu)
Geliştirici menüsü (5x tap on Settings header), production'da gizli:
- `experimental_local_ai` — LocalAiService preview
- `experimental_genetics_v3` — yeni calculator versiyonu
- `debug_show_provider_logs` — provider rebuild log'ları

Public release'de kullanıcılar göremez ama testers + founders aktive edebilir.

## Flag Lifecycle
1. **Add**: feature start'ta flag default `false`, geliştirme local
2. **Beta**: dev menu'den enable, internal test
3. **Rollout**: server config %10 → %50 → %100
4. **Stable**: flag default `true`, eski path remove edilir (max 2 release sonra)
5. **Delete**: flag tamamen kod tabanından silinir

Flag'ler kalıcı olmamalı — `experimental_*` flag'leri 90 günden uzun yaşamamalı. Yaşıyorsa: ya feature stable, flag sil; ya feature ölü, kod sil.

## Flag Inventory (Audit)
- 6 ayda bir flag inventory: aktif tüm flag'leri listele, lifecycle stage'leri belirle
- Stale flag'ler (90 gün+ aynı state'te) sil
- Flag kullanımı izle: `AppLogger.debug('feature_flag', 'flag_x evaluated as true')` (production'da gürültü etmez, debug only)

## Testing Flags
- Feature flag'i testte explicit override:
```dart
final container = ProviderContainer(overrides: [
  remoteConfigProvider.overrideWithValue(RemoteConfig(isCommunityDisabled: true)),
  syncOfflineBannerEnabledProvider.overrideWithValue(false),
]);
addTearDown(container.dispose);
```
- Asla test'te `setFlag` yapma — provider override kullan

## Anti-Patterns
1. dart-define flag'ini production binary'e koymak (release-blocker — debug-only)
2. SharedPreferences flag'ini security check için kullanmak (bypass edilebilir)
3. Kill switch yokken bozuk feature deploy etmek (rollback dışında çözüm yok)
4. Flag explosion (5+ flag'in cross-product'ı test edilemez)
5. Stale flag'leri 90 gün üzeri tutmak (dead code)
6. `.env` dosyasını commit etmek (anti-pattern: ai-workflow.md prohibited)
7. Remote config fail durumunda app crash (fail-open default zorunlu)
8. Flag kararını widget tree'nin derininde yapmak (root'ta kontrol et, alt tree'ye prop pass et)

> **İlgili**: release-ops.md (env vars), premium-revenuecat.md (entitlement), security.md (secret'lar), observability.md (flag log)
