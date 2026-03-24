# Sync Observability & Conflict Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add table-level sync error tracking, persistent conflict history, enhanced sync error UX, and ValidatedSyncMixin documentation.

**Architecture:** New local-only `conflict_history` Drift entity (table+DAO+mapper+model) following GeneticsHistory pattern. New providers aggregate errors by table from existing `sync_metadata`. UI widgets enhanced to show specific error details. All changes are additive — no existing APIs break.

**Tech Stack:** Flutter/Dart, Drift 2.31+, Riverpod 3, Freezed 3, easy_localization

**Spec:** `docs/superpowers/specs/2026-03-24-sync-observability-design.md`

---

## File Map

| Action | File | Responsibility |
|--------|------|---------------|
| Create | `lib/core/enums/sync_enums.dart` | ConflictType enum with toJson/fromJson |
| Create | `lib/data/models/conflict_history_model.dart` | Freezed ConflictHistory model |
| Create | `lib/data/local/database/tables/conflict_history_table.dart` | Drift table definition |
| Create | `lib/data/local/database/mappers/conflict_history_mapper.dart` | Row↔Model mapping extensions |
| Create | `lib/data/local/database/daos/conflict_history_dao.dart` | DAO with watchAll, insert, cleanup |
| Create | `lib/features/settings/widgets/sync_detail_sheet.dart` | Bottom sheet with 3 sections |
| Modify | `lib/data/local/database/converters/enum_converters.dart` | Add conflictTypeConverter |
| Modify | `lib/data/local/database/app_database.dart` | Register table+DAO, schema v16 |
| Modify | `lib/data/local/database/app_database_migrations.dart` | Add _migrateV15ToV16 |
| Modify | `lib/data/local/database/dao_providers.dart` | Add conflictHistoryDaoProvider |
| Modify | `lib/data/local/database/daos/sync_metadata_dao.dart` | Add watchErrorsByTable, watchPendingByTable |
| Modify | `lib/domain/services/sync/sync_providers.dart` | Add syncErrorDetailsProvider, pendingByTableProvider, update conflictHistoryProvider |
| Modify | `lib/domain/services/sync/sync_pull_handler.dart` | Persist conflicts to DAO |
| Modify | `lib/domain/services/sync/sync_orchestrator.dart` | Add conflict cleanup |
| Modify | `lib/features/profile/widgets/sync_status_tile.dart` | Table-specific error display + tap to sheet |
| Modify | `lib/features/home/widgets/sync_status_bar.dart` | Error count in text + tap to sheet |
| Modify | `assets/translations/tr.json` | ~20 new keys |
| Modify | `assets/translations/en.json` | ~20 new keys |
| Modify | `assets/translations/de.json` | ~20 new keys |
| Modify | `.claude/rules/database.md` | ValidatedSyncMixin docs |
| Modify | `.claude/rules/supabase_rules.md` | Repository variants table |
| Modify | `.claude/rules/CLAUDE.md` | Stats + sync quick ref |
| Modify | `CLAUDE.md` (root) | Stats update |

---

## Task 1: ConflictType Enum + Converter

**Files:**
- Create: `lib/core/enums/sync_enums.dart`
- Modify: `lib/data/local/database/converters/enum_converters.dart`
- Test: `test/core/enums/sync_enums_test.dart`

- [ ] **Step 1: Write enum test**

```dart
// test/core/enums/sync_enums_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';

void main() {
  group('ConflictType', () {
    test('toJson returns enum name', () {
      expect(ConflictType.serverWins.toJson(), 'serverWins');
      expect(ConflictType.orphanDeleted.toJson(), 'orphanDeleted');
    });

    test('fromJson returns correct value', () {
      expect(ConflictType.fromJson('serverWins'), ConflictType.serverWins);
      expect(ConflictType.fromJson('orphanDeleted'), ConflictType.orphanDeleted);
    });

    test('fromJson returns unknown for invalid value', () {
      expect(ConflictType.fromJson('invalid'), ConflictType.unknown);
      expect(ConflictType.fromJson(''), ConflictType.unknown);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/enums/sync_enums_test.dart`
Expected: FAIL — file not found

- [ ] **Step 3: Create enum file**

```dart
// lib/core/enums/sync_enums.dart

/// Type of sync conflict detected during pull operations.
enum ConflictType {
  /// Remote data overwrote local (standard server-wins).
  serverWins,

  /// Local changes lost during full reconciliation.
  localOverwritten,

  /// Local record deleted (not on server, no pending metadata).
  orphanDeleted,

  /// Fallback for safe deserialization.
  unknown;

  String toJson() => name;

  static ConflictType fromJson(String json) {
    return ConflictType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => ConflictType.unknown,
    );
  }
}
```

