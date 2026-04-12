import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/breeding_pairs_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/breeding_pair_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';

part 'breeding_pairs_dao.g.dart';

@DriftAccessor(tables: [BreedingPairsTable])
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
    return (select(breedingPairsTable)..where((t) => t.id.equals(id)))
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
    final row = await (selectOnly(breedingPairsTable)
          ..addColumns([count])
          ..where(
            breedingPairsTable.userId.equals(userId) &
                breedingPairsTable.isDeleted.equals(false) &
                (breedingPairsTable.status.equalsValue(BreedingStatus.active) |
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

  /// Watches active (non-deleted) breeding pairs for a user.
  Stream<List<BreedingPair>> watchActive(String userId) {
    return (select(breedingPairsTable)..where(
          (t) =>
              t.userId.equals(userId) &
              t.isDeleted.equals(false) &
              t.status.equalsValue(BreedingStatus.active),
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
}
