# Feature: home

**Purpose**: Main dashboard — summary widgets, quick actions, sync status.

## Key Screens

- Home dashboard

## Key Providers

- Uses `.select()` on providers to narrow rebuilds (audit 2026-04-19)
- `connectivityProvider` — shows offline banner when disconnected
- `conflictNotifierProvider` — shows sync conflict banner

## Widgets

- Recent breeding pairs
- Bird count summary
- Upcoming incubation milestones
- OfflineBanner (global, app-wide)

## See Also

- [[features/statistics]]
- [[features/_features-index]]
- [[patterns/empty-loading-error-states]]