- [ ] **Step 4: Add converter to enum_converters.dart**

Add import `import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';` and at the end:

```dart
// Conflict enums
const conflictTypeConverter = EnumConverter<ConflictType>(
  ConflictType.values,
  ConflictType.unknown,
);
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/enums/sync_enums_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/core/enums/sync_enums.dart lib/data/local/database/converters/enum_converters.dart test/core/enums/sync_enums_test.dart
git commit -m "feat(sync): add ConflictType enum and Drift converter"
```

---

## Task 2: Freezed Model + Table + Mapper

**Files:**
- Create: `lib/data/models/conflict_history_model.dart`
- Create: `lib/data/local/database/tables/conflict_history_table.dart`
- Create: `lib/data/local/database/mappers/conflict_history_mapper.dart`

- [ ] **Step 1: Create Freezed model**

```dart
// lib/data/models/conflict_history_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';

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
    @JsonKey(unknownEnumValue: ConflictType.unknown)
    required ConflictType conflictType,
    DateTime? resolvedAt,
    DateTime? createdAt,
  }) = _ConflictHistory;

  factory ConflictHistory.fromJson(Map<String, dynamic> json) =>
      _$ConflictHistoryFromJson(json);
}
```

- [ ] **Step 2: Create Drift table**

```dart
// lib/data/local/database/tables/conflict_history_table.dart
import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';

@DataClassName('ConflictHistoryRow')
class ConflictHistoryTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  // Named to avoid collision with Drift's tableName getter (same pattern as SyncMetadataTable).
  TextColumn get tableName_ => text().named('table_name')();
  TextColumn get recordId => text()();
  TextColumn get description => text()();
  TextColumn get conflictType => text().map(conflictTypeConverter)();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'conflict_history';
}
```

- [ ] **Step 3: Create mapper**

Reference pattern: `lib/data/local/database/mappers/sync_metadata_mapper.dart` (uses `tableName_` → model field mapping).

```dart
// lib/data/local/database/mappers/conflict_history_mapper.dart
import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/conflict_history_model.dart';

extension ConflictHistoryRowMapper on ConflictHistoryRow {
  ConflictHistory toModel() => ConflictHistory(
    id: id,
    userId: userId,
    tableName: tableName_,
    recordId: recordId,
    description: description,
    conflictType: conflictType,
    resolvedAt: resolvedAt,
    createdAt: createdAt,
  );
}

extension ConflictHistoryModelMapper on ConflictHistory {
  ConflictHistoryTableCompanion toCompanion() => ConflictHistoryTableCompanion(
    id: Value(id),
    userId: Value(userId),
    tableName_: Value(tableName),
    recordId: Value(recordId),
    description: Value(description),
    conflictType: Value(conflictType),
    resolvedAt: Value(resolvedAt),
    createdAt: Value(createdAt ?? DateTime.now()),
  );
}
```

- [ ] **Step 4: Commit model + table (mapper will compile after Task 3 registers table in DB)**

Note: The mapper imports `app_database.dart` which references generated types from the table registration. The mapper will only compile after Task 3 registers `ConflictHistoryTable` in `@DriftDatabase` and runs `build_runner`. Commit model and table now; mapper is committed together with Task 3.

```bash
git add lib/data/models/conflict_history_model.dart lib/data/local/database/tables/conflict_history_table.dart lib/data/local/database/mappers/conflict_history_mapper.dart
git commit -m "feat(sync): add ConflictHistory model, table, and mapper"
```

---

## Task 3: DAO + Database Registration + Migration + Code Generation

**Files:**
- Create: `lib/data/local/database/daos/conflict_history_dao.dart`
- Modify: `lib/data/local/database/app_database.dart`
- Modify: `lib/data/local/database/app_database_migrations.dart`
- Modify: `lib/data/local/database/dao_providers.dart`
- Test: `test/data/local/database/daos/conflict_history_dao_test.dart`

- [ ] **Step 1: Write DAO test**

