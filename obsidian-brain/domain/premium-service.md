# Premium Service

Source: `.claude/rules/premium-revenuecat.md`

**Location**: `lib/domain/services/` (premium-related services)

## Stack

| Layer | Tool |
|-------|------|
| Store | App Store + Google Play |
| Aggregator | RevenueCat (`purchases_flutter ^10.0.2`) |
| Server verify | `sync-premium-status` Edge Function |
| Client state | `premiumStatusProvider` |
| Route guard | `PremiumGuard` |

## Premium Entitlement Flow

```
User purchases (RevenueCat SDK)
  → RevenueCat webhook
  → sync-premium-status Edge Function
  → Server validates with REVENUECAT_SECRET_API_KEY
  → Updates profiles.is_premium in Supabase
  → Client refreshes premiumStatusProvider
```

## Key Providers

- `premiumStatusProvider` — server-sourced premium flag
- `premiumGracePeriodProvider` — `GracePeriodStatus` (active/gracePeriod/expired/none)
- `effectivePremiumProvider` — final gate for feature access
- `freeTierUsageProvider` — current entity counts

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
