import 'package:drift/drift.dart';
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

  Future<void> insertAll(List<SyncMetadata> items) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        syncMetadataTable,
        items.map((m) => m.toCompanion()).toList(),
      );
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
  /// Used by [SyncOrchestrator] to skip layers with no pending changes,
  /// avoiding unnecessary repository reads and empty push cycles.
  Future<Set<String>> getPendingTableNames(String userId) async {
    final rows =
        await (selectOnly(syncMetadataTable)
              ..addColumns([syncMetadataTable.tableName_])
              ..where(
                syncMetadataTable.userId.equals(userId) &
                    syncMetadataTable.status.equalsValue(SyncStatus.pending),
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

  Future<int> countStaleErrors(String userId, Duration maxAge, int minRetries) async {
    final count = syncMetadataTable.id.count();
    final cutoff = DateTime.now().subtract(maxAge);
    final row = await (selectOnly(syncMetadataTable)
          ..addColumns([count])
          ..where(syncMetadataTable.userId.equals(userId) &
              syncMetadataTable.status.equalsValue(SyncStatus.error) &
              syncMetadataTable.createdAt.isSmallerOrEqualValue(cutoff) &
              syncMetadataTable.retryCount.isBiggerOrEqualValue(minRetries)))
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
    final rows = await (select(syncMetadataTable)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.status.equalsValue(SyncStatus.error) &
                t.createdAt.isSmallerOrEqualValue(cutoff) &
                t.retryCount.isBiggerOrEqualValue(minRetries),
          ))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<int> deleteStaleErrors(String userId, Duration maxAge, int minRetries) async {
    final cutoff = DateTime.now().subtract(maxAge);
    return (delete(syncMetadataTable)..where((t) =>
            t.userId.equals(userId) &
            t.status.equalsValue(SyncStatus.error) &
            t.createdAt.isSmallerOrEqualValue(cutoff) &
            t.retryCount.isBiggerOrEqualValue(minRetries)))
        .go();
  }

  Stream<List<SyncErrorDetail>> watchErrorsByTable(String userId) {
    final tbl = syncMetadataTable.tableName_;
    final cnt = syncMetadataTable.id.count();
    final lastErr = syncMetadataTable.errorMessage.max();
    final lastTime = syncMetadataTable.updatedAt.max();
    return (selectOnly(syncMetadataTable)
          ..addColumns([tbl, cnt, lastErr, lastTime])
          ..where(syncMetadataTable.userId.equals(userId) &
              syncMetadataTable.status.equalsValue(SyncStatus.error))
          ..groupBy([tbl]))
        .watch()
        .map((rows) => rows
            .map((row) => SyncErrorDetail(
                  tableName: row.read(tbl) ?? '',
                  errorCount: row.read(cnt) ?? 0,
                  lastError: row.read(lastErr),
                  lastAttempt: row.read(lastTime),
                ))
            .toList());
  }

  Stream<List<SyncErrorDetail>> watchPendingByTable(String userId) {
    final tbl = syncMetadataTable.tableName_;
    final cnt = syncMetadataTable.id.count();
    return (selectOnly(syncMetadataTable)
          ..addColumns([tbl, cnt])
          ..where(syncMetadataTable.userId.equals(userId) &
              syncMetadataTable.status.equalsValue(SyncStatus.pending))
          ..groupBy([tbl]))
        .watch()
        .map((rows) => rows
            .map((row) => SyncErrorDetail(
                  tableName: row.read(tbl) ?? '',
                  errorCount: row.read(cnt) ?? 0,
                ))
            .toList());
  }
}
