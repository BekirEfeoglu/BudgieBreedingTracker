# Domain: Ads Service

**Purpose**: AdMob banners, interstitials, and rewarded ads. `AdService`
(`lib/domain/services/ads/ad_service.dart`) + reward providers
(`ad_reward_providers.dart`). Free-user monetization plus rewarded temporary
access to premium-gated screens. Premium users see **no ads**.

Rule source: `.claude/rules/ads.md`.

## SDK Init (lazy — off the startup critical path)

- `AdService.ensureSdkInitialized()` is lazy (~2s deferred) — no bootstrap
  phase; it never blocks splash and never runs during the iOS auth flow.
- iOS ATT (App Tracking Transparency) is requested via MethodChannel
  **before** `MobileAds` init — this ordering is fixed.
- No UMP consent form; ATT is the only consent mechanism.
- iOS simulator debug defers SDK init + preload.

## Ad Unit IDs

- Static getters on `AdService`; `kDebugMode` → Google test IDs, release →
  production IDs. Not in `.env`/dart-define — IDs are public, no secret handling.

## Banner Placement

- Real call sites: `home_screen`, `calendar_screen`, `bird_list_screen`,
  `breeding_list_screen`, `chick_list_screen`. **Not** wired into marketplace
  (the marketplace-banner rows in `.claude/rules/marketplace.md` are a design
  goal, not shipped).
- `AdBannerWidget` receives `isPremium` as a **parameter** (caller injects it) —
  the widget does not read `effectivePremiumProvider` from the domain layer,
  avoiding a layer violation.
- `isPremium || !_isAdLoaded` → `SizedBox.shrink()` — no gap on premium or load
  failure. Load failure disposes the ad and skips silently (no retry spam).

## Interstitial

- 3-minute cooldown between displays (`_cooldownDuration = Duration(minutes: 3)`).
- Fail-safe: `onAdClosed` always fires even if the ad fails to load/show — user
  flow is never held hostage to an ad.

## Rewarded Ads (temporary premium access)

| Reward | Model | Persist key |
|--------|-------|-------------|
| Statistics | 24h (unlock timestamp) | `pref_reward_statistics_unlocked_at` |
| Genetics | use-count (consumed on route entry) | `pref_reward_genetics_uses` |
| Export | use-count | `pref_reward_export_uses` |

- Router gates (`app_router.dart`): `/statistics` → `isPremium || statsReward`;
  genetics routes → `isPremium || geneticsReward` (consumed per entry); export →
  `effectivePremiumProvider || isExportRewardActiveProvider` (backup screen).
- Providers: `isStatisticsRewardActiveProvider`,
  `isGeneticsRewardActiveProvider`, `isExportRewardActiveProvider`.
- When a reward is active, `PremiumRewardedAdSection` hides the button and shows
  `RewardStatusChip`; `RewardedAdButton` shows a SnackBar fallback if the ad is
  not ready.
- Reward is a **UX gate, not a security boundary** — SharedPreferences can be
  tampered; server-side data/limit protection comes from
  [[domain/premium-service]]. Reward may gate only screen access.

## Premium Interaction

- Premium source is `effectivePremiumProvider` (grace period included) — do not
  use `isPremiumProvider` alone for the ad decision (see [[domain/premium-service]]).

## Tests

`ad_service_test.dart` (init, lifecycle, cooldown), `ad_reward_providers_test.dart`
(unlock/consume, expiry), `ad_banner_widget_test.dart` (premium, load fail),
`rewarded_ad_button_test.dart`, `premium_rewarded_ad_section_test.dart`. No live
AdMob calls in tests.

## See Also

- [[domain/premium-service]] — `effectivePremiumProvider`, grace period
- [[features/statistics]] — reward-based screen access
- [[features/premium]] — upgrade entry point
- [[domain/services-index]]
