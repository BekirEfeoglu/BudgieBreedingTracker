# Drift Tables Catalog

Source: `.claude/rules/data-layer.md`, `CLAUDE.md`

20 Drift tables in `lib/data/local/database/tables/`. Each has a corresponding DAO and Mapper.

## Tables

Verified against `ls lib/data/local/database/tables/` (2026-07-02):

| Table File | Entity | FK Parents |
|-----------|--------|-----------|
| `birds_table.dart` | Bird | — (root entity; self-referential `father_id`/`mother_id`) |
| `breeding_pairs_table.dart` | BreedingPair | Bird × 2 (male + female) |
| `incubations_table.dart` | Incubation | BreedingPair |
| `clutches_table.dart` | Clutch | Incubation, BreedingPair, Nest |
| `eggs_table.dart` | Egg | Incubation, Clutch |
| `chicks_table.dart` | Chick | Bird, Egg, Clutch |
| `nests_table.dart` | Nest | — (root entity) |
| `health_records_table.dart` | HealthRecord | Bird |
| `events_table.dart` | Event | Bird, BreedingPair, Chick |
| `event_reminders_table.dart` | EventReminder | Event |
| `growth_measurements_table.dart` | GrowthMeasurement | Chick |
| `genetics_history_table.dart` | GeneticsHistory | Bird × 2 (father_id, mother_id) |
| `sync_metadata_table.dart` | SyncMetadata | — |
| `conflict_history_table.dart` | ConflictHistory | — |
| `notifications_table.dart` | Notification | — |
| `notification_schedules_table.dart` | NotificationSchedule | — |
| `notification_settings_table.dart` | NotificationSettings | — |
| `photos_table.dart` | Photo | various (entity-scoped, user-scoped) |
| `profiles_table.dart` | Profile | — |
| `user_preferences_table.dart` | UserPreferences | — |

## Common Patterns

All tables:
- Use client-generated UUID primary key (text)
- Include `user_id` (foreign key to auth user)
- Include `created_at` and `updated_at` (DateTime, UTC)
- Include `is_deleted` or soft-delete field for sync safety
- Enum columns use `IntColumn` with `TypeConverter`

## ValidatedSyncMixin Repos

The following repos require `ValidatedSyncMixin` due to FK parents:
- `egg_repository` (parents: incubation, clutch — injects `IncubationsDao` + `ClutchesDao`)
- `chick_repository` (parent: egg)
- `health_record_repository` (parent: bird)
- `breeding_pair_repository` (parent: bird)
- `event_reminder_repository` (parent: event — injects `EventsDao`)

## Local FK Graph

Source of truth: Drift `references(...)` declarations under `lib/data/local/database/tables/`.

| Parent | Children / FK Columns |
|--------|------------------------|
| `birds` | `birds.father_id`, `birds.mother_id`; `breeding_pairs.male_id`, `breeding_pairs.female_id`; `clutches.male_id`, `clutches.female_id`; `chicks.bird_id`; `events.bird_id`; `health_records.bird_id`; `genetics_history.father_id`, `genetics_history.mother_id`; `marketplace_listings.bird_id` |
| `breeding_pairs` | `incubations.breeding_pair_id`; `clutches.breeding_pair_id`; `events.breeding_pair_id` |
| `incubations` | `clutches.incubation_id`; `eggs.incubation_id` |
| `clutches` | `eggs.clutch_id`; `chicks.clutch_id`; `incubations.clutch_id` |
| `eggs` | `chicks.egg_id` |
| `chicks` | `events.chick_id`; `growth_measurements.chick_id` |
| `events` | `event_reminders.event_id` |
| `nests` | `clutches.nest_id` |

Cascade policy:
- Drift FK constraints are enabled per connection with `PRAGMA foreign_keys = ON`.
- User-facing deletes remain logical soft deletes unless a DAO/repository explicitly owns a destructive cleanup flow.
- Destructive parent flows must close or clean up related incubations, eggs, reminders, notifications, and calendar work before reporting success.
- Sync repositories must validate parent existence before local writes when FK parents can arrive out of order.

## Composite Index Policy

Schema v23 adds composite indexes for the high-traffic FK and dashboard paths. Keep new FK filters covered by either an existing single-column FK index or a composite index matching the query prefix.

| Query Pattern | Required Index |
|---------------|----------------|
| incubating eggs by incubation/status/delete state | `idx_eggs_incubation_status_deleted` |
| chick lookup by egg while excluding deleted rows | `idx_chicks_egg_deleted` |
| health timeline by bird while excluding deleted rows | `idx_health_records_bird_deleted` |
| calendar/event lookup by bird while excluding deleted rows | `idx_events_bird_deleted` |
| clutch lookup by breeding pair while excluding deleted rows | `idx_clutches_breeding_deleted` |
| incubation lookup by breeding pair and status | `idx_incubations_breeding_pair_status` |
| notification unread/read list by user | `idx_notifications_user_read` |
| photo lookup by entity scoped to user | `idx_photos_entity_user` |
| growth chart by chick and measurement date | `idx_growth_measurements_chick_date` |

CI coverage:
- `test/data/local/database/app_database_indexes_test.dart` asserts schema `>= 23` (a floor, not the exact version) and required index names in `sqlite_master`.
- Future FK-heavy DAO work should extend the same test instead of relying on manual profiling notes.

## See Also

- [[data-layer/drift]] — import rules, query patterns
- [[data-layer/repositories]] — ValidatedSyncMixin
