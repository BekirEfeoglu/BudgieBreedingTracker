import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/nest_model.dart';

extension NestRowMapper on NestRow {
  Nest toModel() => Nest(
        id: id,
        userId: userId,
        name: name,
        location: location,
        status: status,
        notes: notes,
        isDeleted: isDeleted,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension NestModelMapper on Nest {
  NestsTableCompanion toCompanion() => NestsTableCompanion(
        id: Value(id),
        userId: Value(userId),
        name: Value(name),
        location: Value(location),
        status: Value(status),
        notes: Value(notes),
        isDeleted: Value(isDeleted),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt ?? DateTime.now()),
      );
}
