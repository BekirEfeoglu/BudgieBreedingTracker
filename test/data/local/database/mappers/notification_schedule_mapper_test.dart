import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/notification_schedule_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/notification_schedule_model.dart';

void main() {
  final scheduledAt = DateTime.utc(2024, 6, 15, 9, 0);
  final processedAt = DateTime.utc(2024, 6, 15, 9, 5);

  group('NotificationScheduleRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      final row = NotificationScheduleRow(
        id: 'ns1',
        userId: 'u1',
        type: NotificationType.eggTurning,
        title: 'Turn eggs',
        message: 'Time to turn eggs in nest A',
        scheduledAt: scheduledAt,
        isActive: true,
        isRecurring: true,
        intervalMinutes: 480,
        relatedEntityId: 'e1',
        priority: NotificationPriority.high,
        metadata: '{"nest":"A"}',
        processedAt: processedAt,
        createdAt: DateTime.utc(2024, 6, 1),
        updatedAt: DateTime.utc(2024, 6, 2),
      );
      final model = row.toModel();

      expect(model.id, 'ns1');
      expect(model.userId, 'u1');
      expect(model.type, NotificationType.eggTurning);
      expect(model.title, 'Turn eggs');
      expect(model.message, 'Time to turn eggs in nest A');
      expect(model.scheduledAt, scheduledAt);
      expect(model.isActive, true);
      expect(model.isRecurring, true);
      expect(model.intervalMinutes, 480);
      expect(model.relatedEntityId, 'e1');
      expect(model.priority, NotificationPriority.high);
      expect(model.metadata, '{"nest":"A"}');
      expect(model.processedAt, processedAt);
    });

    test('handles null optional fields', () {
      final row = NotificationScheduleRow(
        id: 'ns2',
        userId: 'u1',
        type: NotificationType.custom,
        title: 'Custom',
        message: null,
        scheduledAt: scheduledAt,
        isActive: false,
        isRecurring: false,
        intervalMinutes: null,
        relatedEntityId: null,
        priority: NotificationPriority.normal,
        metadata: null,
        processedAt: null,
      );
      final model = row.toModel();

      expect(model.message, isNull);
      expect(model.intervalMinutes, isNull);
      expect(model.relatedEntityId, isNull);
      expect(model.metadata, isNull);
      expect(model.processedAt, isNull);
      expect(model.isActive, false);
    });
  });

  group('NotificationScheduleModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      final model = NotificationSchedule(
        id: 'ns1',
        userId: 'u1',
        type: NotificationType.feedingReminder,
        title: 'Feed birds',
        message: 'Morning feeding',
        scheduledAt: scheduledAt,
        isActive: true,
        isRecurring: true,
        intervalMinutes: 720,
        relatedEntityId: 'b1',
        priority: NotificationPriority.high,
        metadata: '{}',
        processedAt: processedAt,
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'ns1');
      expect(companion.userId.value, 'u1');
      expect(companion.type.value, NotificationType.feedingReminder);
      expect(companion.title.value, 'Feed birds');
      expect(companion.message.value, 'Morning feeding');
      expect(companion.scheduledAt.value, scheduledAt);
      expect(companion.isActive.value, true);
      expect(companion.isRecurring.value, true);
      expect(companion.intervalMinutes.value, 720);
      expect(companion.relatedEntityId.value, 'b1');
      expect(companion.priority.value, NotificationPriority.high);
      expect(companion.metadata.value, '{}');
      expect(companion.processedAt.value, processedAt);
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      final model = NotificationSchedule(
        id: 'ns1',
        userId: 'u1',
        type: NotificationType.custom,
        title: 'Test',
        scheduledAt: scheduledAt,
      );
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