```dart
// test/data/local/database/daos/conflict_history_dao_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/conflict_history_model.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  group('ConflictHistoryDao', () {
    final conflict = ConflictHistory(
      id: 'c1',
      userId: 'u1',
      tableName: 'eggs',
      recordId: 'e1',
      description: 'Egg #3',
      conflictType: ConflictType.serverWins,
      createdAt: DateTime.now(),
    );

    test('insert and watchAll returns conflict', () async {
      await db.conflictHistoryDao.insert(conflict);
      final results = await db.conflictHistoryDao.watchAll('u1').first;
      expect(results, hasLength(1));
      expect(results.first.tableName, 'eggs');
      expect(results.first.conflictType, ConflictType.serverWins);
    });

    test('watchAll is user-scoped', () async {
      await db.conflictHistoryDao.insert(conflict);
      final results = await db.conflictHistoryDao.watchAll('other').first;
      expect(results, isEmpty);
    });

    test('deleteAll removes all for user', () async {
      await db.conflictHistoryDao.insert(conflict);
      await db.conflictHistoryDao.deleteAll('u1');
      final results = await db.conflictHistoryDao.watchAll('u1').first;
      expect(results, isEmpty);
    });

    test('deleteOlderThan removes old records', () async {
      final old = conflict.copyWith(
        id: 'c-old',
        createdAt: DateTime.now().subtract(const Duration(days: 31)),
      );
      await db.conflictHistoryDao.insert(old);
      await db.conflictHistoryDao.insert(conflict);
      await db.conflictHistoryDao.deleteOlderThan(30);
      final results = await db.conflictHistoryDao.watchAll('u1').first;
      expect(results, hasLength(1));
      expect(results.first.id, 'c1');
    });

    test('watchRecentCount returns count within duration', () async {
      await db.conflictHistoryDao.insert(conflict);
      final count = await db.conflictHistoryDao
          .watchRecentCount('u1', const Duration(hours: 24))
          .first;
      expect(count, 1);
    });
  });
}
```

- [ ] **Step 2: Create DAO file**

```dart
// lib/data/local/database/daos/conflict_history_dao.dart
import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/conflict_history_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/conflict_history_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/conflict_history_model.dart';

part 'conflict_history_dao.g.dart';

@DriftAccessor(tables: [ConflictHistoryTable])
class ConflictHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$ConflictHistoryDaoMixin {
  ConflictHistoryDao(super.db);

  /// Watch last 100 conflict records for a user, newest first.
  Stream<List<ConflictHistory>> watchAll(String userId) {
    return (select(conflictHistoryTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(100))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  /// Watch count of conflicts within [since] duration for a user.
  Stream<int> watchRecentCount(String userId, Duration since) {
    final cutoff = DateTime.now().subtract(since);
    final count = conflictHistoryTable.id.count();
    return (selectOnly(conflictHistoryTable)
          ..addColumns([count])
          ..where(
            conflictHistoryTable.userId.equals(userId) &
                conflictHistoryTable.createdAt.isBiggerOrEqualValue(cutoff),
          ))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  /// Insert a new conflict record.
  Future<void> insert(ConflictHistory conflict) {
    return into(conflictHistoryTable)
        .insertOnConflictUpdate(conflict.toCompanion());
  }

  /// Hard delete records older than [days].
  Future<int> deleteOlderThan(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return (delete(conflictHistoryTable)
          ..where((t) => t.createdAt.isSmallerOrEqualValue(cutoff)))
        .go();
  }

  /// Hard delete all records for a user.
  Future<int> deleteAll(String userId) {
    return (delete(conflictHistoryTable)
          ..where((t) => t.userId.equals(userId)))
        .go();
  }
}
```

- [ ] **Step 3: Register in app_database.dart**

In `app_database.dart`:
- Add import: `import 'package:budgie_breeding_tracker/data/local/database/tables/conflict_history_table.dart';`
- Add import: `import 'package:budgie_breeding_tracker/data/local/database/daos/conflict_history_dao.dart';`
- Add `ConflictHistoryTable,` to the `tables:` list (after `GeneticsHistoryTable`)
- Add `ConflictHistoryDao,` to the `daos:` list (after `GeneticsHistoryDao`)
- Change `schemaVersion => 15` to `schemaVersion => 16`
- Add migration case: `case 16: await _migrateV15ToV16(this, m);`

- [ ] **Step 4: Add migration helper**

In `app_database_migrations.dart`, add at the end:

```dart
Future<void> _migrateV15ToV16(AppDatabase db, Migrator m) async {
  await m.createTable(db.conflictHistoryTable);
  await db.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_conflict_history_user_created '
    'ON conflict_history (user_id, created_at)',
  );
}
```

- [ ] **Step 5: Add DAO provider**

In `dao_providers.dart`:
- Add import: `import 'package:budgie_breeding_tracker/data/local/database/daos/conflict_history_dao.dart';`
- Add at the end:

```dart
final conflictHistoryDaoProvider = Provider<ConflictHistoryDao>((ref) {
  return ref.watch(appDatabaseProvider).conflictHistoryDao;
});
```

- [ ] **Step 6: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `conflict_history_dao.g.dart`, `app_database.g.dart` updated.

- [ ] **Step 7: Run DAO test**

Run: `flutter test test/data/local/database/daos/conflict_history_dao_test.dart`
Expected: ALL PASS

- [ ] **Step 8: Commit**

