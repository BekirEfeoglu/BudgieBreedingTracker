import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/health_records_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/health_record_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';

part 'health_records_dao.g.dart';

@DriftAccessor(tables: [HealthRecordsTable])
class HealthRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$HealthRecordsDaoMixin {
  HealthRecordsDao(super.db);

  /// Watches all non-deleted health records for a user, ordered by date descending.
  Stream<List<HealthRecord>> watchAll(String userId) {
    return (select(healthRecordsTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  /// Watches a single health record by id.
  Stream<HealthRecord?> watchById(String id) {
    return (select(healthRecordsTable)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  /// Gets all non-deleted health records for a user.
  Future<List<HealthRecord>> getAll(String userId) async {
    final rows = await (select(
      healthRecordsTable,
    )..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Gets a single health record by id.
  Future<HealthRecord?> getById(String id) async {
    final row = await (select(
      healthRecordsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  /// Inserts or updates a health record.
  Future<void> insertItem(HealthRecord model) {
    return into(healthRecordsTable).insertOnConflictUpdate(model.toCompanion());
  }

  /// Batch inserts health records.
  Future<void> insertAll(List<HealthRecord> models) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        healthRecordsTable,
        models.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  /// Updates a health record.
  Future<bool> updateItem(HealthRecord model) {
    return update(healthRecordsTable).replace(model.toCompanion());
  }

  /// Soft-deletes a health record by setting isDeleted to true.
  Future<void> softDelete(String id) {
    return (update(healthRecordsTable)..where((t) => t.id.equals(id))).write(
      HealthRecordsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Permanently deletes a health record.
  Future<int> hardDelete(String id) {
    return (delete(healthRecordsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Watches the count of non-deleted health records for a user.
  Stream<int> watchCount(String userId) {
    final countExpr = healthRecordsTable.id.count();
    return (selectOnly(healthRecordsTable)
          ..addColumns([countExpr])
          ..where(
            healthRecordsTable.userId.equals(userId) &
                healthRecordsTable.isDeleted.equals(false),
          ))
        .watchSingle()
        .map((row) => row.read(countExpr) ?? 0);
  }

  /// Watches non-deleted health records for a specific bird.
  Stream<List<HealthRecord>> watchByBird(String birdId) {
    return (select(healthRecordsTable)
          ..where((t) => t.birdId.equals(birdId) & t.isDeleted.equals(false)))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  /// Gets the latest health records for a specific bird, ordered by date descending.
  Future<List<HealthRecord>> getLatest(String birdId, {int limit = 5}) async {
    final rows =
        await (select(healthRecordsTable)
              ..where(
                (t) => t.birdId.equals(birdId) & t.isDeleted.equals(false),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(limit))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }
}
