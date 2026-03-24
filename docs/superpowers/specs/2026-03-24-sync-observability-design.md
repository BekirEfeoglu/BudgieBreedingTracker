# Sync Observability & Conflict Persistence Design

**Date:** 2026-03-24
**Status:** Approved
**Approach:** B — Separate conflict_history table + enriched error tracking

## Problem Statement

The sync system works reliably but lacks observability for end users:
1. Sync errors are tracked as a boolean — no per-table breakdown
2. Conflict history lives only in memory (FIFO max 50, lost on restart)
3. ValidatedSyncMixin retry behavior (10 vs 5) is undocumented
4. Users see "sync error" but cannot diagnose which data failed

## Scope

| Item | Type | Description |
|------|------|-------------|
| #1 | Provider | `syncErrorDetailsProvider` — table-level error aggregation |
| #2 | Data Layer | `conflict_history` Drift table — persistent conflict log |
| #3 | Documentation | ValidatedSyncMixin retry behavior clarification |
| #4 | UX | Specific sync error display in UI widgets |

**Out of scope:** #5 Genetics lazy-load (already optimal — services load on-demand via routing).

## Design

### 1. Data Layer: `conflict_history` Table

#### 1.1 Drift Table

**File:** `lib/data/local/database/tables/conflict_history_table.dart`

```dart
@DataClassName('ConflictHistoryRow')
class ConflictHistoryTable extends Table {
  TextColumn get id => text()();                          // UUID v4
  TextColumn get userId => text()();                      // User scope
  // NOTE: Column named `tableName_` with `.named('table_name')` to avoid
  // collision with Drift's built-in `String get tableName` override.
  // Same pattern as SyncMetadataTable (line 7).
  TextColumn get tableName_ => text().named('table_name')(); // Affected table (e.g., "eggs")
  TextColumn get recordId => text()();                    // Conflicting record ID
  TextColumn get description => text()();                 // Human-readable (e.g., "Yumurta #3")
  TextColumn get conflictType => text().map(conflictTypeConverter)(); // Enum
  DateTimeColumn get resolvedAt => dateTime().nullable()(); // Resolution time
  DateTimeColumn get createdAt => dateTime().nullable()();  // Detection time

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'conflict_history';
}
```

**Pattern:** Local-only entity (like GeneticsHistory) — no remote source, no repository, no SyncOrchestrator registration. Providers access DAO directly.

**Hard delete by design:** Unlike most entities, ConflictHistory uses hard deletes for cleanup (`deleteOlderThan`, `deleteAll`). This is intentional — conflict records are insert-only audit entries with TTL-based retention (30 days), not user-editable data requiring soft-delete recovery. No `isDeleted`/`updatedAt` columns needed.

#### 1.2 Enum

**File:** `lib/core/enums/sync_enums.dart`

**ConflictType** — Dart 3 enhanced enum with `toJson()`/`fromJson()`:
```dart
enum ConflictType {
  serverWins,        // Remote data overwrote local (standard server-wins)
  localOverwritten,  // Local changes lost during reconciliation
  orphanDeleted,     // Local record deleted (not on server, no pending metadata)
  unknown;           // Fallback for safe deserialization

  String toJson() => name;

  static ConflictType fromJson(String json) {
    return ConflictType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => ConflictType.unknown,
    );
  }
}
```

**Drift converter** added to `lib/data/local/database/converters/enum_converters.dart`:
```dart
final conflictTypeConverter = TypeConverter.extensionType<ConflictType, String>(
  mapToDart: (dbValue) => ConflictType.fromJson(dbValue),
  mapToSql: (dartValue) => dartValue.toJson(),
);
```

#### 1.3 Freezed Model

**File:** `lib/data/models/conflict_history_model.dart`

```dart
part 'conflict_history_model.freezed.dart';
part 'conflict_history_model.g.dart';

@freezed
abstract class ConflictHistory with _$ConflictHistory {
  const ConflictHistory._();
  const factory ConflictHistory({
    required String id,
    required String userId,
    required String tableName,
    required String recordId,
    required String description,
    @JsonKey(unknownEnumValue: ConflictType.unknown) required ConflictType conflictType,
    DateTime? resolvedAt,
    DateTime? createdAt,
  }) = _ConflictHistory;
  factory ConflictHistory.fromJson(Map<String, dynamic> json) => _$ConflictHistoryFromJson(json);
}
```

