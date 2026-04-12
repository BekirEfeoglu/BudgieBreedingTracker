import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/chicks_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/chick_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';

part 'chicks_dao.g.dart';

@DriftAccessor(tables: [ChicksTable])
class ChicksDao extends DatabaseAccessor<AppDatabase> with _$ChicksDaoMixin {
  ChicksDao(super.db);

  Stream<List<Chick>> watchAll(String userId) {
    return (select(chicksTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Stream<Chick?> watchById(String id) {
    return (select(chicksTable)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  Future<List<Chick>> getAll(String userId) async {
    final rows = await (select(
      chicksTable,
    )..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<Chick?> getById(String id) async {
    final row = await (select(
      chicksTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  Future<void> insertItem(Chick model) {
    return into(chicksTable).insertOnConflictUpdate(model.toCompanion());
  }

  Future<void> insertAll(List<Chick> models) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        chicksTable,
        models.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  Future<void> updateItem(Chick model) {
    return update(chicksTable).replace(model.toCompanion());
  }

  Future<void> softDelete(String id) {
    return (update(chicksTable)..where((t) => t.id.equals(id))).write(
      ChicksTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> hardDelete(String id) {
    return (delete(chicksTable)..where((t) => t.id.equals(id))).go();
  }

  /// Reactive count of all non-deleted chicks for a user (lightweight).
  Stream<int> watchCount(String userId) {
    final count = chicksTable.id.count();
    return (selectOnly(chicksTable)
          ..addColumns([count])
          ..where(
            chicksTable.userId.equals(userId) &
                chicksTable.isDeleted.equals(false),
          ))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  Stream<List<Chick>> watchByClutch(String clutchId) {
    return (select(chicksTable)..where(
          (t) => t.clutchId.equals(clutchId) & t.isDeleted.equals(false),
        ))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Future<Chick?> getByEggId(String eggId) async {
    final row =
        await (select(chicksTable)
              ..where((t) => t.eggId.equals(eggId) & t.isDeleted.equals(false)))
            .getSingleOrNull();
    return row?.toModel();
  }

  Future<List<Chick>> getByEggIds(List<String> eggIds) async {
    if (eggIds.isEmpty) return [];
    final rows = await (select(
      chicksTable,
    )..where((t) => t.eggId.isIn(eggIds) & t.isDeleted.equals(false))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<List<Chick>> getUnweaned(String userId) async {
    final rows =
        await (select(chicksTable)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.weanDate.isNull() &
                  t.isDeleted.equals(false),
            ))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Recent chicks sorted by hatch date descending (SQL LIMIT).
  Stream<List<Chick>> watchRecent(String userId, {int limit = 5}) {
    return (select(chicksTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.hatchDate)])
          ..limit(limit))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  /// Count of chicks that are 60+ days old, not yet moved to birds, and alive.
  Stream<int> watchUnweanedCount(String userId) {
    final count = chicksTable.id.count();
    final cutoff = DateTime.now().subtract(const Duration(days: 60));
    return (selectOnly(chicksTable)
          ..addColumns([count])
          ..where(
            chicksTable.userId.equals(userId) &
                chicksTable.isDeleted.equals(false) &
                chicksTable.birdId.isNull() &
                chicksTable.healthStatus.equalsValue(
                  ChickHealthStatus.healthy,
                ) &
                chicksTable.hatchDate.isSmallerOrEqualValue(cutoff),
          ))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }
}
