import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/data/models/notification_schedule_model.dart';

void main() {
  group('AppNotification model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final notification = AppNotification(
          id: 'notification-1',
          title: 'Egg turning reminder',
          read: true,
          type: NotificationType.eggTurning,
          priority: NotificationPriority.high,
          body: 'Turn eggs now',
          userId: 'user-1',
          referenceId: 'incubation-1',
          referenceType: 'incubation',
          scheduledAt: DateTime(2024, 1, 1, 8, 0),
          readAt: DateTime(2024, 1, 1, 8, 5),
          createdAt: DateTime(2024, 1, 1, 7, 0),
          updatedAt: DateTime(2024, 1, 1, 7, 30),
        );

        final restored = AppNotification.fromJson(notification.toJson());

        expect(restored.id, notification.id);
        expect(restored.title, notification.title);
        expect(restored.read, notification.read);
        expect(restored.type, notification.type);
        expect(restored.priority, notification.priority);
        expect(restored.body, notification.body);
        expect(restored.userId, notification.userId);
        expect(restored.referenceId, notification.referenceId);
        expect(restored.referenceType, notification.referenceType);
        expect(restored.scheduledAt, notification.scheduledAt);
        expect(restored.readAt, notification.readAt);
        expect(restored.createdAt, notification.createdAt);
        expect(restored.updatedAt, notification.updatedAt);
      });

      test('applies default values', () {
        final notification = AppNotification.fromJson({
          'id': 'notification-1',
          'title': 'Simple',
          'user_id': 'user-1',
        });

        expect(notification.read, isFalse);
        expect(notification.type, NotificationType.custom);
        expect(notification.priority, NotificationPriority.normal);
      });

      test('falls back to default enums for unknown values', () {
        final notification = AppNotification.fromJson({
          'id': 'notification-1',
          'title': 'Simple',
          'user_id': 'user-1',
          'type': 'invalid-type',
          'priority': 'invalid-priority',
        });

        expect(notification.type, NotificationType.custom);
        expect(notification.priority, NotificationPriority.normal);
      });
    });
  });

  group('NotificationSettings model', () {
    test('applies documented defaults', () {
      final settings = NotificationSettings.fromJson({
        'id': 'settings-1',
        'user_id': 'user-1',
      });

      expect(settings.language, 'tr');
      expect(settings.soundEnabled, isTrue);
      expect(settings.vibrationEnabled, isTrue);
      expect(settings.eggTurningEnabled, isTrue);
      expect(settings.temperatureAlertEnabled, isTrue);
      expect(settings.humidityAlertEnabled, isTrue);
      expect(settings.feedingReminderEnabled, isTrue);
      expect(settings.incubationReminderEnabled, isTrue);
      expect(settings.healthCheckEnabled, isTrue);
      expect(settings.temperatureMin, 37.0);
      expect(settings.temperatureMax, 38.0);
      expect(settings.humidityMin, 55.0);
      expect(settings.humidityMax, 65.0);
      expect(settings.eggTurningIntervalMinutes, 480);
      expect(settings.feedingReminderIntervalMinutes, 1440);
      expect(settings.temperatureCheckIntervalMinutes, 60);
    });
  });

  group('NotificationSchedule relationship', () {
    test('shares compatible enum serialization with AppNotification', () {
      final schedule = NotificationSchedule(
        id: 'schedule-1',
        userId: 'user-1',
        type: NotificationType.feedingReminder,
        title: 'Feed chicks',
        scheduledAt: DateTime(2024, 1, 1, 12, 0),
        priority: NotificationPriority.critical,
      );

      final scheduleJson = schedule.toJson();
      final notification = AppNotification.fromJson({
        'id': 'notification-1',
        'title': 'Feed chicks',
        'user_id': 'user-1',
        'type': scheduleJson['type'],
        'priority': scheduleJson['priority'],
      });

      expect(notification.type, NotificationType.feedingReminder);
      expect(notification.priority, NotificationPriority.critical);
    });
  });
}