#### 1.4 Mapper

**File:** `lib/data/local/database/mappers/conflict_history_mapper.dart`

Standard pattern:
- `ConflictHistoryRow.toModel()` extension
- `ConflictHistory.toCompanion()` extension with `updatedAt` not needed (no updates, insert-only)

#### 1.5 DAO

**File:** `lib/data/local/database/daos/conflict_history_dao.dart`

**Import:** Table imported DIRECTLY (`import 'tables/conflict_history_table.dart'`), NOT via `app_database.dart`. Follows `@DriftAccessor(tables: [ConflictHistoryTable])` annotation pattern.

Methods:
- `watchAll(userId)` → `Stream<List<ConflictHistory>>` (last 100, ordered by createdAt DESC)
- `watchRecentCount(userId, Duration since)` → `Stream<int>` (count in last 24h)
- `insert(ConflictHistory)` → Single insert
- `deleteOlderThan(int days)` → Hard delete cleanup (TTL-based, not soft delete)
- `deleteAll(userId)` → User-triggered hard delete cleanup

All queries scoped by `userId`.

#### 1.6 Migration: Schema v15 → v16

In `app_database.dart`:
- Increment `schemaVersion` to 16
- Add `case 16: await _migrateV15ToV16(m)`
- Helper creates table + composite index on `(userId, createdAt)`

#### 1.7 Registration

- Add `ConflictHistoryTable` to `@DriftDatabase(tables: [...])`
- Add `ConflictHistoryDao` to `@DriftDatabase(daos: [...])`
- Add `conflictHistoryDaoProvider` to `dao_providers.dart`
- **NO** remote source, repository, or SyncOrchestrator entry

---

### 2. Sync Provider Improvements

#### 2.1 `syncErrorDetailsProvider`

**File:** Added to `sync_providers.dart`

```dart
final syncErrorDetailsProvider = StreamProvider.family<List<SyncErrorDetail>, String>((ref, userId) {
  final syncDao = ref.watch(syncMetadataDaoProvider);
  return syncDao.watchErrorsByTable(userId);
});
```

**SyncErrorDetail** — simple class defined in `sync_providers.dart` (internal to domain layer, consumed by features via provider):
```dart
class SyncErrorDetail {
  final String tableName;
  final int errorCount;
  final String? lastError;
  final DateTime? lastAttempt;
  const SyncErrorDetail({
    required this.tableName,
    required this.errorCount,
    this.lastError,
    this.lastAttempt,
  });
}
```

**New DAO query** in `sync_metadata_dao.dart`:
- `watchErrorsByTable(userId)` → `SELECT table_name, COUNT(*), MAX(error_message), MAX(updated_at) FROM sync_metadata WHERE user_id = ? AND status = 'error' GROUP BY table_name`

#### 2.2 Conflict Persist Integration

**In `SyncPullHandler._reportPullConflicts()`:**

Current behavior (preserved):
- Adds conflicts to in-memory `conflictHistoryProvider` (FIFO max 50)

New behavior (added):
- Also calls `ConflictHistoryDao.insert()` for each detected conflict
- Creates `ConflictHistory` with `conflictType: ConflictType.serverWins`

**In `SyncOrchestrator` cleanup phase:**

After each full sync:
- `ConflictHistoryDao.deleteOlderThan(30)` — 30-day retention policy

#### 2.3 Startup Restore

**In `conflictHistoryProvider` initialization:**

Current: starts empty (`[]`)

New: on build, loads last 50 records from `ConflictHistoryDao.watchAll(userId)` to restore session state. In-memory provider stays reactive for current-session additions.

#### 2.4 New Providers

| Provider | Type | Source |
|----------|------|--------|
| `syncErrorDetailsProvider` | `StreamProvider.family<List<SyncErrorDetail>, String>` | SyncMetadataDao |
| `pendingByTableProvider` | `StreamProvider.family<List<SyncErrorDetail>, String>` | SyncMetadataDao |
| `persistedConflictCountProvider` | `StreamProvider.family<int, String>` | ConflictHistoryDao |

