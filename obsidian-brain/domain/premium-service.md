# Premium Service

Source: `.claude/rules/premium-revenuecat.md`

**Location**: `lib/domain/services/` (premium-related services)

## Stack

| Layer | Tool |
|-------|------|
| Store | App Store + Google Play |
| Aggregator | RevenueCat (`purchases_flutter ^10.0.2`) |
| Server verify | `sync-premium-status` Edge Function |
| Client state | `isPremiumProvider` / `premiumGracePeriodProvider` / `effectivePremiumProvider` (`lib/domain/services/premium/premium_providers.dart`) |
| Route guard | `PremiumGuard` (`lib/router/guards/premium_guard.dart`, `static String? redirect(bool hasEffectiveAccess)`) |

## Premium Entitlement Flow

```
User purchases (RevenueCat SDK)
  → RevenueCat webhook
  → sync-premium-status Edge Function
  → Server validates with REVENUECAT_SECRET_API_KEY
  → Updates profiles.is_premium in Supabase
  → Client refreshes premium providers
```

## Key Providers

- `isPremiumProvider`, `premiumGracePeriodProvider`, `effectivePremiumProvider` (`premiumStatusProvider` does not exist)
- `GracePeriodStatus` values: `active`, `gracePeriod`, `expired`, `free`, `unknown` (`lib/core/enums/subscription_enums.dart` — NOT `none`)
- `freeTierUsageProvider` — current entity counts
- `isStatisticsRewardActiveProvider` / `isGeneticsRewardActiveProvider` — temporary rewarded-ad exemption from the premium gate for those two routes
- `PremiumGuard.redirect` is currently only wired to the `/genealogy` route; `/statistics` and `/genetics` gate inline in `app_router.dart` via `effectivePremiumProvider` OR the reward providers above

## Grace Period

Guards must accept `GracePeriodStatus.gracePeriod` as passing (payment renewal failures). Never gate on `isPremium` alone.

## Free Tier Limits

- Server-authoritative via `validate-free-tier-limit` Edge Function
- Client shows count display (UX) but cannot bypass
- `FreeTierLimitException` → upsell dialog

## Environment Variables

| Var | Where |
|-----|-------|
| `REVENUECAT_API_KEY_IOS` | dart-define (client, public) |
| `REVENUECAT_API_KEY_ANDROID` | dart-define (client, public) |
| `REVENUECAT_SECRET_API_KEY` | Edge Function secret only |

**Never put `REVENUECAT_SECRET_API_KEY` in client code.**

## See Also

- [[features/premium]]
- [[infrastructure/edge-functions]]
- [[domain/services-index]]
