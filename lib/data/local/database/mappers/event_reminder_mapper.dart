import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/event_reminder_model.dart';

extension EventReminderRowMapper on EventReminderRow {
  EventReminder toModel() => EventReminder(
    id: id,
    userId: userId,
    eventId: eventId,
    minutesBefore: minutesBefore,
    type: type,
    isSent: isSent,
    isDeleted: isDeleted,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension EventReminderModelMapper on EventReminder {
  EventRemindersTableCompanion toCompanion() => EventRemindersTableCompanion(
    id: Value(id),
    userId: Value(userId),
    eventId: Value(eventId),
    minutesBefore: Value(minutesBefore),
    type: Value(type),
    isSent: Value(isSent),
    isDeleted: Value(isDeleted),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt ?? DateTime.now()),
  );
}
