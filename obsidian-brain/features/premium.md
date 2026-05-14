# Feature: premium

**Purpose**: Premium subscription management, upsell screens, Restore Purchases.

## Key Screens

- Premium upsell screen
- Current subscription status
- Restore Purchases button (iOS App Store policy — mandatory)

## Key Providers

- `premiumStatusProvider` — server-validated premium state
- `premiumGracePeriodProvider` — `GracePeriodStatus` (active/gracePeriod/expired/none)
- `effectivePremiumProvider` — final gate for feature access
- `freeTierUsageProvider` — entity counts for UX display

## Premium Flow

```
User purchases (RevenueCat SDK)
  → RevenueCat webhook → sync-premium-status Edge Function
  → Server validates with REVENUECAT_SECRET_API_KEY
  → Updates profiles.is_premium in Supabase
  → Client refreshes premiumStatusProvider on app resume
```

## Grace Period

Guards must accept `GracePeriodStatus.gracePeriod` as passing — not just `isPremium == true`. Grace period exists for payment renewal failures.

## Two Plans Only

Only two active premium plans (as of 2026-05-14). Adding a plan requires both RevenueCat dashboard and `PremiumPlanConfig` Dart constant updates.

## Route Guard

`PremiumGuard` in `lib/router/guards/` redirects non-premium users to upsell screen.

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
