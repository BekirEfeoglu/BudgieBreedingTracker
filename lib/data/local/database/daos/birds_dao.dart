import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/birds_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/bird_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';

part 'birds_dao.g.dart';

@DriftAccessor(tables: [BirdsTable])
class BirdsDao extends DatabaseAccessor<AppDatabase> with _$BirdsDaoMixin {
  BirdsDao(super.db);

  Stream<List<Bird>> watchAll(String userId) {
    return (select(birdsTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Stream<Bird?> watchById(String id) {
    return (select(birdsTable)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  Future<List<Bird>> getAll(String userId) async {
    final rows = await (select(
      birdsTable,
    )..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<Bird?> getById(String id) async {
    final row = await (select(
      birdsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  Future<void> insertItem(Bird model) {
    return into(birdsTable).insertOnConflictUpdate(model.toCompanion());
  }

  Future<void> insertAll(List<Bird> models) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        birdsTable,
        models.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  Future<void> updateItem(Bird model) {
    return update(birdsTable).replace(model.toCompanion());
  }

  Future<void> softDelete(String id) {
    return (update(birdsTable)..where((t) => t.id.equals(id))).write(
      BirdsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> hardDelete(String id) {
    return (delete(birdsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Bird>> getByGender(String userId, BirdGender gender) async {
    final rows =
        await (select(birdsTable)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.gender.equalsValue(gender) &
                  t.isDeleted.equals(false),
            ))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Reactive count of all non-deleted birds for a user (lightweight).
  Stream<int> watchCount(String userId) {
    final count = birdsTable.id.count();
    return (selectOnly(birdsTable)
          ..addColumns([count])
          ..where(
            birdsTable.userId.equals(userId) &
                birdsTable.isDeleted.equals(false),
          ))
        .watchSingle()
        .map((row) => row.read(count) ?? 0);
  }

  /// Returns the count of non-deleted birds for a user (lightweight — no row mapping).
  Future<int> getCount(String userId) async {
    final count = birdsTable.id.count();
    final row = await (selectOnly(birdsTable)
          ..addColumns([count])
          ..where(
            birdsTable.userId.equals(userId) &
                birdsTable.isDeleted.equals(false),
          ))
        .getSingle();
    return row.read(count) ?? 0;
  }

  Future<List<Bird>> getDeleted(String userId) async {
    final rows = await (select(
      birdsTable,
    )..where((t) => t.userId.equals(userId) & t.isDeleted.equals(true))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Checks if a ring number already exists for a given user.
  ///
  /// When [excludeId] is provided the bird with that id is skipped
  /// (useful for update-form uniqueness validation).
  Future<bool> hasRingNumber(
    String userId,
    String ringNumber, {
    String? excludeId,
  }) async {
    final rows = await (select(birdsTable)
          ..where((t) {
            var condition = t.userId.equals(userId) &
                t.ringNumber.equals(ringNumber) &
                t.isDeleted.equals(false);
            if (excludeId != null) {
              condition = condition & t.id.equals(excludeId).not();
            }
            return condition;
          })
          ..limit(1))
        .get();
    return rows.isNotEmpty;
  }
}
