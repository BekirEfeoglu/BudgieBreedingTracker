import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';

extension GrowthMeasurementRowMapper on GrowthMeasurementRow {
  GrowthMeasurement toModel() => GrowthMeasurement(
        id: id,
        chickId: chickId,
        weight: weight,
        measurementDate: measurementDate,
        userId: userId,
        height: height,
        wingLength: wingLength,
        tailLength: tailLength,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension GrowthMeasurementModelMapper on GrowthMeasurement {
  GrowthMeasurementsTableCompanion toCompanion() =>
      GrowthMeasurementsTableCompanion(
        id: Value(id),
        chickId: Value(chickId),
        weight: Value(weight),
        measurementDate: Value(measurementDate),
        userId: Value(userId),
        height: Value(height),
        wingLength: Value(wingLength),
        tailLength: Value(tailLength),
        notes: Value(notes),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt ?? DateTime.now()),
      );
}
