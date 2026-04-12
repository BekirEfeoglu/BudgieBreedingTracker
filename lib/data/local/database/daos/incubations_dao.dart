import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/incubations_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/incubation_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';

part 'incubations_dao.g.dart';

@DriftAccessor(tables: [IncubationsTable])
class IncubationsDao extends DatabaseAccessor<AppDatabase>
    with _$IncubationsDaoMixin {
  IncubationsDao(super.db);

  Stream<List<Incubation>> watchAll(String userId) {
    return (select(incubationsTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Stream<Incubation?> watchById(String id) {
    return (select(incubationsTable)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  Future<List<Incubation>> getAll(String userId) async {
    final rows = await (select(
      incubationsTable,
    )..where((t) => t.userId.equals(userId))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<Incubation?> getById(String id) async {
    final row = await (select(
      incubationsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  Future<void> insertItem(Incubation model) {
    return into(incubationsTable).insertOnConflictUpdate(model.toCompanion());
  }

  Future<void> insertAll(List<Incubation> models) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        incubationsTable,
        models.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  Future<void> updateItem(Incubation model) {
    return update(incubationsTable).replace(model.toCompanion());
  }

  Future<void> hardDelete(String id) {
    return (delete(incubationsTable)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<Incubation>> watchActive(String userId) {
    return (select(incubationsTable)..where(
          (t) =>
              t.userId.equals(userId) &
              t.status.equalsValue(IncubationStatus.active),
        ))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  /// One-shot count of active incubations.
  Future<int> getActiveCount(String userId) async {
    final count = incubationsTable.id.count();
    final row = await (selectOnly(incubationsTable)
          ..addColumns([count])
          ..where(
            incubationsTable.userId.equals(userId) &
                incubationsTable.status.equalsValue(IncubationStatus.active),
          ))
        .getSingle();
    return row.read(count) ?? 0;
  }

  Stream<int> watchActiveCount(String userId) {
    final count = incubationsTable.id.count();
    return (selectOnly(incubationsTable)
          ..addColumns([count])
          ..where(
            incubationsTable.userId.equals(userId) &
                incubationsTable.status.equalsValue(IncubationStatus.active),
          ))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  Future<List<Incubation>> getByBreedingPair(String pairId) async {
    final rows =
        await (select(incubationsTable)
              ..where((t) => t.breedingPairId.equals(pairId))
              ..orderBy([
                (t) => OrderingTerm.desc(t.startDate),
                (t) => OrderingTerm.desc(t.createdAt),
              ]))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  Stream<List<Incubation>> watchByBreedingPair(String pairId) {
    return (select(incubationsTable)
          ..where((t) => t.breedingPairId.equals(pairId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.startDate),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Future<List<Incubation>> getByBreedingPairIds(List<String> pairIds) async {
    if (pairIds.isEmpty) return [];
    final rows =
        await (select(incubationsTable)
              ..where((t) => t.breedingPairId.isIn(pairIds))
              ..orderBy([
                (t) => OrderingTerm.desc(t.startDate),
                (t) => OrderingTerm.desc(t.createdAt),
              ]))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }
}
