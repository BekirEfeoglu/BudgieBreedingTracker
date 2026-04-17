import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';

extension BreedingPairRowMapper on BreedingPairRow {
  BreedingPair toModel() => BreedingPair(
    id: id,
    userId: userId,
    status: status,
    maleId: maleId,
    femaleId: femaleId,
    cageNumber: cageNumber,
    notes: notes,
    pairingDate: pairingDate?.toUtc(),
    separationDate: separationDate?.toUtc(),
    createdAt: createdAt?.toUtc(),
    updatedAt: updatedAt?.toUtc(),
    isDeleted: isDeleted,
  );
}

extension BreedingPairModelMapper on BreedingPair {
  BreedingPairsTableCompanion toCompanion() => BreedingPairsTableCompanion(
    id: Value(id),
    userId: Value(userId),
    status: Value(status),
    maleId: Value(maleId),
    femaleId: Value(femaleId),
    cageNumber: Value(cageNumber),
    notes: Value(notes),
    pairingDate: Value(pairingDate?.toUtc()),
    separationDate: Value(separationDate?.toUtc()),
    createdAt: Value(createdAt?.toUtc()),
    updatedAt: Value((updatedAt ?? DateTime.now()).toUtc()),
    isDeleted: Value(isDeleted),
  );
}
