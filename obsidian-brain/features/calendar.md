# Feature: calendar

Source: `.claude/rules/calendar.md` (event generation, deterministic notification IDs, deeplink, sync via ValidatedSyncMixin)

**Purpose**: Visualize breeding milestones, vet appointments, and manual
reminders on a month/week/day calendar. Auto-generated entries (incubation
milestones) coexist with manual reminders the user adds.

## Key Screens

| Screen | Route |
|--------|-------|
| `CalendarScreen` | `AppRoutes.calendar` (calendar grid + day sheet) |

## Views

`CalendarViewMode` enum (`month`, `week`, `day`) drives layout. State held
by `calendarViewProvider`. View change preserves `selectedDateProvider`.

## Filters

`CalendarEventFilter` (`all`, `incubation`):

- `all`: every event source
- `incubation`: keeps breeding, mating, egg, egg-laying, hatching, chick

Filter stored in `calendarEventFilterProvider`.

## Key Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `eventsStreamProvider(userId)` | `StreamProvider.family` | Drift stream over events table |
| `eventsForSelectedDateProvider` | `Provider` | Filtered view (uses `selectedDateProvider` + filter) |
| `eventsForMonthProvider(month)` | `Provider.family` | Grouped by date for grid view |
| `eventsForWeekProvider` | `Provider` | Week-grouped view |
| `selectedDateProvider` | `NotifierProvider<…, DateTime>` | Selected day |
| `displayedMonthProvider` | `NotifierProvider<…, DateTime>` | Visible month (pager) |
| `eventRealtimeSyncProvider(userId)` | `Provider.family<void, …>` | Subscribes to Supabase realtime |

## Event Sources

- Breeding milestones (auto-generated from incubation start dates by
  [[domain/calendar-service]])
- Manual reminders (user-added via `event_form_sheet.dart`)
- Vet appointments

`Event` model owns the union; UI distinguishes by `EventType` enum.

## Widgets

- `CalendarGrid` — month view (square date cells with event dots)
- `CalendarWeekView` — week strip + event list
- `CalendarDayView` — single-day timeline
- `CalendarEventListSliver` — collapsing event list under date
- `EventCard`, `EventDetailModal`, `EventFormSheet` — CRUD UI

## Realtime

`eventRealtimeSyncProvider(userId)` subscribes to Supabase realtime
changes on the events table and triggers `ref.invalidate(eventsStream…)`
on change. Sits in the calendar feature because that's the primary
consumer; not duplicated elsewhere.

## Timezone

Event datetimes stored UTC, displayed via `DateFormat` in user locale
(see [[patterns/datetime-format]]). Notification scheduling uses
`tz.TZDateTime` so DST doesn't drift reminders.

## See Also

- [[domain/calendar-service]] — auto-generation rules
- [[features/breeding]] — milestone source
- [[domain/notification-service]] — reminder pipeline
- [[patterns/datetime-format]]
- [[features/_features-index]]
