# Data Layer

## Drift (Local Database)
- **Tables**: `lib/data/local/database/tables/` (20 tables)
- **DAOs**: `lib/data/local/database/daos/` (20 DAOs)
- **Mappers**: `lib/data/local/database/mappers/` (20 mappers)
- **Converters**: `lib/data/local/database/converters/enum_converters.dart`
- **Schema version**: 29
- Import tables DIRECTLY from table file, not via `app_database.dart`
- Use `.equalsValue()` for enum columns, not `.equals()`
- NEVER close a `.references()` cycle between two tables (A↔B çift yönlü typed FK): tablo dosyaları birbirini import eder ve drift_dev "Circular error when deserializing drift modules" WARNING'leri üretir (non-fatal — simolus3/drift#3227). Child→parent ana FK `.references()` kalır; GERİ-referansı raw `.customConstraint('NULL REFERENCES <table> (id)')` ile bildir ve import'u kaldır — üretilen SQL FK birebir aynıdır, schema değişmez. Kanonik örnek: `incubations.clutchId` ↔ `clutches.incubationId` (2026-07-09). Detay: obsidian-brain/data-layer/drift.md § Circular FK References

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
- **Remote sources**: `lib/data/remote/api/` (27 entity + base + 2 caches + providers)
- **Storage**: `lib/data/remote/storage/storage_service.dart`
- **Constants**: `SupabaseConstants` class (192 table/column constants)
- **Edge Functions**: 12 in `supabase/functions/`
- **Migrations**: 217 SQL files in `supabase/migrations/`
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

### Offline-First Classification (mandatory)
A class named `*Repository` MUST be offline-first unless it is a documented
cross-user, fresh-data exception:
- Has Drift table + DAO
- Has `SyncMetadata` entry
- Writes go local-first, then `.upsert()` (never raw `.insert()`) to remote
- Reads return local streams, not remote futures

An ordinary online-only class with no cross-user repository semantics must use
`*RemoteService` or `*OnlineSource`. Cross-user exceptions must explain the
absence of a Drift mirror in their class doc and remain behind the repository
boundary so feature code never imports remote sources directly.

Current exceptions: `CommunityPostRepository`, `CommunityCommentRepository`,
`CommunitySocialRepository`, `MessagingRepository`, `MarketplaceRepository`,
and `GamificationRepository` (see architecture.md § Online-First Exemption).
Each wraps remote sources behind a repository boundary; feature code must not
import those sources directly.

### Sync Strategy
- Offline-first: local Drift DB is source of truth for UI
- Background sync: repositories push local changes to Supabase when online
- `SyncMetadata` tracks one row per pending record (`table_name`, `record_id`,
  status/error/retry timestamps); successful push deletes the row
- Drift streams refresh UI reactively; invalidate only derived/FutureProvider
  snapshots that do not observe the changed DAO stream
- Syncable repos with FK parents MUST use `ValidatedSyncMixin`. Current
  coverage: breeding_pair, clutch, incubation, egg, chick, health_record,
  event, event_reminder, growth_measurement. Bird is a root entity and does not
  require the mixin.

### Write Safety
- Syncable entity replay paths ALWAYS use `.upsert()` for idempotency — raw
  `.insert()` causes duplicates on retry/sync replay
- Use stable client-generated UUIDs as primary keys, not server-assigned IDs. **Prefer `const Uuid().v7()`** — time-orderable, better B-tree index locality, easier debugging. `Uuid().v4()` remains acceptable for non-entity identifiers (transient request tokens, etc.) but new entity creation paths should use v7 for consistency with the rest of the codebase.
- Batch writes in Drift transactions; batch remote writes where API supports

```dart
// CORRECT - idempotent, retry-safe
await client
    .from(SupabaseConstants.birdsTable)
    .upsert(bird.toSupabase(), onConflict: 'id');

// WRONG - duplicates on retry, sync replay breaks
await client.from(SupabaseConstants.birdsTable).insert(bird.toSupabase());
```

Drift toplu yazimda `batch`:
```dart
await db.batch((batch) {
  batch.insertAll(birdsTable, birds.map((b) => b.toCompanion()).toList(),
    mode: InsertMode.insertOrReplace);
});
```

### Conflict Resolution
- Pull is server-wins; any incoming overwrite of a locally pending row is a
  conflict regardless of timestamp order
- Discarded local edits MUST NOT be silent: shared `detectPullConflicts` →
  `lastPullConflicts` → `conflict_history` + providers/banner/detail sheet
- Local/server snapshots MUST be authenticated-encrypted and persisted before
  the remote row overwrites Drift. Snapshot failure aborts that repository pull.
- One recoverable unresolved snapshot is kept per `(user, table, record)`;
  repeated pulls preserve the oldest local payload and must not append a later
  server-wins copy. In-memory conflict state follows the same unresolved-key
  deduplication; resolved history does not suppress a new conflict.
- "Retry local" MUST decode/validate the versioned snapshot, restore the typed
  model through its DAO, reset the existing metadata through
  `markPendingByRecords`, and resolve history in one Drift transaction. Exactly
  one pending metadata row must remain. Payload-less v28 history and
  corrupt/unsupported payloads remain unresolved and must surface a localized
  fallback without mutating entity data.
- A retry is UI-successful only when `fullSync` succeeds and batched
  `getByRecords` checks find no metadata for every restored `(table, record)`
  key. Remaining metadata is a partial/unverified result; reload conflict state
  after the sync attempt and keep the detail sheet open.
- Conflict payloads are capped at 64 KiB per snapshot, retained with history for
  30 days, and never included in logs, Sentry events, or telemetry.
- Never overwrite local dirty rows without conflict accounting

## Cache
- `community_profile_cache`, `community_post_cache` in remote/api/
- Preferences via `SharedPreferences` wrapper (`AppPreferences`)
- Cache invalidation: manual via `ref.invalidate()` or TTL-based for remote caches

> **Related**: architecture.md (layers), providers.md (repository providers), error-handling.md (DB exceptions)
