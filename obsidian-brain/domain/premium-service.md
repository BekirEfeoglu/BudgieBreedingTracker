# Premium Service

Source: `.claude/rules/premium-revenuecat.md`

**Location**: `lib/domain/services/` (premium-related services)

## Stack

| Layer | Tool |
|-------|------|
| Store | App Store + Google Play |
| Aggregator | RevenueCat (`purchases_flutter ^10.4.2`) |
| Server verify | `sync-premium-status` Edge Function |
| Client state | `isPremiumProvider` / `premiumGracePeriodProvider` / `effectivePremiumProvider` (`lib/domain/services/premium/premium_providers.dart`) |
| Route guard | `PremiumGuard` (`lib/router/guards/premium_guard.dart`, `static String? redirect(bool hasEffectiveAccess)`) |

## Premium Entitlement Flow

```
User purchases (RevenueCat SDK)
  → sync-premium-status Edge Function
  → Server validates with REVENUECAT_SECRET_API_KEY
  → Atomically updates profile + subscription rows
  → Verified response updates Drift without pending client sync metadata

RevenueCat webhook
  → Refetches complete subscriber state
  → Applies the same atomic per-user RPC
  → Returns retryable 503 on transient processing/profile races
```

Before fetching RevenueCat, both sync paths check `user_subscriptions.provider`.
`manual` means an explicit audited admin override: `active|trial` grants access,
while `canceled|expired|past_due` removes it. `admin_revoke_premium` upserts a
manual canceled row even when no prior subscription exists, so app-resume sync
cannot silently reactivate the user. This access change does not cancel store
billing.

Verified RevenueCat results are written only through the service-role-only
`apply_verified_premium_status` RPC. It shares a per-user advisory lock with the
admin grant/revoke RPCs and rechecks `provider = manual` while holding that lock,
so an admin override arriving during a RevenueCat request cannot be overwritten
by the stale result.

Purchase and restore are reported as successful only after this server
reconciliation succeeds. `Profile.toSupabase()` strips all server-owned premium,
role, expiry, and grace fields from ordinary client profile writes. RevenueCat
initialize/login/logout operations are serialized across auth user changes.
When the SDK already reports an active store entitlement but the first server
pull has not observed the receipt yet, the client retries reconciliation after
500 ms and 1500 ms. It never sends a client premium assertion, and access opens
only from the verified server response.

The current RevenueCat offering remains authoritative when it has packages. If
it is empty, packages from every offering are aggregated and deduplicated before
the supported two-product filter runs, so stale legacy offering order cannot
hide the active plans. Debug iOS Simulator runs still initialize RevenueCat;
empty packages show a retryable Xcode/StoreKit configuration explanation.
Before SDK configuration, logging is capped at `warn` in debug and `error` in
release so StoreKit transaction/JWS/receipt payloads never enter local logs or
Sentry.

## Key Providers

- `isPremiumProvider`, `premiumGracePeriodProvider`, `effectivePremiumProvider` (`premiumStatusProvider` does not exist)
- `GracePeriodStatus` values: `active`, `gracePeriod`, `expired`, `free`, `unknown` (`lib/core/enums/subscription_enums.dart` — NOT `none`)
- `freeTierLimitServiceProvider` — client-side free-tier limit check (server-authoritative via `validate-free-tier-limit`)
- `isStatisticsRewardActiveProvider` / `isGeneticsRewardActiveProvider` — temporary rewarded-ad exemption from the premium gate for those two routes
- `PremiumGuard.redirect` is currently only wired to the `/genealogy` route; `/statistics` and `/genetics` gate inline in `app_router.dart` via `effectivePremiumProvider` OR the reward providers above

## Grace Period

Guards must accept `GracePeriodStatus.gracePeriod` as passing (payment renewal failures). Never gate on `isPremium` alone. Grace is granted only by a future, server-verified `profiles.grace_period_until`; the client and Edge Functions never fabricate it from `premium_expires_at`. The provider invalidates itself at the exact grace deadline.

This includes ad visibility: a grace-period subscriber is a paying customer and
must not see ads. Since 2026-07-25 all nine ad surfaces read
`effectivePremiumProvider` (see [[domain/ads-service]] § Premium Interaction);
the provider's doc comment previously said the opposite and has been corrected.

## Free Tier Limits

- `validate-free-tier-limit` is a fast UX preflight
- PostgreSQL `private.free_tier_usage` plus transactional table triggers are the
  authoritative enforcement layer for insert, activation update, delete, direct
  API writes, and concurrent writes
- Premium/admin/founder and active server-grace profiles are exempt; usage is
  still tracked so expiry cannot reset their count
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
