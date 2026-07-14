# Feature: premium

**Purpose**: Premium subscription management, upsell screens, Restore Purchases.

## Key Screens

- Premium upsell screen
- Current subscription status
- Restore Purchases button (iOS App Store policy — mandatory)

## Key Providers

- `isPremiumProvider`, `premiumGracePeriodProvider`, `effectivePremiumProvider` (`premiumStatusProvider` does not exist)
- `GracePeriodStatus` values: `active`/`gracePeriod`/`expired`/`free`/`unknown` (NOT `none`)
- `freeTierLimitServiceProvider` — client-side free-tier limit check for UX (server-authoritative via `validate-free-tier-limit`)

## Premium Flow

```
User purchases (RevenueCat SDK)
  → RevenueCat webhook → sync-premium-status Edge Function
  → Server validates with REVENUECAT_SECRET_API_KEY
  → Updates profiles.is_premium in Supabase
  → Client refreshes premium providers on app resume
```

## Grace Period

Guards must accept `GracePeriodStatus.gracePeriod` as passing — not just `isPremium == true`. Grace period exists for payment renewal failures.

## Two Plans Only

Only two active premium plans (as of 2026-05-14). Adding a plan requires both RevenueCat dashboard and `lib/domain/services/premium/premium_plan_utilities.dart` updates.

## Route Guard

`PremiumGuard.redirect(bool hasEffectiveAccess)` (`lib/router/guards/premium_guard.dart`) redirects to `AppRoutes.premium` when access is false — currently only wired to `/genealogy`. `/statistics` and `/genetics` gate inline in `app_router.dart` via `effectivePremiumProvider` OR a temporary rewarded-ad exemption (`isStatisticsRewardActiveProvider`/`isGeneticsRewardActiveProvider`).

## Free Tier Limits

- Entity insert calls `validate-free-tier-limit` Edge Function
- Client shows count display (UX only — not authoritative)
- `FreeTierLimitException` → upsell dialog

## Rules

- `.claude/rules/premium-revenuecat.md` — full premium details
- `.claude/rules/edge-functions.md` — sync-premium-status, validate-free-tier-limit

## See Also

- [[features/_features-index]]
- [[domain/premium-service]]
- [[infrastructure/edge-functions]]
