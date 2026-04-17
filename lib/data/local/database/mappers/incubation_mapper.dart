import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';

extension IncubationRowMapper on IncubationRow {
  Incubation toModel() => Incubation(
    id: id,
    userId: userId,
    species: species,
    status: status,
    version: version,
    clutchId: clutchId,
    breedingPairId: breedingPairId,
    notes: notes,
    startDate: startDate?.toUtc(),
    endDate: endDate?.toUtc(),
    expectedHatchDate: expectedHatchDate?.toUtc(),
    createdAt: createdAt?.toUtc(),
    updatedAt: updatedAt?.toUtc(),
  );
}

extension IncubationModelMapper on Incubation {
  IncubationsTableCompanion toCompanion() => IncubationsTableCompanion(
    id: Value(id),
    userId: Value(userId),
    species: Value(species),
    status: Value(status),
    version: Value(version),
    clutchId: Value(clutchId),
    breedingPairId: Value(breedingPairId),
    notes: Value(notes),
    startDate: Value(startDate?.toUtc()),
    endDate: Value(endDate?.toUtc()),
    expectedHatchDate: Value(expectedHatchDate?.toUtc()),
    createdAt: Value(createdAt?.toUtc()),
    updatedAt: Value((updatedAt ?? DateTime.now()).toUtc()),
  );
}
