import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/notification_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';

void main() {
  group('NotificationRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      final scheduledAt = DateTime(2024, 5, 1, 10, 0);
      final row = NotificationRow(
        id: 'n1',
        title: 'Egg turning',
        read: false,
        type: NotificationType.eggTurning,
        priority: NotificationPriority.high,
        body: 'Time to turn eggs',
        userId: 'u1',
        referenceId: 'e1',
        referenceType: 'egg',
        scheduledAt: scheduledAt,
        readAt: null,
      );
      final model = row.toModel();

      expect(model.id, 'n1');
      expect(model.title, 'Egg turning');
      expect(model.read, false);
      expect(model.type, NotificationType.eggTurning);
      expect(model.priority, NotificationPriority.high);
      expect(model.body, 'Time to turn eggs');
      expect(model.userId, 'u1');
      expect(model.referenceId, 'e1');
      expect(model.referenceType, 'egg');
      expect(model.scheduledAt, scheduledAt);
    });

    test('maps userId directly', () {
      const row = NotificationRow(
        id: 'n2',
        title: 'System',
        read: false,
        type: NotificationType.custom,
        priority: NotificationPriority.normal,
        userId: 'u2',
      );
      final model = row.toModel();

      expect(model.userId, 'u2');
    });
  });

  group('NotificationModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      const model = AppNotification(
        id: 'n1',
        title: 'Reminder',
        read: true,
        type: NotificationType.healthCheck,
        priority: NotificationPriority.normal,
        body: 'Check bird health',
        userId: 'u1',
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'n1');
      expect(companion.title.value, 'Reminder');
      expect(companion.read.value, true);
      expect(companion.type.value, NotificationType.healthCheck);
      expect(companion.priority.value, NotificationPriority.normal);
      expect(companion.body.value, 'Check bird health');
      expect(companion.userId.value, 'u1');
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      const model = AppNotification(id: 'n1', title: 'Test', userId: 'u1');
      final companion = model.toCompanion();

      expect(
        companion.updatedAt.value!.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });
  });
}
