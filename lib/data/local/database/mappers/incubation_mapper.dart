import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';

extension IncubationRowMapper on IncubationRow {
  Incubation toModel() => Incubation(
    id: id,
    userId: userId,
    status: status,
    version: version,
    clutchId: clutchId,
    breedingPairId: breedingPairId,
    notes: notes,
    startDate: startDate,
    endDate: endDate,
    expectedHatchDate: expectedHatchDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension IncubationModelMapper on Incubation {
  IncubationsTableCompanion toCompanion() => IncubationsTableCompanion(
    id: Value(id),
    userId: Value(userId),
    status: Value(status),
    version: Value(version),
    clutchId: Value(clutchId),
    breedingPairId: Value(breedingPairId),
    notes: Value(notes),
    startDate: Value(startDate),
    endDate: Value(endDate),
    expectedHatchDate: Value(expectedHatchDate),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt ?? DateTime.now()),
  );
}