```bash
git add lib/data/local/database/daos/conflict_history_dao.dart lib/data/local/database/app_database.dart lib/data/local/database/app_database_migrations.dart lib/data/local/database/dao_providers.dart test/data/local/database/daos/conflict_history_dao_test.dart
git commit -m "feat(sync): add ConflictHistoryDao, register in database, migrate to v16"
```

---

## Task 4: SyncMetadataDao — New Aggregate Queries

**Files:**
- Modify: `lib/data/local/database/daos/sync_metadata_dao.dart`
- Test: `test/data/local/database/daos/sync_metadata_dao_aggregate_test.dart`

- [ ] **Step 1: Write test for watchErrorsByTable**

```dart
// test/data/local/database/daos/sync_metadata_dao_aggregate_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  SyncMetadata _makeError(String id, String table) => SyncMetadata(
    id: id,
    table: table,
    userId: 'u1',
    status: SyncStatus.error,
    recordId: 'r-$id',
    errorMessage: 'Network timeout',
    retryCount: 1,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  SyncMetadata _makePending(String id, String table) => SyncMetadata(
    id: id,
    table: table,
    userId: 'u1',
    status: SyncStatus.pending,
    recordId: 'r-$id',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('watchErrorsByTable', () {
    test('groups errors by table with count', () async {
      await db.syncMetadataDao.insertItem(_makeError('e1', 'eggs'));
      await db.syncMetadataDao.insertItem(_makeError('e2', 'eggs'));
      await db.syncMetadataDao.insertItem(_makeError('b1', 'birds'));

      final results = await db.syncMetadataDao.watchErrorsByTable('u1').first;
      expect(results, hasLength(2));

      final eggs = results.firstWhere((d) => d.tableName == 'eggs');
      expect(eggs.errorCount, 2);

      final birds = results.firstWhere((d) => d.tableName == 'birds');
      expect(birds.errorCount, 1);
    });
  });

  group('watchPendingByTable', () {
    test('groups pending by table with count', () async {
      await db.syncMetadataDao.insertItem(_makePending('p1', 'eggs'));
      await db.syncMetadataDao.insertItem(_makePending('p2', 'chicks'));
      await db.syncMetadataDao.insertItem(_makePending('p3', 'chicks'));

      final results = await db.syncMetadataDao.watchPendingByTable('u1').first;
      expect(results, hasLength(2));

      final chicks = results.firstWhere((d) => d.tableName == 'chicks');
      expect(chicks.errorCount, 2);
    });
  });
}
```

- [ ] **Step 2: Add SyncErrorDetail class and queries to sync_metadata_dao.dart**

At the top of `sync_metadata_dao.dart` (after imports, before class):

```dart
/// Aggregated sync error/pending detail per table.
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

Add these methods inside `SyncMetadataDao` class:

```dart
  /// Watches error records grouped by table name.
  Stream<List<SyncErrorDetail>> watchErrorsByTable(String userId) {
    final tbl = syncMetadataTable.tableName_;
    final cnt = syncMetadataTable.id.count();
    final lastErr = syncMetadataTable.errorMessage.max();
    final lastTime = syncMetadataTable.updatedAt.max();

    return (selectOnly(syncMetadataTable)
          ..addColumns([tbl, cnt, lastErr, lastTime])
          ..where(
            syncMetadataTable.userId.equals(userId) &
                syncMetadataTable.status.equalsValue(SyncStatus.error),
          )
          ..groupBy([tbl]))
        .watch()
        .map((rows) => rows.map((row) {
              return SyncErrorDetail(
                tableName: row.read(tbl) ?? '',
                errorCount: row.read(cnt) ?? 0,
                lastError: row.read(lastErr),
                lastAttempt: row.read(lastTime),
              );
            }).toList());
  }

  /// Watches pending records grouped by table name.
  Stream<List<SyncErrorDetail>> watchPendingByTable(String userId) {
    final tbl = syncMetadataTable.tableName_;
    final cnt = syncMetadataTable.id.count();

    return (selectOnly(syncMetadataTable)
          ..addColumns([tbl, cnt])
          ..where(
            syncMetadataTable.userId.equals(userId) &
                syncMetadataTable.status.equalsValue(SyncStatus.pending),
          )
          ..groupBy([tbl]))
        .watch()
        .map((rows) => rows.map((row) {
              return SyncErrorDetail(
                tableName: row.read(tbl) ?? '',
                errorCount: row.read(cnt) ?? 0,
              );
            }).toList());
  }
