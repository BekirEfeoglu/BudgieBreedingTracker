import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/clutches_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/clutch_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';

part 'clutches_dao.g.dart';

@DriftAccessor(tables: [ClutchesTable])
class ClutchesDao extends DatabaseAccessor<AppDatabase>
    with _$ClutchesDaoMixin {
  ClutchesDao(super.db);

  Stream<List<Clutch>> watchAll(String userId) {
    return (select(clutchesTable)
          ..where(
              (t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Stream<Clutch?> watchById(String id) {
    return (select(clutchesTable)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  Future<List<Clutch>> getAll(String userId) async {
    final rows = await (select(clutchesTable)
          ..where(
              (t) => t.userId.equals(userId) & t.isDeleted.equals(false)))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<Clutch?> getById(String id) async {
    final row = await (select(clutchesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toModel();
  }

  Future<void> insertItem(Clutch model) {
    return into(clutchesTable).insertOnConflictUpdate(model.toCompanion());
  }

  Future<void> insertAll(List<Clutch> models) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        clutchesTable,
        models.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  Future<void> softDelete(String id) {
    return (update(clutchesTable)..where((t) => t.id.equals(id))).write(
      ClutchesTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> hardDelete(String id) {
    return (delete(clutchesTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Clutch>> getByBreeding(String breedingId) async {
    final rows = await (select(clutchesTable)
          ..where((t) =>
              t.breedingId.equals(breedingId) & t.isDeleted.equals(false)))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }
}
