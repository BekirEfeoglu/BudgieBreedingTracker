# Feature Flags

Source: `.claude/rules/feature-flags.md`

Three types: **compile-time** (dart-define), **runtime** (SharedPreferences/remote config), **entitlement** (premium).

## Compile-Time Flags (dart-define)

Debug/staging only — hardcoded to defaults in production binary.

| Flag | Type | Purpose |
|------|------|---------|
| `DEBUG_START_ROUTE` | string | Skip splash, open at route (`/birds`) |
| `DEBUG_GENETICS_FIXTURE` | string | Preset genetics state |
| `SENTRY_ENVIRONMENT` | string | `development`/`staging`/`production` |

```dart
const debugRoute = String.fromEnvironment('DEBUG_START_ROUTE');
if (debugRoute.isNotEmpty) return GoRouter(initialLocation: debugRoute);
```

**Never put debug flags in production binary.**

## Static Rollout Flags (`FeatureFlags`)

`lib/core/constants/feature_flags.dart` — Dart `const`, fixed at compile time,
tree-shaken when false. Six flags:

| Flag | Value | Meaning |
|------|-------|---------|
| `anonymousSignInEnabled` | `false` | Mirrors Supabase `enable_anonymous_sign_ins=false` |
| `communityEnabled` | `true` | Registers community routes |
| `marketplaceEnabled` | `true` | Registers marketplace routes |
| `messagingEnabled` | `true` | Registers DM routes (2026-07-10) |
| `gamificationEnabled` | `true` | XP / badge / leaderboard surfaces |
| `messageAttachmentsEnabled` | `true` | DM photo attachments |

**A flag registers routes; it does not grant access.** `FounderGuard` restricts
`/community/*`, `/marketplace/*` and `/ai-predictions` to founder accounts, so
those two `true` flags are invisible to ordinary users today — and messaging is
transitively founder-only, since its only entry points live on those surfaces.
Reading "flag is true, therefore users see it" is wrong here. See
[[architecture/router-navigation]] and `.claude/rules/security.md` § Route Guards.

## Runtime Flags (SharedPreferences / Remote Config)

- `analytics_enabled` — user opt-in
- `notification_quiet_hours` — quiet hours setting
- `experimental_*` — developer menu toggles (planned — not yet implemented)

### Sync Rollout Flags (operational, not security)

| Flag | Default | Purpose |
|------|---------|---------|
| `syncOfflineBannerEnabledProvider` | `true` | Global offline/error banner kill switch |
| `syncBackgroundEnabledProvider` | `false` | Controlled background push task enable |
| `syncRealtimeEnabledProvider` | `false` | Foreground realtime subscription rollout |
| `syncRealtimeServerKillSwitchProvider` | `false` | Remote-config realtime global off |
| `syncRealtimeRolloutPercentProvider` | `100` | Deterministic user-bucket ramp threshold |

Realtime starts only when local flag is on, server kill switch is off, and user bucket falls under ramp percent. Ramp plan: 5% internal → 25% beta → 100% stable. On crash/timeout/conflict spikes, flip kill switch first, ship fix second.

### Server-Side Kill Switch

**Not implemented** (verified 2026-07-02): `app_config` Supabase table,
`remoteConfigProvider`, `RemoteConfig` class, and `isCommunityDisabled` do
not exist in the codebase — future design goal only. Don't confuse with the
real, working sync kill switch above (`syncRealtimeServerKillSwitchProvider`).
Design intent if implemented:
- Pulled on app start + each foreground
- Cache: 1h TTL
- Default: **fail-open** (feature ON if config unavailable)

```dart
// Design goal — not yet real
final config = ref.watch(remoteConfigProvider);
if (config.isCommunityDisabled) return const FeatureDisabledScreen();
```

## Entitlement Flags (Premium)

See [[patterns/security]] and [[domain/premium-service]]. Summary:
- Server-validated `is_premium`
- `PremiumGuard` on routes
- `premiumGracePeriodProvider` honored as passing

## Experimental Features (Dev Menu)

**Not implemented** (verified 2026-07-02): the "5-tap on Settings header"
developer menu and the `experimental_*` flags do not exist in the codebase —
future design goal only. The sole debug-gated route today is
`geneticsColorAudit` (`user_routes.dart`, wrapped in `kDebugMode`).

## Flag Lifecycle

```
Add (default false, local dev)
  → Beta (dev menu enable, internal test)
  → Rollout (server config 10% → 50% → 100%)
  → Stable (default true, remove old path)  ← max 2 releases
  → Delete (flag removed from codebase)
```

`experimental_*` flags must not live > 90 days. If stale: stabilize or delete.

## Testing

```dart
// Use provider override, never setFlag
final container = ProviderContainer(overrides: [
  syncOfflineBannerEnabledProvider.overrideWithValue(false),
]);
addTearDown(container.dispose);
```

## Anti-Patterns

1. Debug dart-define flag in production binary
2. SharedPreferences flag for security decisions (bypassable)
3. No kill switch for new feature deployment
4. Flag explosion (> 5 cross-product flags)
5. Stale flag > 90 days
6. Committing `.env` file
7. App crash when remote config unavailable (fail-open required)
8. Flag decision deep in widget tree (check at root, pass as prop)

## See Also

- [[infrastructure/environment]] — dart-define vars
- [[domain/premium-service]] — entitlement flags
