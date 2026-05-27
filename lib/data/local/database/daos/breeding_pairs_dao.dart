import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/breeding_pairs_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/incubations_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/breeding_pair_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';

part 'breeding_pairs_dao.g.dart';

@DriftAccessor(tables: [BreedingPairsTable, IncubationsTable])
class BreedingPairsDao extends DatabaseAccessor<AppDatabase>
    with _$BreedingPairsDaoMixin {
  BreedingPairsDao(super.db);

  /// Watches all non-deleted breeding pairs for a user.
  Stream<List<BreedingPair>> watchAll(String userId) {
    return (select(breedingPairsTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  /// Watches a single breeding pair by id.
  Stream<BreedingPair?> watchById(String id) {
    return (select(breedingPairsTable)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  /// Gets all non-deleted breeding pairs for a user.
  Future<List<BreedingPair>> getAll(String userId) async {
    final rows = await (select(
      breedingPairsTable,
    )..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Gets a single breeding pair by id.
  Future<BreedingPair?> getById(String id) async {
    final row =
        await (select(breedingPairsTable)
              ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
            .getSingleOrNull();
    return row?.toModel();
  }

  Future<BreedingPair?> getByIdIncludingDeleted(String id) async {
    final row = await (select(
      breedingPairsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  /// Inserts or updates a breeding pair.
  Future<void> insertItem(BreedingPair model) {
    return into(breedingPairsTable).insertOnConflictUpdate(model.toCompanion());
  }

  /// Batch inserts breeding pairs.
  Future<void> insertAll(List<BreedingPair> models) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        breedingPairsTable,
        models.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  /// Updates a breeding pair.
  Future<bool> updateItem(BreedingPair model) {
    return update(breedingPairsTable).replace(model.toCompanion());
  }

  /// Soft-deletes a breeding pair by setting isDeleted to true.
  Future<void> softDelete(String id) {
    return (update(breedingPairsTable)..where((t) => t.id.equals(id))).write(
      BreedingPairsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Permanently deletes a breeding pair.
  Future<int> hardDelete(String id) {
    return (delete(breedingPairsTable)..where((t) => t.id.equals(id))).go();
  }

  /// One-shot count of active + ongoing breeding pairs.
  Future<int> getActiveCount(String userId) async {
    final count = breedingPairsTable.id.count();
    final row =
        await (selectOnly(breedingPairsTable)
              ..addColumns([count])
              ..where(
                breedingPairsTable.userId.equals(userId) &
                    breedingPairsTable.isDeleted.equals(false) &
                    (breedingPairsTable.status.equalsValue(
                          BreedingStatus.active,
                        ) |
                        breedingPairsTable.status.equalsValue(
                          BreedingStatus.ongoing,
                        )),
              ))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// Reactive count of active + ongoing breeding pairs (lightweight).
  Stream<int> watchActiveCount(String userId) {
    final count = breedingPairsTable.id.count();
    return (selectOnly(breedingPairsTable)
          ..addColumns([count])
          ..where(
            breedingPairsTable.userId.equals(userId) &
                breedingPairsTable.isDeleted.equals(false) &
                (breedingPairsTable.status.equalsValue(BreedingStatus.active) |
                    breedingPairsTable.status.equalsValue(
                      BreedingStatus.ongoing,
                    )),
          ))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  /// Watches active + ongoing (non-deleted) breeding pairs for a user.
  Stream<List<BreedingPair>> watchActive(String userId) {
    return (select(breedingPairsTable)..where(
          (t) =>
              t.userId.equals(userId) &
              t.isDeleted.equals(false) &
              (t.status.equalsValue(BreedingStatus.active) |
                  t.status.equalsValue(BreedingStatus.ongoing)),
        ))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  /// Gets breeding pairs where the given bird is either the male or female.
  Future<List<BreedingPair>> getByBirdId(String birdId) async {
    final rows =
        await (select(breedingPairsTable)..where(
              (t) =>
                  (t.maleId.equals(birdId) | t.femaleId.equals(birdId)) &
                  t.isDeleted.equals(false),
            ))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Active + ongoing breeding pairs with SQL LIMIT (for dashboard).
  Stream<List<BreedingPair>> watchActiveLimited(
    String userId, {
    int limit = 3,
  }) {
    return (select(breedingPairsTable)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.isDeleted.equals(false) &
                (t.status.equalsValue(BreedingStatus.active) |
                    t.status.equalsValue(BreedingStatus.ongoing)),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  /// Watches monthly breeding outcomes: `'YYYY-MM' → {completed, cancelled}`.
  ///
  /// Buckets non-deleted pairs by `COALESCE(separation_date, updated_at)`
  /// month and partitions by status. Mirrors the legacy provider's Dart
  /// loop with SQL `GROUP BY` so memory stays O(monthCount). Optional
  /// [species] filter joins through `incubations` to limit to pairs that
  /// have at least one incubation of that species.
  Stream<Map<String, ({int completed, int cancelled})>> watchMonthlyOutcomes(
    String userId, {
    String? species,
  }) {
    // EXISTS subquery beats DISTINCT join when filtering by species — the
    // pair-row count is small (~hundreds), the incubations table can grow
    // independently.
    final speciesClause = species == null
        ? ''
        : 'AND EXISTS (SELECT 1 FROM incubations i '
              'WHERE i.breeding_pair_id = p.id AND i.species = ?) ';
    final tables = <ResultSetImplementation>{breedingPairsTable};
    if (species != null) tables.add(incubationsTable);
    final query = customSelect(
      "SELECT strftime('%Y-%m', "
      "COALESCE(p.separation_date, p.updated_at), 'localtime') AS month, "
      'p.status AS status, '
      'COUNT(*) AS cnt '
      'FROM breeding_pairs p '
      'WHERE p.user_id = ? AND p.is_deleted = 0 '
      "AND p.status IN ('completed', 'cancelled') "
      'AND COALESCE(p.separation_date, p.updated_at) IS NOT NULL '
      '$speciesClause'
      'GROUP BY month, p.status '
      'ORDER BY month',
      variables: [
        Variable.withString(userId),
        if (species != null) Variable.withString(species),
      ],
      readsFrom: tables,
    );
    return query.watch().map((rows) {
      final result = <String, ({int completed, int cancelled})>{};
      for (final row in rows) {
        final month = row.read<String>('month');
        final status = row.read<String>('status');
        final count = row.read<int>('cnt');
        final current = result[month] ?? (completed: 0, cancelled: 0);
        result[month] = (
          completed: current.completed + (status == 'completed' ? count : 0),
          cancelled: current.cancelled + (status == 'cancelled' ? count : 0),
        );
      }
      return result;
    });
  }
}
