import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';

extension EventRowMapper on EventRow {
  Event toModel() => Event(
    id: id,
    title: title,
    eventDate: eventDate.toUtc(),
    type: type,
    userId: userId,
    status: status,
    description: description,
    birdId: birdId,
    breedingPairId: breedingPairId,
    chickId: chickId,
    notes: notes,
    endDate: endDate?.toUtc(),
    reminderDate: reminderDate?.toUtc(),
    createdAt: createdAt?.toUtc(),
    updatedAt: updatedAt?.toUtc(),
    isDeleted: isDeleted,
  );
}

extension EventModelMapper on Event {
  EventsTableCompanion toCompanion() => EventsTableCompanion(
    id: Value(id),
    title: Value(title),
    eventDate: Value(eventDate.toUtc()),
    type: Value(type),
    userId: Value(userId),
    status: Value(status),
    description: Value(description),
    birdId: Value(birdId),
    breedingPairId: Value(breedingPairId),
    chickId: Value(chickId),
    notes: Value(notes),
    endDate: Value(endDate?.toUtc()),
    reminderDate: Value(reminderDate?.toUtc()),
    createdAt: Value(createdAt?.toUtc()),
    updatedAt: Value((updatedAt ?? DateTime.now()).toUtc()),
    isDeleted: Value(isDeleted),
  );
}
