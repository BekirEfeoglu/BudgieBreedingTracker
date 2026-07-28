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
Week and day layouts expose 48dp previous/next buttons with localized semantic
labels; horizontal swipe remains an optional shortcut, never the only way to
change periods.

## Filters

`CalendarEventFilter` (`all`, `incubation`):

- `all`: every event source
- `incubation`: keeps breeding, mating, egg, egg-laying, hatching, chick

Filter stored in `calendarEventFilterProvider`.

## Key Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `eventsStreamProvider(userId)` | `StreamProvider.family` | Drift stream over events table |
| `filteredCalendarEventsProvider` | `Provider` | Single source of truth for the filter pass — runs `filterCalendarEvents` once per (stream, filter) change |
| `eventsForSelectedDateProvider` | `Provider` | Day view — derives from `filteredCalendarEventsProvider` + `selectedDateProvider` |
| `eventsForMonthProvider(month)` | `Provider.family` | Month grid — derives from `filteredCalendarEventsProvider`, grouped by date |
| `eventsForWeekProvider` | `Provider` | Week view — derives from `filteredCalendarEventsProvider` |

The three view providers no longer each re-run `filterCalendarEvents`; they
share `filteredCalendarEventsProvider` so the O(n) filter pass runs once per
filter/stream change instead of three times.
| `selectedDateProvider` | `NotifierProvider<…, DateTime>` | Selected day |
| `displayedMonthProvider` | `NotifierProvider<…, DateTime>` | Visible month (pager) |
| `eventRealtimeSyncProvider(userId)` | `Provider.family<void, …>` | Subscribes to Supabase realtime |

## Event Sources

- Breeding milestones (auto-generated from incubation start dates by
  [[domain/calendar-service]])
- Manual reminders (user-added via `event_form_sheet.dart`)
- Vet appointments

`Event` model owns the union; UI distinguishes by `EventType` enum.

The manual-event form offers a reminder-offset dropdown
(`kReminderOffsetOptions` in `calendar_form_providers.dart`: no reminder / at
time / 30 min / 1 hour / 1 day before). `EventFormNotifier.createEvent`'s
`reminderMinutesBefore` param drives it — default `kDefaultReminderMinutesBefore`
(30, the historic behavior), `null` skips the reminder. Added 2026-07-03; before
that every event got a fixed 30-minute reminder.

**Editing (2026-07-09):** the dropdown now shows in edit mode too. On open,
`_loadExistingReminder` reads the event's current offset via
`eventReminderRepository.getByEvent` (pre-fills, or "no reminder" when none).
The field and Save action stay disabled until that async read completes. A read
failure shows a generic localized error and retry action; the form never saves
the default offset over an existing reminder whose value failed to load.
Saving calls `updateEvent(event, reminderMinutesBefore:, reconcileReminder:
true)`, which cancels + removes the old reminder(s) (and their OS
notifications) then re-creates the chosen offset — the cancel+reschedule
pattern. `reconcileReminder` defaults to `false` so other `updateEvent` callers
(e.g. a status change) keep the legacy date-shift-only re-arm.

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
