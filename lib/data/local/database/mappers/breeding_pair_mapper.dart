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
    pairingDate: pairingDate,
    separationDate: separationDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
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
    pairingDate: Value(pairingDate),
    separationDate: Value(separationDate),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt ?? DateTime.now()),
    isDeleted: Value(isDeleted),
  );
}