```

- [ ] **Step 3: Run test**

Run: `flutter test test/data/local/database/daos/sync_metadata_dao_aggregate_test.dart`
Expected: ALL PASS

- [ ] **Step 4: Commit**

```bash
git add lib/data/local/database/daos/sync_metadata_dao.dart test/data/local/database/daos/sync_metadata_dao_aggregate_test.dart
git commit -m "feat(sync): add watchErrorsByTable and watchPendingByTable to SyncMetadataDao"
```

---

## Task 5: Sync Provider Enhancements

**Files:**
- Modify: `lib/domain/services/sync/sync_providers.dart`

- [ ] **Step 1: Add new providers**

Add imports at the top of `sync_providers.dart`:
```dart
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart' show SyncErrorDetail;
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart' show conflictHistoryDaoProvider;
```

Note: `syncMetadataDaoProvider` is already imported via existing `dao_providers.dart` import at line 11. The `SyncErrorDetail` class lives in `sync_metadata_dao.dart` (added in Task 4). The `conflictHistoryDaoProvider` lives in `dao_providers.dart` (added in Task 3).

Add after `staleErrorCountProvider`:

```dart
// ---------------------------------------------------------------------------
// Table-Level Error Details (reactive stream)
// ---------------------------------------------------------------------------

/// Stream of sync errors grouped by table for the current user.
final syncErrorDetailsProvider =
    StreamProvider.family<List<SyncErrorDetail>, String>((ref, userId) {
  if (userId == 'anonymous') return Stream.value([]);
  final syncDao = ref.watch(syncMetadataDaoProvider);
  return syncDao.watchErrorsByTable(userId);
});

/// Stream of pending sync records grouped by table for the current user.
final pendingByTableProvider =
    StreamProvider.family<List<SyncErrorDetail>, String>((ref, userId) {
  if (userId == 'anonymous') return Stream.value([]);
  final syncDao = ref.watch(syncMetadataDaoProvider);
  return syncDao.watchPendingByTable(userId);
});

/// Stream count of persisted conflict history records.
final persistedConflictCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  if (userId == 'anonymous') return Stream.value(0);
  final dao = ref.watch(conflictHistoryDaoProvider);
  return dao.watchRecentCount(userId, const Duration(hours: 24));
});
```

- [ ] **Step 2: Update ConflictHistoryNotifier to restore from DB on build**

Replace existing `ConflictHistoryNotifier`:

```dart
class ConflictHistoryNotifier extends Notifier<List<SyncConflict>> {
  static const _maxEntries = 50;

  @override
  List<SyncConflict> build() {
    // Restore from persisted DB on startup (async, non-blocking)
    _restoreFromDb();
    return [];
  }

  Future<void> _restoreFromDb() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == 'anonymous') return;
      final dao = ref.read(conflictHistoryDaoProvider);
      final persisted = await dao.watchAll(userId).first;
      if (persisted.isNotEmpty) {
        state = persisted.map((c) => SyncConflict(
          table: c.tableName,
          recordId: c.recordId,
          detectedAt: c.createdAt ?? DateTime.now(),
          description: c.description,
        )).take(_maxEntries).toList();
      }
    } catch (e) {
      AppLogger.debug('[ConflictHistory] Restore failed: $e');
    }
  }

  void addConflict(SyncConflict conflict) {
    state = [conflict, ...state].take(_maxEntries).toList();
  }

  void clear() => state = [];
}
```

- [ ] **Step 3: Run analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/domain/services/sync/sync_providers.dart
git commit -m "feat(sync): add syncErrorDetailsProvider, pendingByTableProvider, DB-restore for conflicts"
```

---

## Task 6: Persist Conflicts in Pull Handler + Orchestrator Cleanup

**Files:**
- Modify: `lib/domain/services/sync/sync_pull_handler.dart`
- Modify: `lib/domain/services/sync/sync_orchestrator.dart`

- [ ] **Step 1: Update _reportPullConflicts in sync_pull_handler.dart**

Add import at top:
```dart
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/conflict_history_model.dart';
import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';
import 'package:uuid/uuid.dart';
```

Replace the `_reportPullConflicts` method body (lines 202-221 area) to also persist:

```dart
  void _reportPullConflicts(
    List<({String recordId, String detail})> conflicts,
    String tableName,
  ) {
    if (conflicts.isEmpty) return;

    final notifier = _ref.read(conflictHistoryProvider.notifier);
    final dao = _ref.read(conflictHistoryDaoProvider);
    final userId = _ref.read(currentUserIdProvider);
    const uuid = Uuid();

    for (final c in conflicts) {
      // In-memory (existing behavior)
      notifier.addConflict(
        SyncConflict(
          table: tableName,
          recordId: c.recordId,
          detectedAt: DateTime.now(),
          description: c.detail,
        ),
      );

      // Persist to DB (new behavior)
      dao.insert(ConflictHistory(
        id: uuid.v4(),
        userId: userId,
        tableName: tableName,
        recordId: c.recordId,
        description: c.detail,
        conflictType: ConflictType.serverWins,
        createdAt: DateTime.now(),
      ));
    }

    AppLogger.info(
      '[SyncOrchestrator] ${conflicts.length} conflict(s) detected in $tableName',
    );
  }
```

