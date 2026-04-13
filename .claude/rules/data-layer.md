# Data Layer

## Drift (Local Database)
- **Tables**: `lib/data/local/database/tables/` (20 tables)
- **DAOs**: `lib/data/local/database/daos/` (20 DAOs)
- **Mappers**: `lib/data/local/database/mappers/` (20 mappers)
- **Converters**: `lib/data/local/database/converters/enum_converters.dart`
- **Schema version**: 20
- Import tables DIRECTLY from table file, not via `app_database.dart`
- Use `.equalsValue()` for enum columns, not `.equals()`

### Query Patterns
```dart
// Correct: equalsValue for enums
select(birds)..where((t) => t.gender.equalsValue(BirdGender.male));

// Correct: direct table import in DAO
import 'package:budgie/data/local/database/tables/birds_table.dart';
// Wrong: import via app_database.dart
```

### Schema Migration
- Increment `schemaVersion` in `app_database.dart`
- Add migration logic in `onUpgrade` callback
- Add SQL migration to `supabase/migrations/` for remote schema
- Test migration with fresh DB and upgrade-from-previous scenarios

## Supabase (Remote)
- **Remote sources**: `lib/data/remote/api/` (26 entity + base + 2 caches + providers)
- **Storage**: `lib/data/remote/storage/storage_service.dart`
- **Constants**: `SupabaseConstants` class (106 table/column constants)
- **Edge Functions**: 6 in `supabase/functions/`
- **Migrations**: 116 SQL files in `supabase/migrations/`
- Always use `SupabaseConstants` for table/column names — never hardcode
- Use `.toSupabase()` extension — never send `created_at`/`updated_at` manually

### Remote Source Pattern
```dart
// Always use SupabaseConstants
final data = await client
    .from(SupabaseConstants.birdsTable)
    .select()
    .eq(SupabaseConstants.userId, userId);

// Use .toSupabase() for inserts/updates — strips created_at/updated_at
await client.from(SupabaseConstants.birdsTable).upsert(bird.toSupabase());
```

## Repository Pattern
- `BaseRepository` + `SyncableRepository` mixin
- 23 entity repositories + base + `sync_metadata_repository`
- Repositories orchestrate local <-> remote sync
- UI never calls `client.from()` directly (exception: admin/)

### Sync Strategy
- Offline-first: local Drift DB is source of truth for UI
- Background sync: repositories push local changes to Supabase when online
- Conflict resolution: server wins (last-write-wins with `updated_at` timestamp)
- `SyncMetadata` table tracks per-entity sync state (last sync time, dirty flag)
- Use `ref.invalidate()` after sync completes to refresh UI providers

## Cache
- `community_profile_cache`, `community_post_cache` in remote/api/
- Preferences via `SharedPreferences` wrapper (`AppPreferences`)
- Cache invalidation: manual via `ref.invalidate()` or TTL-based for remote caches

> **Related**: architecture.md (layers), providers.md (repository providers), error-handling.md (DB exceptions)
