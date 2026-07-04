# Ads (AdMob)

Banner, interstitial ve rewarded reklamlar. `AdService` (`lib/domain/services/ads/ad_service.dart`) + `ad_reward_providers.dart`. Free kullanıcı monetizasyonu + rewarded ile geçici premium-feature erişimi. Premium kullanıcı ASLA reklam görmez.

## Stack
| Bileşen | Yer |
|---------|-----|
| SDK | `google_mobile_ads ^9.0.0` |
| Service | `AdService` (`lib/domain/services/ads/`) |
| Reward providers | `isStatisticsRewardActiveProvider` / `isGeneticsRewardActiveProvider` / `isExportRewardActiveProvider` (`ad_reward_providers.dart`) |
| Banner widget | `AdBannerWidget` |
| Rewarded UI | `RewardedAdButton`, `PremiumRewardedAdSection` + `RewardStatusChip` |
| Persist | `AppPreferences` (`pref_reward_statistics_unlocked_at`, `pref_reward_genetics_uses`, `pref_reward_export_uses`) |

## SDK Init (Lazy — startup kritik yoluna ALMA)
- `AdService.ensureSdkInitialized()` lazy çağrılır (~2s ertelenmiş) — bootstrap fazı YOK; splash'i bloklamaz (performance.md § Startup Performance)
- iOS ATT (App Tracking Transparency) izni `MobileAds` init'ten ÖNCE MethodChannel ile istenir — sıra değişmez
- UMP consent formu YOK — tek consent mekanizması iOS ATT (eklenire bu rule güncellenmeli)
- iOS simulator debug'da SDK init + preload ertelenir (`_shouldDeferAdsOnDebugIosSimulator`)

## Ad Unit IDs
- `AdService` içinde static getter'lar; `kDebugMode` → Google test ID'leri, release → production ID'ler
- `.env`/dart-define DEĞİL — ID'ler public (binary'de görünür), secret muamelesi gerekmez
- Test ID'yi production path'e, production ID'yi debug path'e KOYMA (AdMob policy ihlali / kirli metrik)

## Banner Placement
- Gerçek call site'lar: `home_screen`, `calendar_screen`, `bird_list_screen`, `breeding_list_screen`, `chick_list_screen`
- (Marketplace feed banner'ı shipped DEĞİL — marketplace.md § Ad Placement tasarım hedefi)
- `AdBannerWidget` premium durumunu **parametre olarak alır** (`isPremium`) — widget domain'den `effectivePremiumProvider`'ı okumaz; layer ihlalini caller injection çözer
- `isPremium || !_isAdLoaded` → `SizedBox.shrink()` — premium'da ve load fail'de UI'da BOŞLUK KALMAZ
- Load failure: ad dispose + `_isAdLoaded=false`, sessiz geç (retry spam yok)

## Interstitial
- Call site'lar: calendar, bird_list, breeding_list, chick_list ekran akışları
- Cooldown: **3 dakika** (`_cooldownDuration`) — gösterimler arası zorunlu bekleme, kaldırma (UX + policy)
- Fail-safe: reklam yüklenmese/gösterilmese bile `onAdClosed` callback'i HER ZAMAN çağrılır — kullanıcı akışı reklama rehin edilmez

## Rewarded Ads (geçici premium erişim)
| Reward | Süre/Model | Persist key |
|--------|-----------|-------------|
| Statistics | 24 saat (unlock timestamp karşılaştırma) | `pref_reward_statistics_unlocked_at` |
| Genetics | Kullanım sayacı (route girişinde tüketilir) | `pref_reward_genetics_uses` |
| Export | Kullanım sayacı | `pref_reward_export_uses` |

- Router gate (`app_router.dart`): `/statistics` → `isPremium || statsReward`; genetics rotaları → `isPremium || geneticsReward` (girişte tüketim); export → backup_screen'de `effectivePremiumProvider || isExportRewardActiveProvider`
- Reward aktifken `PremiumRewardedAdSection` butonu gizler, `RewardStatusChip` gösterir
- Reklam hazır değilse `RewardedAdButton` SnackBar fallback gösterir — sessiz no-op yok
- Reward **UX gate'idir, güvenlik sınırı DEĞİL**: SharedPreferences manipüle edilebilir; server-side veri/limit koruması premium-revenuecat.md'deki mekanizmalardan gelir. Reward ile korunacak şey yalnızca EKRAN ERİŞİMİ olabilir

## Premium Etkileşimi
- Premium kaynak: `effectivePremiumProvider` (grace period dahil) — reklam kararında `isPremiumProvider`'ı tek başına kullanma (premium-revenuecat.md grace kuralı)
- Premium'a reklam göstermek anti-pattern (marketplace.md #4 ile tutarlı)

## Testing
- `ad_service_test.dart` (init, lifecycle, cooldown), `ad_reward_providers_test.dart` (unlock/consume, expiry), `ad_banner_widget_test.dart` (premium, load fail), `rewarded_ad_button_test.dart`, `premium_rewarded_ad_section_test.dart`
- Testte gerçek AdMob çağrısı ASLA — SDK mock'lanır

## Anti-Patterns
1. Premium kullanıcıya reklam göstermek (entitlement-aware zorunlu)
2. Ad load fail'de UI'da boşluk/placeholder bırakmak (`SizedBox.shrink` pattern)
3. SDK init'i bootstrap kritik yoluna taşımak (startup jank + ATT timing bozulur)
4. ATT isteğini SDK init'ten sonraya almak (iOS policy — sıra sabit)
5. Interstitial cooldown'ı kısaltmak/kaldırmak (policy + UX)
6. Rewarded erişimi güvenlik sınırı sanmak (client-side prefs — sadece UX gate)
7. Widget'ın domain'den premium provider okuması (layer ihlali — `isPremium` injection pattern'i koru)
8. `onAdClosed`'u sadece başarılı gösterimde çağırmak (akış reklama kilitlenir)
9. Test ad unit ID'lerini release'e sızdırmak (kDebugMode ayrımı zorunlu)

> **İlgili**: premium-revenuecat.md (effectivePremiumProvider, grace), statistics.md (reward ile ekran erişimi), marketplace.md (ad placement tasarımı), performance.md (startup lazy init), feature-flags.md (entitlement flags)