- [ ] **Step 2: Add conflict cleanup in sync_orchestrator.dart**

Add import at top:
```dart
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart'
    show conflictHistoryDaoProvider;
```

In the cleanup phase of `fullSync()` (after `_errorHandler.cleanupUnrecoverableErrors(userId)`), add:

```dart
      // Clean up old conflict history (30-day retention)
      try {
        final conflictDao = _ref.read(conflictHistoryDaoProvider);
        await conflictDao.deleteOlderThan(30);
      } catch (e) {
        AppLogger.debug('[SyncOrchestrator] Conflict cleanup failed: $e');
      }
```

- [ ] **Step 3: Run analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/domain/services/sync/sync_pull_handler.dart lib/domain/services/sync/sync_orchestrator.dart
git commit -m "feat(sync): persist conflicts to DB, add 30-day cleanup in orchestrator"
```

---

## Task 7: Localization Keys (3 Languages)

**Files:**
- Modify: `assets/translations/tr.json`
- Modify: `assets/translations/en.json`
- Modify: `assets/translations/de.json`

- [ ] **Step 1: Add keys to tr.json**

In the `"sync"` section, add these keys:

```json
"error_details_title": "Senkronizasyon Detayları",
"pending_section": "Bekleyen Kayıtlar",
"failed_section": "Başarısız Kayıtlar",
"conflict_section": "Çakışma Geçmişi",
"error_count_summary": "{} kayıt senkronize edilemedi",
"error_table_summary": "{} {} kaydı başarısız",
"table_birds": "Kuş",
"table_eggs": "Yumurta",
"table_chicks": "Yavru",
"table_breeding_pairs": "Üreme Çifti",
"table_clutches": "Kuluçka",
"table_nests": "Yuva",
"table_health_records": "Sağlık Kaydı",
"table_events": "Etkinlik",
"table_other": "Diğer",
"conflict_server_wins": "Sunucu verisi korundu",
"conflict_orphan_deleted": "Yerel kayıt silindi",
"clear_conflict_history": "Geçmişi Temizle",
"no_errors": "Tüm veriler senkronize",
"no_conflicts": "Çakışma geçmişi boş",
"sync_now_action": "Şimdi Senkronize Et",
"view_details": "Detayları Gör"
```

- [ ] **Step 2: Add keys to en.json**

```json
"error_details_title": "Sync Details",
"pending_section": "Pending Records",
"failed_section": "Failed Records",
"conflict_section": "Conflict History",
"error_count_summary": "{} records failed to sync",
"error_table_summary": "{} {} records failed",
"table_birds": "Bird",
"table_eggs": "Egg",
"table_chicks": "Chick",
"table_breeding_pairs": "Breeding Pair",
"table_clutches": "Clutch",
"table_nests": "Nest",
"table_health_records": "Health Record",
"table_events": "Event",
"table_other": "Other",
"conflict_server_wins": "Server data preserved",
"conflict_orphan_deleted": "Local record deleted",
"clear_conflict_history": "Clear History",
"no_errors": "All data synced",
"no_conflicts": "No conflict history",
"sync_now_action": "Sync Now",
"view_details": "View Details"
```

- [ ] **Step 3: Add keys to de.json**

```json
"error_details_title": "Synchronisierungsdetails",
"pending_section": "Ausstehende Einträge",
"failed_section": "Fehlgeschlagene Einträge",
"conflict_section": "Konfliktverlauf",
"error_count_summary": "{} Einträge konnten nicht synchronisiert werden",
"error_table_summary": "{} {} Einträge fehlgeschlagen",
"table_birds": "Vogel",
"table_eggs": "Ei",
"table_chicks": "Küken",
"table_breeding_pairs": "Zuchtpaar",
"table_clutches": "Gelege",
"table_nests": "Nest",
"table_health_records": "Gesundheitsbericht",
"table_events": "Ereignis",
"table_other": "Sonstige",
"conflict_server_wins": "Serverdaten beibehalten",
"conflict_orphan_deleted": "Lokaler Eintrag gelöscht",
"clear_conflict_history": "Verlauf löschen",
"no_errors": "Alle Daten synchronisiert",
"no_conflicts": "Kein Konfliktverlauf",
"sync_now_action": "Jetzt synchronisieren",
"view_details": "Details anzeigen"
```

- [ ] **Step 4: Run l10n sync check**

Run: `python scripts/check_l10n_sync.py`
Expected: PASS (all 3 files in sync)

- [ ] **Step 5: Commit**

```bash
git add assets/translations/tr.json assets/translations/en.json assets/translations/de.json
git commit -m "feat(l10n): add sync detail and conflict history localization keys"
```

---

## Task 8: SyncDetailSheet Widget

**Files:**
- Create: `lib/features/settings/widgets/sync_detail_sheet.dart`

- [ ] **Step 1: Create SyncDetailSheet**

This is a bottom sheet with 3 sections: pending, failed, conflict history. Use existing project patterns (AppSpacing, Theme.of(context), .tr(), AppIcon).

Key references:
- `lib/features/settings/widgets/data_storage_dialogs.dart` — existing conflict dialog pattern
- `lib/features/profile/widgets/sync_status_tile.dart` — sync provider usage pattern
- `lib/core/widgets/cards/info_card.dart` — card widget pattern

The widget watches:
- `pendingByTableProvider(userId)` for pending section
- `syncErrorDetailsProvider(userId)` for failed section
- `conflictHistoryProvider` for conflict history section

Actions:
- "Sync Now" button calls `triggerManualSync(ref)`
- "Clear History" button calls `ref.read(conflictHistoryDaoProvider).deleteAll(userId)` and `ref.read(conflictHistoryProvider.notifier).clear()`

Helper function to map table name to localized string and icon:
```dart
String _localizeTable(String table) => switch (table) {
  'birds' => 'sync.table_birds'.tr(),
  'eggs' => 'sync.table_eggs'.tr(),
  'chicks' => 'sync.table_chicks'.tr(),
  'breeding_pairs' => 'sync.table_breeding_pairs'.tr(),
  'clutches' => 'sync.table_clutches'.tr(),
  'nests' => 'sync.table_nests'.tr(),
  'health_records' => 'sync.table_health_records'.tr(),
  'events' => 'sync.table_events'.tr(),
  _ => 'sync.table_other'.tr(),
};
```

If file exceeds 300 lines, extract sections into private sub-widgets in the same file.

- [ ] **Step 2: Run analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/widgets/sync_detail_sheet.dart
git commit -m "feat(sync): add SyncDetailSheet bottom sheet widget"
```

