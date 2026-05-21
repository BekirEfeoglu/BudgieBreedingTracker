# Feature: home

**Purpose**: Primary dashboard — quick scan of today's breeding tasks,
active incubations, recent chicks, sync state. First screen after login,
mounted at `AppRoutes.home` (`/`).

## Key Screens

| Screen | Route |
|--------|-------|
| Home dashboard | `AppRoutes.home` |

## Key Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `activeBreedingsForDashboardProvider(userId)` | `StreamProvider.family` | Active pairs (capped count) |
| `recentChicksProvider(userId)` | `StreamProvider.family` | Last-hatched chicks |
| `incubatingEggsLimitedProvider(userId)` | `StreamProvider.family` | Eggs currently incubating |
| `incubatingEggsSummaryProvider(userId)` | `FutureProvider.family` | Summary objects with milestone day |
| `todaysEggTurningSummaryProvider(userId)` | `FutureProvider.family` | Eggs needing turn today + next slot |
| `homeWidgetDashboardSnapshotProvider(userId)` | `Provider.family<AsyncValue<…>>` | Combines providers into the iOS/Android widget snapshot |
| `profileSyncProvider(userId)` | `FutureProvider.family` | Background profile refresh on resume |
| `connectivityProvider` | `Provider` | Drives offline banner |
| `conflictNotifierProvider` | `Notifier` | Drives sync conflict banner |

## Widgets

- Recent breeding pairs card
- Bird count summary
- Upcoming incubation milestones strip
- **Today's egg-turning routine card** (added 2026-05-15, sources `todaysEggTurningSummaryProvider`)
- OfflineBanner (global, mounted at the router shell, see [[patterns/empty-loading-error-states]])

## Performance Notes

- All providers use `.select()` to narrow rebuild scope (audit 2026-04-19)
- StreamProvider over polling — drift `.watch()` reactive queries
- Limited (`incubatingEggsLimitedProvider`) prevents unbounded list churn
  on power-users with 100+ active eggs

## Home Widget Bridge

`homeWidgetDashboardSnapshotProvider` aggregates today's egg-turning
count, active breeding count, next turn label, and a stale-after epoch.
[[domain/home-widget-service]] consumes the resulting
`HomeWidgetDashboardSnapshot` and pushes it to the platform widget.

## Empty / Loading / Error

- Empty state: "Start your first breeding" CTA → `AppRoutes.breedingForm`
- Loading: `SkeletonLoader(count: 3)` per section
- Error: per-section `ErrorState` with retry — section failures isolated,
  don't blank the whole dashboard

## See Also

- [[features/breeding]] — incubation lifecycle driver
- [[features/eggs]] — egg turning state
- [[domain/home-widget-service]] — platform widget consumer
- [[patterns/empty-loading-error-states]] — global OfflineBanner placement
- [[features/_features-index]]
