import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/notification_schedule_model.dart';

extension NotificationScheduleRowMapper on NotificationScheduleRow {
  NotificationSchedule toModel() => NotificationSchedule(
    id: id,
    userId: userId,
    type: type,
    title: title,
    message: message,
    scheduledAt: scheduledAt.toUtc(),
    isActive: isActive,
    isRecurring: isRecurring,
    intervalMinutes: intervalMinutes,
    relatedEntityId: relatedEntityId,
    priority: priority,
    metadata: metadata,
    processedAt: processedAt?.toUtc(),
    createdAt: createdAt?.toUtc(),
    updatedAt: updatedAt?.toUtc(),
  );
}

extension NotificationScheduleModelMapper on NotificationSchedule {
  NotificationSchedulesTableCompanion toCompanion() =>
      NotificationSchedulesTableCompanion(
        id: Value(id),
        userId: Value(userId),
        type: Value(type),
        title: Value(title),
        message: Value(message),
        scheduledAt: Value(scheduledAt.toUtc()),
        isActive: Value(isActive),
        isRecurring: Value(isRecurring),
        intervalMinutes: Value(intervalMinutes),
        relatedEntityId: Value(relatedEntityId),
        priority: Value(priority),
        metadata: Value(metadata),
        processedAt: Value(processedAt?.toUtc()),
        createdAt: Value(createdAt?.toUtc()),
        updatedAt: Value((updatedAt ?? DateTime.now()).toUtc()),
      );
}