---

## Task 8b: Widget Tests for SyncDetailSheet

**Files:**
- Test: `test/features/settings/widgets/sync_detail_sheet_test.dart`

- [ ] **Step 1: Write widget test**

Test that the sheet displays sections correctly when providers return data. Use `ProviderScope.overrides` to inject test data:
- Override `syncErrorDetailsProvider` with mock error data (2 egg errors, 1 bird error)
- Override `pendingByTableProvider` with mock pending data
- Override `conflictHistoryProvider` with mock conflict list
- Verify section headers render: "Bekleyen Kayitlar", "Basarisiz Kayitlar", "Cakisma Gecmisi"
- Verify error count text appears
- Verify empty state text when no errors/conflicts

Use `pumpWidget` with `MaterialApp` + `EasyLocalization` test wrapper (follow existing widget test patterns in `test/features/`).

- [ ] **Step 2: Run test**

Run: `flutter test test/features/settings/widgets/sync_detail_sheet_test.dart`
Expected: ALL PASS

- [ ] **Step 3: Commit**

```bash
git add test/features/settings/widgets/sync_detail_sheet_test.dart
git commit -m "test(sync): add widget tests for SyncDetailSheet"
```

---

## Task 9: Enhance SyncStatusTile and SyncStatusBar

**Files:**
- Modify: `lib/features/profile/widgets/sync_status_tile.dart`
- Modify: `lib/features/home/widgets/sync_status_bar.dart`

- [ ] **Step 1: Update SyncStatusTile**

Add import for the sheet and providers:
```dart
import 'package:budgie_breeding_tracker/features/settings/widgets/sync_detail_sheet.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
```

Changes to `build()`:
1. Watch `syncErrorDetailsProvider` when status is error
2. Replace `_statusSubtitle` error case with specific table-level message
3. Wrap entire tile in `GestureDetector` → opens `SyncDetailSheet` on tap

In `_statusSubtitle`, change the error branch:
```dart
if (status == SyncDisplayStatus.error) {
  final userId = ref.watch(currentUserIdProvider);
  final errorDetails = ref.watch(syncErrorDetailsProvider(userId));
  final totalErrors = errorDetails.value?.fold<int>(0, (sum, d) => sum + d.errorCount) ?? 0;
  if (totalErrors > 0) {
    return 'sync.error_count_summary'.tr(args: ['$totalErrors']) + pendingSuffix;
  }
  return 'profile.sync_error'.tr() + pendingSuffix;
}
```

Change widget type from `ConsumerWidget` to `ConsumerWidget` with onTap:
```dart
// Wrap the Padding in a GestureDetector:
return GestureDetector(
  onTap: () => _showSyncDetails(context, ref),
  child: Padding(/* existing code */),
);
```

