import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/nests_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/nest_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/nest_model.dart';

part 'nests_dao.g.dart';

@DriftAccessor(tables: [NestsTable])
class NestsDao extends DatabaseAccessor<AppDatabase> with _$NestsDaoMixin {
  NestsDao(super.db);

  Stream<List<Nest>> watchAll(String userId) {
    return (select(nestsTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Stream<Nest?> watchById(String id) {
    return (select(nestsTable)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  Future<List<Nest>> getAll(String userId) async {
    final rows = await (select(
      nestsTable,
    )..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<Nest?> getById(String id) async {
    final row = await (select(
      nestsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  Future<void> insertItem(Nest model) {
    return into(nestsTable).insertOnConflictUpdate(model.toCompanion());
  }

  Future<void> insertAll(List<Nest> models) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        nestsTable,
        models.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  Future<void> softDelete(String id) {
    return (update(nestsTable)..where((t) => t.id.equals(id))).write(
      NestsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> hardDelete(String id) {
    return (delete(nestsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Nest>> getAvailable(String userId) async {
    final rows =
        await (select(nestsTable)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.status.equalsValue(NestStatus.available) &
                  t.isDeleted.equals(false),
            ))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }
}
