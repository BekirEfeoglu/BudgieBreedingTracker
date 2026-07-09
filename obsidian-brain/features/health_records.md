# Feature: health_records

**Purpose**: Health event tracking for individual birds or chicks — vet visits, medication, weight, cost, follow-up reminders.

## Key Screens

- Health record list — global, all-birds list (`HealthRecordListScreen`) with type filter chips + search; per-bird summary is a separate embedded widget in the birds feature (`bird_detail_health.dart`, latest N records + "view all" link)
- Health record detail (`HealthRecordDetailScreen`) — edit/delete actions
- Health record form (`HealthRecordFormScreen`) — create/edit, optional bird/chick link

`birdId` and `chickId` are nullable on the model — a record can exist without being linked to any bird/chick. The form selector stores chick selections in `chickId`, not `birdId`, and clears the other FK when one animal type is selected.

## Data

- **Table**: `health_records_table.dart` (types: checkup, illness, injury, vaccination, medication, death, unknown; optional `birdId`/`chickId`)
- **Repository**: `health_record_repository.dart` — requires `ValidatedSyncMixin` (optional parents: bird/chick)
- **Statistics**: `HealthRecordsDao.watchCountsByTypeInRange` (SQL-aggregated) feeds `healthRecordTypeDistributionProvider` → `HealthRecordTypeChart`

## Attachments

No photo/document upload exists for health records — the model has no attachment field and no Supabase Storage bucket is provisioned for this feature.

## Notifications

Creating a record with a `birdId` schedules health-check reminders via `NotificationScheduler` (daily until `followUpDate`, or 7 days by default). A chick-only record does not schedule health-check reminders because the current notification payload is bird-oriented. See `.claude/rules/notifications.md`.

Reminders are keyed by `recordId` (not bare `birdId`) so multiple records
for the same bird don't collide — `scheduleHealthCheckReminder`'s
`entityKey = recordId ?? birdId`. `updateRecord`/`deleteRecord` re-fetch the
prior row (best-effort — a fetch failure logs a warning but does not block
the save/delete) and cancel+reschedule via `cancelHealthCheckReminders(birdId,
recordId: ...)` whenever `followUpDate` or `birdId` changed; `deleteRecord`
always cancels. Before 2026-07-02 this cancellation path did not exist —
editing or deleting a record with a follow-up date left the old reminders
firing (zombie notifications).

## Rules

- `.claude/rules/data-layer.md` — ValidatedSyncMixin required for FK to bird/chick
- `.claude/rules/statistics.md` — SQL-side aggregation for type distribution chart

## See Also

- [[features/birds]]
- [[features/statistics]]
- [[features/_features-index]]
