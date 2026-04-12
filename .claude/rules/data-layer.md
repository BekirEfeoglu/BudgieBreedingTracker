# Data Layer

## Drift (Local Database)
- **Tables**: `lib/data/local/database/tables/` (22 tables)
- **DAOs**: `lib/data/local/database/daos/` (22 DAOs)
- **Mappers**: `lib/data/local/database/mappers/` (22 mappers)
- **Converters**: `lib/data/local/database/converters/enum_converters.dart`
- **Schema version**: 20
- Import tables DIRECTLY from table file, not via `app_database.dart`
- Use `.equalsValue()` for enum columns, not `.equals()`

## Supabase (Remote)
- **Remote sources**: `lib/data/remote/api/` (26 entity + 2 caches)
- **Storage**: `lib/data/remote/storage/storage_service.dart`
- **Constants**: `SupabaseConstants` class (106 table/column constants)
- **Edge Functions**: 6 in `supabase/functions/`
- **Migrations**: 115 SQL files in `supabase/migrations/`
- Always use `SupabaseConstants` for table/column names — never hardcode
- Use `.toSupabase()` extension — never send `created_at`/`updated_at` manually

## Repository Pattern
- `BaseRepository` + `SyncableRepository` mixin
- 23 entity repositories + `sync_metadata_repository`
- Repositories orchestrate local ↔ remote sync
- UI never calls `client.from()` directly (exception: admin/)

## Cache
- `community_profile_cache`, `community_post_cache` in remote/api/
- Preferences via `SharedPreferences` wrapper (`AppPreferences`)