**No breaking changes** to existing providers. `syncErrorProvider` (boolean), `syncStatusProvider` (derived), `pendingSyncCountProvider` (count) all unchanged.

---

### 3. UX: Sync Error Detail UI

#### 3.1 `SyncStatusTile` Enhancement (Profile Screen)

**File:** `lib/features/profile/widgets/sync_status_tile.dart`

Changes:
- When `syncErrorProvider` is true, watch `syncErrorDetailsProvider`
- Replace generic "Senkronizasyon hatasi" with specific message:
  - 1 table: `"2 yumurta kaydı senkronize edilemedi"`
  - Multiple tables: `"3 kayıt senkronize edilemedi (yumurta, kuş)"`
- Add onTap → opens `SyncDetailSheet`

#### 3.2 New Widget: `SyncDetailSheet`

**File:** `lib/features/settings/widgets/sync_detail_sheet.dart`

Bottom sheet with 3 sections:

**Section 1: Pending Records**
- Table-grouped list of pending sync records
- Each row: table icon (AppIcon) + localized table name + pending count
- Source: new `pendingByTableProvider` — `StreamProvider.family` wrapping `SyncMetadataDao.watchPendingByTable(userId)` (new DAO query: `SELECT table_name, COUNT(*) FROM sync_metadata WHERE user_id = ? AND status = 'pending' GROUP BY table_name`)

**Section 2: Failed Records**
- Table-grouped list from `syncErrorDetailsProvider`
- Each row: table icon + localized table name + error count + last error message (truncated)
- Color: error theme color

**Section 3: Conflict History**
- List from persisted `ConflictHistoryDao.watchAll()`
- Each row: table icon + record description + relative time + conflict type badge
- "Gecmisi Temizle" action button

**Actions:**
- "Simdi Senkronize Et" — triggers `orchestrator.forceFullSync()`
- "Gecmisi Temizle" — clears conflict_history table

**300-line rule:** If `SyncDetailSheet` exceeds 300 lines, split sections into private sub-widgets (`_PendingSection`, `_FailedSection`, `_ConflictSection`) using `part` directive or extract to separate files.

#### 3.3 `SyncStatusBar` Enhancement (Home Screen)

**File:** `lib/features/home/widgets/sync_status_bar.dart`

Changes:
- Error state text: `"Senkronizasyon hatasi"` → `"{n} kayit senkronize edilemedi"` (from error details count)
- Tap behavior: opens `SyncDetailSheet` instead of just triggering manual sync
- Synced state tap: unchanged (no-op or manual sync)

#### 3.4 Localization Keys

~15 new keys added to all 3 language files (tr/en/de):

```
sync.error_details_title — "Senkronizasyon Detaylari"
sync.pending_section — "Bekleyen Kayitlar"
sync.failed_section — "Basarisiz Kayitlar"
sync.conflict_section — "Cakisma Gecmisi"
sync.error_count_summary — "{} kayit senkronize edilemedi"
sync.error_table_summary — "{} {} kaydı basarisiz"
sync.table_birds — "Kus"
sync.table_eggs — "Yumurta"
sync.table_chicks — "Yavru"
sync.table_breeding_pairs — "Ureme Cifti"
sync.table_clutches — "Kulucka"
sync.table_nests — "Yuva"
sync.table_health_records — "Saglik Kaydi"
sync.table_events — "Etkinlik"
sync.table_other — "Diger"
sync.conflict_server_wins — "Sunucu verisi korundu"
sync.conflict_orphan_deleted — "Yerel kayit silindi"
sync.clear_conflict_history — "Gecmisi Temizle"
sync.no_errors — "Tum veriler senkronize"
sync.no_conflicts — "Cakisma gecmisi bos"
sync.sync_now_action — "Simdi Senkronize Et"
```

---

### 4. Documentation Updates

#### 4.1 `.claude/rules/database.md`

Add to "Repository Pattern" section:

**ValidatedSyncMixin:**
- Used by: Egg, Chick, EventReminder repositories
- Max retries: 10 (vs standard 5)
- Behavior: Before push, validates FK references exist locally AND are not pending sync
- On FK failure: Marks as sync error (not deleted), kept for retry
- Stale cleanup: Records with retryCount >= 10 AND older than 24h auto-deleted

