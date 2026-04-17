import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';

extension EggRowMapper on EggRow {
  Egg toModel() => Egg(
    id: id,
    layDate: layDate.toUtc(),
    userId: userId,
    status: status,
    clutchId: clutchId,
    incubationId: incubationId,
    eggNumber: eggNumber,
    notes: notes,
    photoUrl: photoUrl,
    hatchDate: hatchDate?.toUtc(),
    fertileCheckDate: fertileCheckDate?.toUtc(),
    discardDate: discardDate?.toUtc(),
    createdAt: createdAt?.toUtc(),
    updatedAt: updatedAt?.toUtc(),
    isDeleted: isDeleted,
  );
}

extension EggModelMapper on Egg {
  EggsTableCompanion toCompanion() => EggsTableCompanion(
    id: Value(id),
    layDate: Value(layDate.toUtc()),
    userId: Value(userId),
    status: Value(status),
    clutchId: Value(clutchId),
    incubationId: Value(incubationId),
    eggNumber: Value(eggNumber),
    notes: Value(notes),
    photoUrl: Value(photoUrl),
    hatchDate: Value(hatchDate?.toUtc()),
    fertileCheckDate: Value(fertileCheckDate?.toUtc()),
    discardDate: Value(discardDate?.toUtc()),
    createdAt: Value(createdAt?.toUtc()),
    updatedAt: Value((updatedAt ?? DateTime.now()).toUtc()),
    isDeleted: Value(isDeleted),
  );
}
