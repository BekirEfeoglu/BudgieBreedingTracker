import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';

extension NotificationRowMapper on NotificationRow {
  AppNotification toModel() => AppNotification(
        id: id,
        title: title,
        read: read,
        type: type,
        priority: priority,
        body: body,
        userId: userId,
        referenceId: referenceId,
        referenceType: referenceType,
        scheduledAt: scheduledAt,
        readAt: readAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension NotificationModelMapper on AppNotification {
  NotificationsTableCompanion toCompanion() => NotificationsTableCompanion(
        id: Value(id),
        title: Value(title),
        read: Value(read),
        type: Value(type),
        priority: Value(priority),
        body: Value(body),
        userId: Value(userId),
        referenceId: Value(referenceId),
        referenceType: Value(referenceType),
        scheduledAt: Value(scheduledAt),
        readAt: Value(readAt),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt ?? DateTime.now()),
      );
}
