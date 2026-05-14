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

## Runtime Flags (SharedPreferences / Remote Config)

- `analytics_enabled` — user opt-in
- `notification_quiet_hours` — quiet hours setting
- `experimental_*` — developer menu toggles

### Server-Side Kill Switch

`app_config` Supabase table:
- Pulled on app start + each foreground
- Cache: 1h TTL
- Default: **fail-open** (feature ON if config unavailable)

```dart
final config = ref.watch(remoteConfigProvider);
if (config.isCommunityDisabled) return const FeatureDisabledScreen();
```

## Entitlement Flags (Premium)

See [[patterns/security]] and [[domain/premium-service]]. Summary:
- Server-validated `is_premium`
- `PremiumGuard` on routes
- `premiumGracePeriodProvider` honored as passing

## Experimental Features (Dev Menu)

Hidden by 5-tap on Settings header:
- `experimental_local_ai` — LocalAiService preview
- `experimental_genetics_v3` — new calculator version
- `debug_show_provider_logs` — provider rebuild logs

Production users cannot access. Founders/testers can.

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
  remoteConfigProvider.overrideWithValue(RemoteConfig(isCommunityDisabled: true)),
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
