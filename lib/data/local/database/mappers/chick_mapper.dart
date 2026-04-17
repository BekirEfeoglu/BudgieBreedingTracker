import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';

extension ChickRowMapper on ChickRow {
  Chick toModel() => Chick(
    id: id,
    userId: userId,
    gender: gender,
    healthStatus: healthStatus,
    clutchId: clutchId,
    eggId: eggId,
    birdId: birdId,
    name: name,
    ringNumber: ringNumber,
    bandingDay: bandingDay,
    bandingDate: bandingDate?.toUtc(),
    notes: notes,
    photoUrl: photoUrl,
    hatchWeight: hatchWeight,
    hatchDate: hatchDate?.toUtc(),
    weanDate: weanDate?.toUtc(),
    deathDate: deathDate?.toUtc(),
    createdAt: createdAt?.toUtc(),
    updatedAt: updatedAt?.toUtc(),
    isDeleted: isDeleted,
  );
}

extension ChickModelMapper on Chick {
  ChicksTableCompanion toCompanion() => ChicksTableCompanion(
    id: Value(id),
    userId: Value(userId),
    gender: Value(gender),
    healthStatus: Value(healthStatus),
    clutchId: Value(clutchId),
    eggId: Value(eggId),
    birdId: Value(birdId),
    name: Value(name),
    ringNumber: Value(ringNumber),
    bandingDay: Value(bandingDay),
    bandingDate: Value(bandingDate?.toUtc()),
    notes: Value(notes),
    photoUrl: Value(photoUrl),
    hatchWeight: Value(hatchWeight),
    hatchDate: Value(hatchDate?.toUtc()),
    weanDate: Value(weanDate?.toUtc()),
    deathDate: Value(deathDate?.toUtc()),
    createdAt: Value(createdAt?.toUtc()),
    updatedAt: Value((updatedAt ?? DateTime.now()).toUtc()),
    isDeleted: Value(isDeleted),
  );
}
