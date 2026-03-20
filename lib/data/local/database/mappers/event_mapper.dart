import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';

extension EventRowMapper on EventRow {
  Event toModel() => Event(
    id: id,
    title: title,
    eventDate: eventDate,
    type: type,
    userId: userId,
    status: status,
    description: description,
    birdId: birdId,
    breedingPairId: breedingPairId,
    notes: notes,
    endDate: endDate,
    reminderDate: reminderDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
    isDeleted: isDeleted,
  );
}

extension EventModelMapper on Event {
  EventsTableCompanion toCompanion() => EventsTableCompanion(
    id: Value(id),
    title: Value(title),
    eventDate: Value(eventDate),
    type: Value(type),
    userId: Value(userId),
    status: Value(status),
    description: Value(description),
    birdId: Value(birdId),
    breedingPairId: Value(breedingPairId),
    notes: Value(notes),
    endDate: Value(endDate),
    reminderDate: Value(reminderDate),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt ?? DateTime.now()),
    isDeleted: Value(isDeleted),
  );
}
