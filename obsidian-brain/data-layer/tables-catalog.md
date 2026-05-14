# Drift Tables Catalog

Source: `.claude/rules/data-layer.md`, `CLAUDE.md`

20 Drift tables in `lib/data/local/database/tables/`. Each has a corresponding DAO and Mapper.

## Tables

| Table File | Entity | FK Parents |
|-----------|--------|-----------|
| `birds_table.dart` | Bird | — (root entity) |
| `breeding_pairs_table.dart` | BreedingPair | Bird × 2 (male + female) |
| `incubations_table.dart` | Incubation | BreedingPair |
| `clutches_table.dart` | Clutch | Incubation |
| `eggs_table.dart` | Egg | Clutch |
| `chicks_table.dart` | Chick | Egg |
| `health_records_table.dart` | HealthRecord | Bird |
| `event_reminders_table.dart` | EventReminder | Incubation |
| `sync_metadata_table.dart` | SyncMetadata | — |
| `user_profiles_table.dart` | UserProfile | — |
| `genetics_results_table.dart` | GeneticsResult | Bird × 2 |
| `calendar_events_table.dart` | CalendarEvent | various |
| `notifications_table.dart` | NotificationRecord | — |
| `community_profiles_table.dart` | CommunityProfile | — (cache) |
| `marketplace_listings_table.dart` | MarketplaceListing | Bird |
| `gamification_badges_table.dart` | Badge | — |
| `user_badges_table.dart` | UserBadge | Badge, UserProfile |
| `genealogy_table.dart` | GenealogyEntry | Bird |
| `feedback_table.dart` | FeedbackEntry | — |
| `app_config_table.dart` | AppConfig | — |

*Note: exact table names derived from patterns in rules files; verify against actual table files in `lib/data/local/database/tables/`.*

## Common Patterns

All tables:
- Use client-generated UUID primary key (text)
- Include `user_id` (foreign key to auth user)
- Include `created_at` and `updated_at` (DateTime, UTC)
- Include `is_deleted` or soft-delete field for sync safety
- Enum columns use `IntColumn` with `TypeConverter`

## ValidatedSyncMixin Repos

The following repos require `ValidatedSyncMixin` due to FK parents:
- `egg_repository` (parent: breeding_pair)
- `chick_repository` (parent: egg)
- `health_record_repository` (parent: bird)
- `breeding_pair_repository` (parent: bird)
- `event_reminder_repository` (parent: incubation)

## See Also

- [[data-layer/drift]] — import rules, query patterns
- [[data-layer/repositories]] — ValidatedSyncMixin
