import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';

extension EggRowMapper on EggRow {
  Egg toModel() => Egg(
    id: id,
    layDate: layDate,
    userId: userId,
    status: status,
    clutchId: clutchId,
    incubationId: incubationId,
    eggNumber: eggNumber,
    notes: notes,
    photoUrl: photoUrl,
    hatchDate: hatchDate,
    fertileCheckDate: fertileCheckDate,
    discardDate: discardDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
    isDeleted: isDeleted,
  );
}

extension EggModelMapper on Egg {
  EggsTableCompanion toCompanion() => EggsTableCompanion(
    id: Value(id),
    layDate: Value(layDate),
    userId: Value(userId),
    status: Value(status),
    clutchId: Value(clutchId),
    incubationId: Value(incubationId),
    eggNumber: Value(eggNumber),
    notes: Value(notes),
    photoUrl: Value(photoUrl),
    hatchDate: Value(hatchDate),
    fertileCheckDate: Value(fertileCheckDate),
    discardDate: Value(discardDate),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt ?? DateTime.now()),
    isDeleted: Value(isDeleted),
  );
}
