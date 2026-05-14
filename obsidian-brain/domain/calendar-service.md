# Calendar Service

**Location**: `lib/domain/services/` (calendar-related)

## Responsibility

Generates and manages calendar events from domain data:
- Incubation milestone events (from breeding pairs)
- Vet appointment reminders
- Manual reminder events

## Side Effect Rule

Calendar generation is a **side effect** after local persistence succeeds. A Supabase-unavailable calendar generation is an expected offline condition — log at info level and continue. Failure must not undo the primary mutation.

## Event Sources

| Source | Event Type |
|--------|-----------|
| Incubation start date + species config | Expected hatch dates |
| Manual user creation | Custom reminders |
| Breeding pair completion | Season-end events |

## Integration with Notifications

Calendar events trigger local notifications via [[domain/notification-service]] (`IncubationReminderService`).

## See Also

- [[features/calendar]]
- [[features/breeding]]
- [[domain/notification-service]]
- [[domain/services-index]]
