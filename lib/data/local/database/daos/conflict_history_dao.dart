import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/conflict_history_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/conflict_history_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/conflict_history_model.dart';

part 'conflict_history_dao.g.dart';

@DriftAccessor(tables: [ConflictHistoryTable])
class ConflictHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$ConflictHistoryDaoMixin {
  ConflictHistoryDao(super.db);

  Stream<List<ConflictHistory>> watchAll(String userId) {
    return (select(conflictHistoryTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(100))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Stream<int> watchRecentCount(String userId, Duration since) {
    final cutoff = DateTime.now().subtract(since);
    final count = conflictHistoryTable.id.count();
    return (selectOnly(conflictHistoryTable)
          ..addColumns([count])
          ..where(
            conflictHistoryTable.userId.equals(userId) &
                conflictHistoryTable.resolvedAt.isNull() &
                conflictHistoryTable.createdAt.isBiggerOrEqualValue(cutoff),
          ))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  Stream<bool> watchExistsForRecord(
    String userId,
    String tableName,
    String recordId,
  ) {
    final count = conflictHistoryTable.id.count();
    return (selectOnly(conflictHistoryTable)
          ..addColumns([count])
          ..where(
            conflictHistoryTable.userId.equals(userId) &
                conflictHistoryTable.tableName_.equals(tableName) &
                conflictHistoryTable.recordId.equals(recordId),
          ))
        .watchSingle()
        .map((row) => (row.read(count) ?? 0) > 0);
  }

  Future<bool> existsForRecord(
    String userId,
    String tableName,
    String recordId,
  ) async {
    final count = conflictHistoryTable.id.count();
    final row =
        await (selectOnly(conflictHistoryTable)
              ..addColumns([count])
              ..where(
                conflictHistoryTable.userId.equals(userId) &
                    conflictHistoryTable.tableName_.equals(tableName) &
                    conflictHistoryTable.recordId.equals(recordId),
              ))
            .getSingle();
    return (row.read(count) ?? 0) > 0;
  }

  Future<void> insert(ConflictHistory conflict) {
    return into(
      conflictHistoryTable,
    ).insertOnConflictUpdate(conflict.toCompanion());
  }

  Future<void> insertAll(List<ConflictHistory> conflicts) {
    if (conflicts.isEmpty) return Future.value();
    return batch((b) {
      b.insertAllOnConflictUpdate(
        conflictHistoryTable,
        conflicts.map((c) => c.toCompanion()).toList(),
      );
    });
  }

  /// Inserts at most one recoverable unresolved conflict per record.
  ///
  /// The oldest encrypted local snapshot is the only trustworthy pre-overwrite
  /// value. Repeated pulls must not append a later server-wins snapshot that
  /// would overwrite that original value during recovery. The transaction also
  /// serializes concurrent pull attempts on the local database.
  Future<int> insertAllPreservingOldestRecoverable(
    List<ConflictHistory> conflicts,
  ) {
    if (conflicts.isEmpty) return Future.value(0);
    return attachedDatabase.transaction(() async {
      var inserted = 0;
      for (final conflict in conflicts) {
        final existing =
            await (select(conflictHistoryTable)
                  ..where(
                    (t) =>
                        t.userId.equals(conflict.userId) &
                        t.tableName_.equals(conflict.tableName) &
                        t.recordId.equals(conflict.recordId) &
                        t.resolvedAt.isNull() &
                        t.localPayload.isNotNull() &
                        t.payloadVersion.isNotNull(),
                  )
                  ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
                  ..limit(1))
                .getSingleOrNull();
        if (existing != null) continue;

        await into(
          conflictHistoryTable,
        ).insertOnConflictUpdate(conflict.toCompanion());
        inserted++;
      }
      return inserted;
    });
  }

  Future<ConflictHistory?> getById(String id) async {
    final row = await (select(
      conflictHistoryTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  Future<List<ConflictHistory>> getUnresolved(String userId) async {
    final rows =
        await (select(conflictHistoryTable)
              ..where((t) => t.userId.equals(userId) & t.resolvedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return rows.map((row) => row.toModel()).toList();
  }

  Future<int> markResolvedIfUnresolved(
    String id,
    DateTime resolvedAt, {
    ConflictType? conflictType,
  }) {
    return (update(
      conflictHistoryTable,
    )..where((t) => t.id.equals(id) & t.resolvedAt.isNull())).write(
      ConflictHistoryTableCompanion(
        resolvedAt: Value(resolvedAt.toUtc()),
        conflictType: conflictType == null
            ? const Value.absent()
            : Value(conflictType),
      ),
    );
  }

  Future<int> deleteOlderThan(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return (delete(
      conflictHistoryTable,
    )..where((t) => t.createdAt.isSmallerOrEqualValue(cutoff))).go();
  }

  Future<int> deleteAll(String userId) {
    return (delete(
      conflictHistoryTable,
    )..where((t) => t.userId.equals(userId))).go();
  }
}