Add helper:
```dart
void _showSyncDetails(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const SyncDetailSheet(),
  );
}
```

- [ ] **Step 2: Update SyncStatusBar**

Add import:
```dart
import 'package:budgie_breeding_tracker/features/settings/widgets/sync_detail_sheet.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
```

Changes:
1. In error state label: watch `syncErrorDetailsProvider` and show count
2. Change onTap: if error state, open `SyncDetailSheet`; otherwise trigger sync

Replace the `GestureDetector.onTap` in build:
```dart
onTap: () {
  if (status == SyncDisplayStatus.error) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SyncDetailSheet(),
    );
  } else if (status != SyncDisplayStatus.syncing) {
    final orchestrator = ref.read(syncOrchestratorProvider);
    orchestrator.fullSync();
  }
},
```

For error label, watch error details:
```dart
SyncDisplayStatus.error => (
  AppIcon(AppIcons.offline, size: 13, color: colorScheme.error),
  colorScheme.error,
  _errorLabel(ref),
),
```

Add helper:
```dart
String _errorLabel(WidgetRef ref) {
  final userId = ref.watch(currentUserIdProvider);
  final details = ref.watch(syncErrorDetailsProvider(userId));
  final total = details.value?.fold<int>(0, (sum, d) => sum + d.errorCount) ?? 0;
  if (total > 0) return 'sync.error_count_summary'.tr(args: ['$total']);
  return 'sync.sync_error'.tr();
}
```

- [ ] **Step 3: Run analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/features/profile/widgets/sync_status_tile.dart lib/features/home/widgets/sync_status_bar.dart
git commit -m "feat(sync): enhance status tile and bar with table-level error details"
```

---

## Task 10: Documentation Updates

**Files:**
- Modify: `.claude/rules/database.md`
- Modify: `.claude/rules/supabase_rules.md`
- Modify: `.claude/rules/CLAUDE.md`
- Modify: `CLAUDE.md` (root)

- [ ] **Step 1: Update database.md**

After the "Local-Only Entity Pattern" section, add:

```markdown
### ValidatedSyncMixin (FK-Dependent Entities)
Used by: **Egg, Chick, EventReminder** repositories (entities with FK dependencies).
- Max retries: **10** (vs standard 5 for other entities)
- Before push: validates FK references exist locally AND are not pending sync
- On FK validation failure: marks as sync error (not deleted), kept for retry
- Stale cleanup: records with retryCount >= 10 AND older than 24h auto-deleted
- Orphan handling: sync_metadata without matching local record auto-deleted
```

Also add ConflictHistory to the local-only entity list:
```
GeneticsHistory, UserPreferences, NotificationSettings, ConflictHistory:
```

- [ ] **Step 2: Update supabase_rules.md**

Update the "Repository Variants" table to include Max Retry column:

```markdown
| Pattern | Use Case | Max Retry |
|---------|----------|-----------|
| `BaseRepository + SyncableRepository` | Bird, Nest, Event, Notification, etc. | 5 |
| `+ ValidatedSyncMixin` | Egg, Chick, EventReminder (FK deps) | 10 |
| `ProfileRepository` (custom) | Single-record, push-before-pull | 5 |
| `SyncMetadataRepository` | Local-only (no remote) | N/A |
| DAO directly | GeneticsHistory, ConflictHistory (no remote, no repo) | N/A |
```

- [ ] **Step 3: Update .claude/rules/CLAUDE.md and root CLAUDE.md**

Update stats:
- Drift tables: 19 → 20
- DAOs: 19 → 20
- Mappers: 19 → 20
- Schema version: 15 → 16

Add to Sync Architecture in quick reference:
- `ValidatedSyncMixin`: Egg, Chick, EventReminder (10 retries, FK validation)
- `ConflictHistory`: local-only (Drift table + DAO + mapper, no remote/repo)

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/database.md .claude/rules/supabase_rules.md .claude/rules/CLAUDE.md CLAUDE.md
git commit -m "docs: add ValidatedSyncMixin docs, update stats for conflict_history entity"
```

---

## Task 11: Final Verification

- [ ] **Step 1: Run full analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 2: Run all tests**

Run: `flutter test --exclude-tags golden`
Expected: ALL PASS (existing + new tests)

- [ ] **Step 3: Run l10n sync**

Run: `python scripts/check_l10n_sync.py`
Expected: PASS

- [ ] **Step 4: Run code quality**

Run: `python scripts/verify_code_quality.py`
Expected: PASS (no anti-patterns)

- [ ] **Step 5: Commit if any fixes needed, then final status check**

Run: `git status`
Expected: Clean working tree (all committed)
