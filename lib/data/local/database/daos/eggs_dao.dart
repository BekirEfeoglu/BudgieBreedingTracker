import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/eggs_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/incubations_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/egg_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';

part 'eggs_dao.g.dart';

@DriftAccessor(tables: [EggsTable, IncubationsTable])
class EggsDao extends DatabaseAccessor<AppDatabase> with _$EggsDaoMixin {
  EggsDao(super.db);

  Stream<List<Egg>> watchAll(String userId) {
    return (select(eggsTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Stream<Egg?> watchById(String id) {
    return (select(eggsTable)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  Future<List<Egg>> getAll(String userId) async {
    final rows = await (select(
      eggsTable,
    )..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<Egg?> getById(String id) async {
    final row =
        await (select(eggsTable)
              ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
            .getSingleOrNull();
    return row?.toModel();
  }

  Future<void> insertItem(Egg model) {
    return into(eggsTable).insertOnConflictUpdate(model.toCompanion());
  }

  Future<void> insertAll(List<Egg> models) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        eggsTable,
        models.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  Future<void> updateItem(Egg model) {
    return update(eggsTable).replace(model.toCompanion());
  }

  Future<void> softDelete(String id) {
    return (update(eggsTable)..where((t) => t.id.equals(id))).write(
      EggsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> hardDelete(String id) {
    return (delete(eggsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Reactive count of all non-deleted eggs for a user (lightweight).
  Stream<int> watchCount(String userId) {
    final count = eggsTable.id.count();
    return (selectOnly(eggsTable)
          ..addColumns([count])
          ..where(
            eggsTable.userId.equals(userId) & eggsTable.isDeleted.equals(false),
          ))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  /// Reactive count of incubating eggs for a user (lightweight).
  Stream<int> watchIncubatingCount(String userId) {
    final count = eggsTable.id.count();
    return (selectOnly(eggsTable)
          ..addColumns([count])
          ..where(
            eggsTable.userId.equals(userId) &
                eggsTable.status.equalsValue(EggStatus.incubating) &
                eggsTable.isDeleted.equals(false),
          ))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  /// Watches monthly egg production for statistics (SQL aggregate).
  ///
  /// Returns a map of `'YYYY-MM'` → count. Only non-deleted eggs are counted.
  Stream<Map<String, int>> watchMonthlyProduction(String userId) {
    final query = customSelect(
      "SELECT strftime('%Y-%m', lay_date) AS month, COUNT(*) AS cnt "
      'FROM eggs WHERE user_id = ? AND is_deleted = 0 '
      'GROUP BY month ORDER BY month',
      variables: [Variable.withString(userId)],
      readsFrom: {eggsTable},
    );
    return query.watch().map((rows) {
      final result = <String, int>{};
      for (final row in rows) {
        result[row.read<String>('month')] = row.read<int>('cnt');
      }
      return result;
    });
  }

  /// Watches monthly egg production filtered by species (SQL aggregate + JOIN).
  ///
  /// Joins eggs → incubations.species. Filters and aggregation run in SQL so
  /// memory stays O(monthCount), not O(eggCount). Previously this filter was
  /// applied in Dart after loading all eggs + incubations via stream providers.
  Stream<Map<String, int>> watchMonthlyProductionBySpecies(
    String userId,
    String species,
  ) {
    final query = customSelect(
      "SELECT strftime('%Y-%m', e.lay_date) AS month, COUNT(*) AS cnt "
      'FROM eggs e '
      'INNER JOIN incubations i ON e.incubation_id = i.id '
      'WHERE e.user_id = ? AND e.is_deleted = 0 '
      'AND i.is_deleted = 0 AND i.species = ? '
      'GROUP BY month ORDER BY month',
      variables: [Variable.withString(userId), Variable.withString(species)],
      readsFrom: {eggsTable, incubationsTable},
    );
    return query.watch().map((rows) {
      final result = <String, int>{};
      for (final row in rows) {
        result[row.read<String>('month')] = row.read<int>('cnt');
      }
      return result;
    });
  }

  Stream<List<Egg>> watchByClutch(String clutchId) {
    return (select(eggsTable)..where(
          (t) => t.clutchId.equals(clutchId) & t.isDeleted.equals(false),
        ))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Stream<List<Egg>> watchByIncubation(String incubationId) {
    return (select(eggsTable)
          ..where(
            (t) =>
                t.incubationId.equals(incubationId) & t.isDeleted.equals(false),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.eggNumber),
            (t) => OrderingTerm.asc(t.layDate),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Future<List<Egg>> getByIncubation(String incubationId) async {
    final rows =
        await (select(eggsTable)
              ..where(
                (t) =>
                    t.incubationId.equals(incubationId) &
                    t.isDeleted.equals(false),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.eggNumber),
                (t) => OrderingTerm.asc(t.layDate),
                (t) => OrderingTerm.asc(t.createdAt),
              ]))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<List<Egg>> getByIncubationIds(List<String> incubationIds) async {
    if (incubationIds.isEmpty) return [];
    final rows =
        await (select(eggsTable)..where(
              (t) =>
                  t.incubationId.isIn(incubationIds) &
                  t.isDeleted.equals(false),
            ))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<List<Egg>> getIncubating(String userId) async {
    final rows =
        await (select(eggsTable)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.status.equalsValue(EggStatus.incubating) &
                  t.isDeleted.equals(false),
            ))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Incubating eggs sorted by lay date with SQL LIMIT (for dashboard).
  Stream<List<Egg>> watchIncubatingLimited(String userId, {int limit = 3}) {
    return (select(eggsTable)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.status.equalsValue(EggStatus.incubating) &
                t.isDeleted.equals(false),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.layDate)])
          ..limit(limit))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }
}