#### 4.2 `.claude/rules/supabase_rules.md`

Update "Repository Variants" table:

| Pattern | Use Case | Max Retry |
|---------|----------|-----------|
| `BaseRepository + SyncableRepository` | Bird, Nest, Event, Notification, etc. | 5 |
| `+ ValidatedSyncMixin` | Egg, Chick, EventReminder (FK deps) | 10 |
| `ProfileRepository` (custom) | Single-record, push-before-pull | 5 |
| `SyncMetadataRepository` | Local-only (no remote) | N/A |
| DAO directly | GeneticsHistory, ConflictHistory (no remote, no repo) | N/A |

#### 4.3 `CLAUDE.md` Quick Reference

Add to Sync Architecture section:
- `ValidatedSyncMixin` entities: Egg, Chick, EventReminder (10 retries, FK validation before push)
- `ConflictHistory`: local-only entity (Drift table + DAO + mapper, no remote/repo)

Update Codebase Stats:
- Drift tables: 19 → 20
- DAOs: 19 → 20
- Mappers: 19 → 20
- Schema version: 15 → 16

---

## Files Changed Summary

| Category | File | Action |
|----------|------|--------|
| **New files (7)** | | |
| Model | `lib/data/models/conflict_history_model.dart` | Create |
| Table | `lib/data/local/database/tables/conflict_history_table.dart` | Create |
| DAO | `lib/data/local/database/daos/conflict_history_dao.dart` | Create |
| Mapper | `lib/data/local/database/mappers/conflict_history_mapper.dart` | Create |
| Enum | `lib/core/enums/sync_enums.dart` (ConflictType) | Create |
| Widget | `lib/features/settings/widgets/sync_detail_sheet.dart` | Create |
| Converter | `lib/data/local/database/converters/enum_converters.dart` | Add `conflictTypeConverter` |
| **Modified files (~12)** | | |
| Database | `lib/data/local/database/app_database.dart` | Add table/DAO, migration v16 |
| Providers | `lib/data/local/database/daos/dao_providers.dart` | Add conflictHistoryDaoProvider |
| Sync DAO | `lib/data/local/database/daos/sync_metadata_dao.dart` | Add watchErrorsByTable query |
| Sync Providers | `lib/domain/services/sync/sync_providers.dart` | Add syncErrorDetailsProvider, update conflictHistoryProvider |
| Pull Handler | `lib/domain/services/sync/sync_pull_handler.dart` | Persist conflicts to DAO |
| Orchestrator | `lib/domain/services/sync/sync_orchestrator.dart` | Add conflict cleanup call |
| Status Tile | `lib/features/profile/widgets/sync_status_tile.dart` | Enhanced error display |
| Status Bar | `lib/features/home/widgets/sync_status_bar.dart` | Enhanced error text + tap |
| L10n TR | `assets/translations/tr.json` | ~15 new keys |
| L10n EN | `assets/translations/en.json` | ~15 new keys |
| L10n DE | `assets/translations/de.json` | ~15 new keys |
| **Documentation (4)** | | |
| Rules | `.claude/rules/database.md` | ValidatedSyncMixin section |
| Rules | `.claude/rules/supabase_rules.md` | Repository variants table |
| Rules | `.claude/rules/CLAUDE.md` | Stats + sync quick ref |
| Rules | `CLAUDE.md` (root) | Stats update |

**Total: ~7 new + ~12 modified + ~4 docs = ~23 files**

## Testing Strategy

- Unit test: `ConflictHistoryDao` CRUD operations
- Unit test: `SyncMetadataDao.watchErrorsByTable()` aggregation
- Widget test: `SyncDetailSheet` displays error/conflict data correctly
- Widget test: `SyncStatusTile` shows table-specific error messages
- Widget test: `SyncStatusBar` shows error count summary
- Integration: Conflict persistence survives app restart (DAO read after insert)

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Migration failure on existing installs | Standard for-loop + switch pattern, `createTable` is safe |
| Disk growth from conflict history | 30-day auto-cleanup + user manual clear |
| Performance of GROUP BY query | Existing composite index on sync_metadata (userId+status) covers it |
| Breaking existing sync flow | All changes are additive — no existing provider/method signatures change |
