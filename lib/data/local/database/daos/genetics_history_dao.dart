import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/genetics_history_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/genetics_history_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';

part 'genetics_history_dao.g.dart';

@DriftAccessor(tables: [GeneticsHistoryTable])
class GeneticsHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$GeneticsHistoryDaoMixin {
  GeneticsHistoryDao(super.db);

  /// Watch all non-deleted history entries for a user, newest first.
  Stream<List<GeneticsHistory>> watchAll(String userId) {
    return (select(geneticsHistoryTable)
          ..where(
              (t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  /// Watch a single history entry by ID.
  Stream<GeneticsHistory?> watchById(String id) {
    return (select(geneticsHistoryTable)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  /// Get all non-deleted history entries for a user.
  Future<List<GeneticsHistory>> getAll(String userId) async {
    final rows = await (select(geneticsHistoryTable)
          ..where(
              (t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Get a single history entry by ID.
  Future<GeneticsHistory?> getById(String id) async {
    final row = await (select(geneticsHistoryTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toModel();
  }

  /// Insert or update a history entry.
  Future<void> insertItem(GeneticsHistory model) {
    return into(geneticsHistoryTable)
        .insertOnConflictUpdate(model.toCompanion());
  }

  /// Bulk insert history entries.
  Future<void> insertAll(List<GeneticsHistory> models) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        geneticsHistoryTable,
        models.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  /// Soft delete a history entry.
  Future<void> softDelete(String id) {
    return (update(geneticsHistoryTable)..where((t) => t.id.equals(id)))
        .write(
      GeneticsHistoryTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Hard delete a history entry.
  Future<void> hardDelete(String id) {
    return (delete(geneticsHistoryTable)..where((t) => t.id.equals(id))).go();
  }
}
