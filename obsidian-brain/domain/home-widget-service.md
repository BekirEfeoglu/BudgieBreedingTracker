# Home Widget Service

Source: `.claude/rules/home-widget.md` (primary — shared storage schema, refresh triggers, iOS WidgetKit timeline budget, deeplink, lock-screen families)

**Location**: `lib/domain/services/home_widget/`

## Responsibility

Pushes a lightweight dashboard snapshot to the platform home / lock-screen
widget (iOS WidgetKit, Android AppWidgetProvider). The app is the source of
truth; the widget is read-only. Snapshot updates happen on relevant data
changes (egg turning, breeding lifecycle) and lifecycle events (resume,
sync complete).

## Constants

| Constant | Value |
|----------|-------|
| `appGroupId` | `group.com.budgiebreeding.tracker` (iOS shared container) |
| `iOSWidgetName` | `BudgieDashboardWidget` |
| `androidWidgetName` | `BudgieDashboardWidgetReceiver` |
| `qualifiedAndroidWidgetName` | Fully-qualified Java class path |

## Snapshot Schema

`HomeWidgetDashboardSnapshot` (plain `@immutable` class with hand-written
`==`/`hashCode` — **not** a Freezed model, no `@freezed` annotation or
generated part files) carries:

| Key | Type | Meaning |
|-----|------|---------|
| `egg_turning_count` | int | Eggs needing turn today |
| `active_breedings_count` | int | Currently active breedings |
| `next_turning_label` | string | Localized next-turn slot |
| `has_work_today` | bool | Drives the "work pending" indicator |
| `last_updated_label` | string | Human-readable timestamp |
| `last_updated_epoch_seconds` | int | Numeric for staleness math |

Keys are constants in `AppHomeWidgetConstants` — adding a key requires
updating the iOS Swift widget and Android XML provider together.

`==`/`hashCode` deliberately **exclude** `last_updated_label`/
`last_updated_at` (display-only, change on every recompute even when the
dashboard content is unchanged) — only `egg_turning_count`/
`active_breedings_count`/`next_turning_label` participate in equality. This
is what keeps `home_screen.dart`'s `ref.listen` dedup guard
(`if (!next.hasValue || next.value == previous?.value) return;`) effective;
before 2026-07-02 the timestamp fields were included in equality, so the
guard almost never short-circuited and the native widget re-synced on every
unrelated Drift table invalidation, burning into iOS WidgetKit's ~40/day
timeline budget (anti-pattern #1 in `.claude/rules/home-widget.md`).

## Gateway Abstraction

`HomeWidgetGateway` interface decouples the service from `home_widget`
plugin. `PluginHomeWidgetGateway` is the production impl; tests inject a
fake gateway that records calls. Methods: `setAppGroupId`, `saveString`,
`saveInt`, `saveBool`, `updateWidget`.

## Update Cycle

```
HomeWidgetService.syncDashboardSnapshot(snapshot)
  ├── setAppGroupId (iOS shared container handshake)
  ├── saveString/Int/Bool per key
  └── updateWidget(iOS + Android names) — triggers system widget redraw
```

The call is debounced upstream — repeated calls within the same
short window collapse to a single update. Free-tier and login state
gating happen in the upstream provider, not this service.

## Anti-Patterns

1. Pushing a snapshot without a logged-in user (widget shows stale data of previous user)
2. Embedding business logic in the widget (snapshot must be pre-computed)
3. Bypassing the gateway abstraction (tests can't substitute)
4. Updating one platform's name only (widget desyncs across iOS/Android)
5. Sending PII in snapshot strings (bird names OK, owner email NO)

## See Also

- [[features/home]] — provider feeding the snapshot
- [[domain/services-index]]
