import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/growth_measurements_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/growth_measurement_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';

part 'growth_measurements_dao.g.dart';

@DriftAccessor(tables: [GrowthMeasurementsTable])
class GrowthMeasurementsDao extends DatabaseAccessor<AppDatabase>
    with _$GrowthMeasurementsDaoMixin {
  GrowthMeasurementsDao(super.db);

  Stream<List<GrowthMeasurement>> watchAll(String userId) {
    return (select(growthMeasurementsTable)
          ..where((t) => t.userId.equals(userId)))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Stream<GrowthMeasurement?> watchById(String id) {
    return (select(growthMeasurementsTable)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  Future<List<GrowthMeasurement>> getAll(String userId) async {
    final rows = await (select(growthMeasurementsTable)
          ..where((t) => t.userId.equals(userId)))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<GrowthMeasurement?> getById(String id) async {
    final row = await (select(growthMeasurementsTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toModel();
  }

  Future<void> insertItem(GrowthMeasurement measurement) {
    return into(growthMeasurementsTable)
        .insertOnConflictUpdate(measurement.toCompanion());
  }

  Future<void> insertAll(List<GrowthMeasurement> measurements) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        growthMeasurementsTable,
        measurements.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  Future<void> updateItem(GrowthMeasurement measurement) {
    return update(growthMeasurementsTable).replace(measurement.toCompanion());
  }

  Future<void> hardDelete(String id) {
    return (delete(growthMeasurementsTable)..where((t) => t.id.equals(id)))
        .go();
  }

  Stream<List<GrowthMeasurement>> watchByChick(String chickId) {
    return (select(growthMeasurementsTable)
          ..where((t) => t.chickId.equals(chickId))
          ..orderBy([(t) => OrderingTerm.asc(t.measurementDate)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Future<GrowthMeasurement?> getLatest(String chickId) async {
    final row = await (select(growthMeasurementsTable)
          ..where((t) => t.chickId.equals(chickId))
          ..orderBy([(t) => OrderingTerm.desc(t.measurementDate)])
          ..limit(1))
        .getSingleOrNull();
    return row?.toModel();
  }
}
