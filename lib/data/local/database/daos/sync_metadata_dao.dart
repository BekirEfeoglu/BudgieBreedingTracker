import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/sync_metadata_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/sync_metadata_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';

part 'sync_metadata_dao.g.dart';

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

@DriftAccessor(tables: [SyncMetadataTable])
class SyncMetadataDao extends DatabaseAccessor<AppDatabase>
    with _$SyncMetadataDaoMixin {
  SyncMetadataDao(super.db);

  Stream<List<SyncMetadata>> watchAll(String userId) {
    return (select(syncMetadataTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Future<List<SyncMetadata>> getAll(String userId) async {
    final rows = await (select(
      syncMetadataTable,
    )..where((t) => t.userId.equals(userId))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<SyncMetadata?> getById(String id) async {
    final row = await (select(
      syncMetadataTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  Future<void> insertItem(SyncMetadata metadata) {
    return into(
      syncMetadataTable,
    ).insertOnConflictUpdate(metadata.toCompanion());
  }

  /// Bulk upsert of sync metadata keyed on the logical record, not the PK.
  ///
  /// Callers (repository `saveAll`, cascade-delete tombstones) build each row
  /// with a FRESH `_uuid.v7()` primary key but target an existing
  /// `(tableName, recordId)`. A plain [batch.insertAllOnConflictUpdate] conflicts
  /// on the primary key only (Drift's default target), so a fresh PK for a
  /// record that already has a pending/error row falls through to the separate
  /// `UNIQUE(table_name, record_id)` index and throws
  /// `UNIQUE constraint failed: sync_metadata.table_name, sync_metadata.record_id`.
  ///
  /// Mirror [markPendingByRecords]: for each incoming `(tableName, recordId)`
  /// look up the existing row, reuse its primary key and preserve its
  /// `createdAt` (so stale-error cleanup timing is not reset), then delete the
  /// target keys and insert the merged rows in one batch — exactly one row per
  /// record. Status-agnostic: honors each item's status, so it is correct for
  /// both `pending` saves and `pendingDelete` tombstones. Rows with a null
  /// `recordId` never collide on the unique index (SQLite treats NULLs as
  /// distinct) and are inserted as-is.
  Future<void> insertAll(List<SyncMetadata> items) async {
    if (items.isEmpty) return;
    final itemsByTable = <String, List<SyncMetadata>>{};
    for (final item in items) {
      itemsByTable.putIfAbsent(item.table, () => <SyncMetadata>[]).add(item);
    }
    final companions = <SyncMetadataTableCompanion>[];
    final deleteByTable = <String, List<String>>{};
    for (final entry in itemsByTable.entries) {
      final table = entry.key;
      final recordIds = entry.value
          .map((m) => m.recordId)
          .whereType<String>()
          .toList();
      final existingByRecordId = <String, SyncMetadata>{};
      if (recordIds.isNotEmpty) {
        for (final existing in await getByRecords(table, recordIds)) {
          final recordId = existing.recordId;
          if (recordId != null) {
            existingByRecordId.putIfAbsent(recordId, () => existing);
          }
        }
        deleteByTable[table] = recordIds;
      }
      for (final item in entry.value) {
        final current = item.recordId == null
            ? null
            : existingByRecordId[item.recordId];
        companions.add(
          (current == null
                  ? item
                  : item.copyWith(
                      id: current.id,
                      createdAt: current.createdAt,
                    ))
              .toCompanion(),
        );
      }
    }
    await batch((b) {
      deleteByTable.forEach((table, recordIds) {
        b.deleteWhere(
          syncMetadataTable,
          (t) => t.tableName_.equals(table) & t.recordId.isIn(recordIds),
        );
      });
      b.insertAllOnConflictUpdate(syncMetadataTable, companions);
    });
  }

  Future<void> updateItem(SyncMetadata metadata) {
    return update(syncMetadataTable).replace(metadata.toCompanion());
  }

  Future<void> hardDelete(String id) {
    return (delete(syncMetadataTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<SyncMetadata>> getPending(String userId) async {
    final rows =
        await (select(syncMetadataTable)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.status.equalsValue(SyncStatus.pending),
            ))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Gets pending sync records for a specific table.
  ///
  /// Includes both [SyncStatus.pending] and [SyncStatus.pendingDelete]
  /// records so that offline deletes are also pushed during sync.
  Future<List<SyncMetadata>> getPendingByTable(
    String userId,
    String tableName,
  ) async {
    final rows =
        await (select(syncMetadataTable)..where(
              (t) =>
                  t.userId.equals(userId) &
                  (t.status.equalsValue(SyncStatus.pending) |
                      t.status.equalsValue(SyncStatus.pendingDelete)) &
                  t.tableName_.equals(tableName),
            ))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Gets error sync records for a specific table.
  Future<List<SyncMetadata>> getErrorsByTable(
    String userId,
    String tableName,
  ) async {
    final rows =
        await (select(syncMetadataTable)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.status.equalsValue(SyncStatus.error) &
                  t.tableName_.equals(tableName),
            ))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Gets all unsynced record IDs (pending + error) as a Set for fast lookup.
  ///
  /// Used by reconciliation to protect records that haven't been successfully
  /// pushed to the server. Includes both [SyncStatus.pending] and
  /// [SyncStatus.error] records — error records are items that failed to push
  /// and must not be deleted during full reconciliation.
  Future<Set<String>> getPendingRecordIds(String userId) async {
    final rows =
        await (selectOnly(syncMetadataTable)
              ..addColumns([syncMetadataTable.recordId])
              ..where(
                syncMetadataTable.userId.equals(userId) &
                    (syncMetadataTable.status.equalsValue(SyncStatus.pending) |
                        syncMetadataTable.status.equalsValue(SyncStatus.error)),
              ))
            .get();
    return rows
        .map((row) => row.read(syncMetadataTable.recordId))
        .whereType<String>()
        .toSet();
  }

  /// Returns the set of table names that have pending sync records.
  ///
  /// Used by [SyncOrchestrator] to skip layers with no pending writes or
  /// deletes, avoiding unnecessary repository reads and empty push cycles.
  Future<Set<String>> getPendingTableNames(String userId) async {
    final rows =
        await (selectOnly(syncMetadataTable)
              ..addColumns([syncMetadataTable.tableName_])
              ..where(
                syncMetadataTable.userId.equals(userId) &
                    (syncMetadataTable.status.equalsValue(SyncStatus.pending) |
                        syncMetadataTable.status.equalsValue(
                          SyncStatus.pendingDelete,
                        )),
              )
              ..groupBy([syncMetadataTable.tableName_]))
            .get();
    return rows
        .map((row) => row.read(syncMetadataTable.tableName_))
        .whereType<String>()
        .toSet();
  }

  /// Counts pending sync records for a user (lightweight — no row mapping).
  Future<int> countPending(String userId) async {
    final count = syncMetadataTable.id.count();
    final row =
        await (selectOnly(syncMetadataTable)
              ..addColumns([count])
              ..where(
                syncMetadataTable.userId.equals(userId) &
                    syncMetadataTable.status.equalsValue(SyncStatus.pending),
              ))
            .getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<SyncMetadata>> getErrors(String userId) async {
    final rows =
        await (select(syncMetadataTable)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.status.equalsValue(SyncStatus.error),
            ))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<void> updateStatus(String id, SyncStatus status) {
    return (update(syncMetadataTable)..where((t) => t.id.equals(id))).write(
      SyncMetadataTableCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Gets the sync metadata for a specific record.
  /// Uses get() + firstOrNull instead of getSingleOrNull to handle
  /// duplicate records gracefully (avoids "more than one result" crash).
  Future<SyncMetadata?> getByRecord(String tableName, String recordId) async {
    final rows =
        await (select(syncMetadataTable)
              ..where(
                (t) =>
                    t.tableName_.equals(tableName) &
                    t.recordId.equals(recordId),
              )
              ..limit(1))
            .get();
    return rows.isEmpty ? null : rows.first.toModel();
  }

  Future<void> deleteByRecord(String tableName, String recordId) {
    return (delete(syncMetadataTable)..where(
          (t) => t.tableName_.equals(tableName) & t.recordId.equals(recordId),
        ))
        .go();
  }

  /// Batch equivalent of [getByRecord]: all metadata rows for the given
  /// (tableName, recordIds). Empty input returns an empty list without
  /// touching the database.
  Future<List<SyncMetadata>> getByRecords(
    String tableName,
    List<String> recordIds,
  ) async {
    if (recordIds.isEmpty) return const <SyncMetadata>[];
    final rows =
        await (select(syncMetadataTable)..where(
              (t) =>
                  t.tableName_.equals(tableName) & t.recordId.isIn(recordIds),
            ))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Batch equivalent of [deleteByRecord] — single DELETE with IN clause.
  Future<void> deleteByRecords(String tableName, List<String> recordIds) {
    if (recordIds.isEmpty) return Future.value();
    return (delete(syncMetadataTable)..where(
          (t) => t.tableName_.equals(tableName) & t.recordId.isIn(recordIds),
        ))
        .go();
  }

  /// Batch equivalent of the repository-level markPending upsert dance.
  ///
  /// Existing `(tableName, recordId)` rows keep their primary key and are reset
  /// to pending; missing rows are inserted. Deleting and reinserting the target
  /// keys in one batch guarantees exactly one pending row per record and stays
  /// compatible with the v12 unique index.
  Future<void> markPendingByRecords(
    String tableName,
    Map<String, String> recordIdToUserId,
  ) async {
    if (recordIdToUserId.isEmpty) return;
    const uuid = Uuid();
    final existing = await getByRecords(
      tableName,
      recordIdToUserId.keys.toList(),
    );
    final existingByRecordId = <String, SyncMetadata>{};
    for (final metadata in existing) {
      final recordId = metadata.recordId;
      if (recordId != null) {
        existingByRecordId.putIfAbsent(recordId, () => metadata);
      }
    }
    final entries = recordIdToUserId.entries.map((e) {
      final current = existingByRecordId[e.key];
      if (current != null) {
        return current.copyWith(
          userId: e.value,
          status: SyncStatus.pending,
          errorMessage: null,
          retryCount: 0,
        );
      }
      return SyncMetadata(
        id: uuid.v7(),
        table: tableName,
        userId: e.value,
        status: SyncStatus.pending,
        recordId: e.key,
      );
    }).toList();
    final recordIds = recordIdToUserId.keys.toList();
    await batch((b) {
      b.deleteWhere(
        syncMetadataTable,
        (t) => t.tableName_.equals(tableName) & t.recordId.isIn(recordIds),
      );
      b.insertAllOnConflictUpdate(
        syncMetadataTable,
        entries.map((metadata) => metadata.toCompanion()).toList(),
      );
    });
  }

  Stream<int> watchPendingCount(String userId) {
    final count = syncMetadataTable.id.count();
    return (selectOnly(syncMetadataTable)
          ..addColumns([count])
          ..where(
            syncMetadataTable.userId.equals(userId) &
                syncMetadataTable.status.equalsValue(SyncStatus.pending),
          ))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  Future<int> countStaleErrors(
    String userId,
    Duration maxAge,
    int minRetries,
  ) async {
    final count = syncMetadataTable.id.count();
    final cutoff = DateTime.now().subtract(maxAge);
    final row =
        await (selectOnly(syncMetadataTable)
              ..addColumns([count])
              ..where(
                syncMetadataTable.userId.equals(userId) &
                    syncMetadataTable.status.equalsValue(SyncStatus.error) &
                    syncMetadataTable.createdAt.isSmallerOrEqualValue(cutoff) &
                    syncMetadataTable.retryCount.isBiggerOrEqualValue(
                      minRetries,
                    ),
              ))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// Returns stale error records that will be deleted by [deleteStaleErrors].
  Future<List<SyncMetadata>> getStaleErrors(
    String userId,
    Duration maxAge,
    int minRetries,
  ) async {
    final cutoff = DateTime.now().subtract(maxAge);
    final rows =
        await (select(syncMetadataTable)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.status.equalsValue(SyncStatus.error) &
                  t.createdAt.isSmallerOrEqualValue(cutoff) &
                  t.retryCount.isBiggerOrEqualValue(minRetries),
            ))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<int> deleteStaleErrors(
    String userId,
    Duration maxAge,
    int minRetries,
  ) async {
    final cutoff = DateTime.now().subtract(maxAge);
    return (delete(syncMetadataTable)..where(
          (t) =>
              t.userId.equals(userId) &
              t.status.equalsValue(SyncStatus.error) &
              t.createdAt.isSmallerOrEqualValue(cutoff) &
              t.retryCount.isBiggerOrEqualValue(minRetries),
        ))
        .go();
  }

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
        .map(
          (rows) => rows
              .map(
                (row) => SyncErrorDetail(
                  tableName: row.read(tbl) ?? '',
                  errorCount: row.read(cnt) ?? 0,
                  lastError: row.read(lastErr),
                  lastAttempt: row.read(lastTime),
                ),
              )
              .toList(),
        );
  }

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
        .map(
          (rows) => rows
              .map(
                (row) => SyncErrorDetail(
                  tableName: row.read(tbl) ?? '',
                  errorCount: row.read(cnt) ?? 0,
                ),
              )
              .toList(),
        );
  }
}
