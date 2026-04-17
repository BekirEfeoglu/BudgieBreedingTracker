import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';

extension ClutchRowMapper on ClutchRow {
  Clutch toModel() => Clutch(
    id: id,
    userId: userId,
    name: name,
    breedingId: breedingId,
    incubationId: incubationId,
    maleBirdId: maleBirdId,
    femaleBirdId: femaleBirdId,
    nestId: nestId,
    pairDate: pairDate?.toUtc(),
    startDate: startDate?.toUtc(),
    endDate: endDate?.toUtc(),
    status: status,
    notes: notes,
    isDeleted: isDeleted,
    createdAt: createdAt?.toUtc(),
    updatedAt: updatedAt?.toUtc(),
  );
}

extension ClutchModelMapper on Clutch {
  ClutchesTableCompanion toCompanion() => ClutchesTableCompanion(
    id: Value(id),
    userId: Value(userId),
    name: Value(name),
    breedingId: Value(breedingId),
    incubationId: Value(incubationId),
    maleBirdId: Value(maleBirdId),
    femaleBirdId: Value(femaleBirdId),
    nestId: Value(nestId),
    pairDate: Value(pairDate?.toUtc()),
    startDate: Value(startDate?.toUtc()),
    endDate: Value(endDate?.toUtc()),
    status: Value(status),
    notes: Value(notes),
    isDeleted: Value(isDeleted),
    createdAt: Value(createdAt?.toUtc()),
    updatedAt: Value((updatedAt ?? DateTime.now()).toUtc()),
  );
}
