import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/core/enums/photo_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/photos_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/photo_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';

part 'photos_dao.g.dart';

@DriftAccessor(tables: [PhotosTable])
class PhotosDao extends DatabaseAccessor<AppDatabase> with _$PhotosDaoMixin {
  PhotosDao(super.db);

  Stream<List<Photo>> watchAll(String userId) {
    return (select(photosTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Stream<List<Photo>> watchByEntity(String entityId) {
    return (select(photosTable)..where((t) => t.entityId.equals(entityId)))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Future<List<Photo>> getAll(String userId) async {
    final rows = await (select(
      photosTable,
    )..where((t) => t.userId.equals(userId))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<Photo?> getById(String id) async {
    final row = await (select(
      photosTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  Future<List<Photo>> getByEntity(String entityId) async {
    final rows = await (select(
      photosTable,
    )..where((t) => t.entityId.equals(entityId))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<List<Photo>> getByEntityType(
    String userId,
    PhotoEntityType entityType,
  ) async {
    final rows =
        await (select(photosTable)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.entityType.equalsValue(entityType),
            ))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<void> insertItem(Photo model) {
    return into(photosTable).insertOnConflictUpdate(model.toCompanion());
  }

  Future<void> insertAll(List<Photo> models) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        photosTable,
        models.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  Future<void> hardDelete(String id) {
    return (delete(photosTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteByEntity(String entityId) {
    return (delete(
      photosTable,
    )..where((t) => t.entityId.equals(entityId))).go();
  }
}
