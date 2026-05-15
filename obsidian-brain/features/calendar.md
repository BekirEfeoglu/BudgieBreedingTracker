# Feature: calendar

**Purpose**: Event calendar — breeding milestones, vet appointments, reminders.

## Key Screens

- Monthly/weekly calendar view
- Event detail
- Add event / reminder form

## Key Providers

- `calendarEventsProvider(month)` — events for a given month
- `calendarEventFilterProvider` — all events vs incubation-focused events

## Event Sources

- Breeding milestones (auto-generated from incubation start dates)
- Manual reminders
- Vet appointments

## Filters

- Calendar includes an All / Incubation segmented filter.
- Incubation mode keeps breeding, mating, egg, egg-laying, hatching, and chick events.

## See Also

- [[domain/calendar-service]]
- [[features/breeding]]
- [[features/_features-index]]
