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
    bandingDate: bandingDate,
    notes: notes,
    photoUrl: photoUrl,
    hatchWeight: hatchWeight,
    hatchDate: hatchDate,
    weanDate: weanDate,
    deathDate: deathDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
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
    bandingDate: Value(bandingDate),
    notes: Value(notes),
    photoUrl: Value(photoUrl),
    hatchWeight: Value(hatchWeight),
    hatchDate: Value(hatchDate),
    weanDate: Value(weanDate),
    deathDate: Value(deathDate),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt ?? DateTime.now()),
    isDeleted: Value(isDeleted),
  );
}
