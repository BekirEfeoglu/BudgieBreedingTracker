# Router & Navigation

Source: `lib/router/` + `.claude/rules/ui-patterns.md` § GoRouter, `.claude/rules/security.md` § Route Guards

GoRouter 17+ composition layer. `router/` is the ONLY layer allowed to import
feature screens/providers to assemble routes and guards (see [[architecture/layers]]).

## File Map

| File | Role |
|------|------|
| `lib/router/app_router.dart` | GoRouter instance, redirect chain, top-level routes |
| `lib/router/route_names.dart` | `AppRoutes` constants — 75 route paths |
| `lib/router/route_utils.dart` | `isValidRouteId` (UUID check), `validEditIdOrNull` |
| `lib/router/router_notifier.dart` | `RouterNotifier` — `refreshListenable`, re-runs redirect on state change |
| `lib/router/redirect_guards.dart` | `sessionLockRedirect`, `authRedirect`, `twoFactorRedirect` |
| `lib/router/guards/admin_guard.dart` | `AdminGuard.redirect(bool)` → home if not admin |
| `lib/router/guards/founder_guard.dart` | `FounderGuard.redirect(bool)` → founder-only surfaces |
| `lib/router/guards/premium_guard.dart` | `PremiumGuard.redirect(bool)` → `/premium` upsell |
| `lib/router/routes/` | 7 grouped builders: admin, auth, community, gamification, marketplace, messaging, user |

## Redirect Chain (order is load-bearing)

Evaluated top-to-bottom in `app_router.dart` `redirect:`; first non-null wins.

1. **Maintenance mode** — `maintenanceModeProvider` → `/maintenance` (admin routes exempt; auto-exit when mode clears)
2. **Session lock** — locked session forces login
3. **Auth** — unauthenticated → login (unless anonymous-allowed route); authenticated on auth screens → home
4. **2FA** — pending MFA factor forces `/two-factor-verify`
5. **Init guard** — logged in + `appInitializationProvider` not ready → splash; splash + ready → home (or `DEBUG_START_ROUTE` in debug)
6. **Premium gates** (inline, NOT all via `PremiumGuard`):
   - `/statistics` → `effectivePremiumProvider` OR `isStatisticsRewardActiveProvider`
   - genetics routes (`/genetics`, history, reverse, compare) → premium OR `isGeneticsRewardActiveProvider`; reward is **consumed once per route entry** (`lastConsumedGeneticsRewardLocation` tracking)
   - `/genealogy` → `PremiumGuard.redirect` (the ONLY route using PremiumGuard; no rewarded-ad bypass, deliberate)
7. **Founder gate** — `/community/*` (except public community guidelines), `/marketplace/*`, and AI predictions are currently **founder-only** via `FounderGuard`
8. **Admin gate** — `/admin/*` via `AdminGuard`

All guards are **stateless** — they derive from current provider state via `ref.read`.
Grace period counts as premium: gates read `effectivePremiumProvider`, never raw `isPremiumProvider`.

## Main Tab Shell

The five primary destinations use `StatefulShellRoute.indexedStack`; each
branch owns a Navigator. Switching tabs therefore preserves the branch route
stack plus local widget and scroll state. Tapping the already-selected
destination calls `goBranch(..., initialLocation: true)` and returns that branch
to its root. Chicks belongs to the More branch, so `/chicks` keeps More selected.
Detail/form routes still target `rootNavigatorKey` and intentionally cover the
bottom navigation.

## RouterNotifier

Single GoRouter instance for the app lifetime. `RouterNotifier` listens to
`isAuthenticatedProvider`, `isAdminProvider`, `effectivePremiumProvider`,
`maintenanceModeProvider`, `appInitializationProvider`, `initSkippedProvider`,
`pendingMfaFactorIdProvider` and coalesces changes into one `notifyListeners()`
— never rebuild/recreate the router on provider change.

## Route Definition Rules

- **Specific before parameterized**: `/birds/form` BEFORE `/birds/:id` (anti-pattern #18)
- **Forward nav**: `context.push()` — never `context.go()` (replaces stack, anti-pattern #17); back = `context.pop()`
- **Primary tab switching**: only `MainShell` uses
  `StatefulNavigationShell.goBranch`; do not replace this with path-based
  `context.go()` or branch state will be discarded
- **Edit mode**: query param `?editId=<uuid>` — read via `validEditIdOrNull`; invalid/stale id silently opens create mode (no NotFound flicker)
- **Deep-link safety**: path `:id` params validated with `isValidRouteId` (UUID regex) before reaching detail screens — crafted deep links can't inject arbitrary strings
- All routes must be URI-addressable (deep linking, notification payload `route` field — see [[domain/notification-service]])

## Debug Affordances

- `--dart-define=DEBUG_START_ROUTE=/birds` — skip splash, open at route (debug builds only; `overridePlatformDefaultLocation`)
- `geneticsColorAudit` route — the only `kDebugMode`-gated route (`lib/router/routes/user_routes.dart`)
- `SentryNavigatorObserver` attached for navigation breadcrumbs

## See Also

- [[patterns/ui-patterns]] — GoRouter usage patterns in UI code
- [[domain/premium-service]] — effectivePremium, grace period, reward providers
- [[features/splash]] — init flow that the init guard waits on
- [[patterns/security]] — guard policy
- [[index]]
