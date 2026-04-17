import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';

extension HealthRecordRowMapper on HealthRecordRow {
  HealthRecord toModel() => HealthRecord(
    id: id,
    date: date.toUtc(),
    type: type,
    title: title,
    userId: userId,
    birdId: birdId,
    description: description,
    treatment: treatment,
    veterinarian: veterinarian,
    notes: notes,
    weight: weight,
    cost: cost,
    followUpDate: followUpDate?.toUtc(),
    createdAt: createdAt?.toUtc(),
    updatedAt: updatedAt?.toUtc(),
    isDeleted: isDeleted,
  );
}

extension HealthRecordModelMapper on HealthRecord {
  HealthRecordsTableCompanion toCompanion() => HealthRecordsTableCompanion(
    id: Value(id),
    date: Value(date.toUtc()),
    type: Value(type),
    title: Value(title),
    userId: Value(userId),
    birdId: Value(birdId),
    description: Value(description),
    treatment: Value(treatment),
    veterinarian: Value(veterinarian),
    notes: Value(notes),
    weight: Value(weight),
    cost: Value(cost),
    followUpDate: Value(followUpDate?.toUtc()),
    createdAt: Value(createdAt?.toUtc()),
    updatedAt: Value((updatedAt ?? DateTime.now()).toUtc()),
    isDeleted: Value(isDeleted),
  );
}
