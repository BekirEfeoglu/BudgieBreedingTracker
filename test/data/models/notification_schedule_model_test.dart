import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/data/models/notification_schedule_model.dart';
import 'package:flutter_test/flutter_test.dart';

NotificationSchedule _buildSchedule({
  String id = 'schedule-1',
  String userId = 'user-1',
  NotificationType type = NotificationType.healthCheck,
  String title = 'Health check reminder',
  String? message = 'Observe behavior',
  DateTime? scheduledAt,
  bool isActive = false,
  bool isRecurring = true,
  int? intervalMinutes = 120,
  String? relatedEntityId = 'bird-1',
  NotificationPriority priority = NotificationPriority.high,
  String? metadata = '{"source":"test"}',
  DateTime? processedAt,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return NotificationSchedule(
    id: id,
    userId: userId,
    type: type,
    title: title,
    message: message,
    scheduledAt: scheduledAt ?? DateTime(2024, 1, 1, 8, 0),
    isActive: isActive,
    isRecurring: isRecurring,
    intervalMinutes: intervalMinutes,
    relatedEntityId: relatedEntityId,
    priority: priority,
    metadata: metadata,
    processedAt: processedAt ?? DateTime(2024, 1, 1, 8, 5),
    createdAt: createdAt ?? DateTime(2024, 1, 1, 7, 0),
    updatedAt: updatedAt ?? DateTime(2024, 1, 1, 7, 30),
  );
}

void main() {
  group('NotificationSchedule model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final schedule = _buildSchedule();

        final restored = NotificationSchedule.fromJson(schedule.toJson());
        expect(restored, schedule);
      });

      test('applies documented defaults', () {
        final schedule = NotificationSchedule.fromJson({
          'id': 'schedule-1',
          'user_id': 'user-1',
          'type': 'custom',
          'title': 'Simple reminder',
          'scheduled_at': DateTime(2024, 1, 1, 8, 0).toIso8601String(),
        });

        expect(schedule.isActive, isTrue);
        expect(schedule.isRecurring, isFalse);
        expect(schedule.priority, NotificationPriority.normal);
      });

      test('falls back to safe enums for unknown values', () {
        final schedule = NotificationSchedule.fromJson({
          'id': 'schedule-1',
          'user_id': 'user-1',
          'type': 'invalid-type',
          'title': 'Simple reminder',
          'scheduled_at': DateTime(2024, 1, 1, 8, 0).toIso8601String(),
          'priority': 'invalid-priority',
        });

        expect(schedule.type, NotificationType.custom);
        expect(schedule.priority, NotificationPriority.normal);
      });
    });

    group('copyWith', () {
      test('updates selected fields and keeps remaining values', () {
        final original = _buildSchedule(
          title: 'Old title',
          isActive: true,
          priority: NotificationPriority.normal,
        );
        final updated = original.copyWith(
          title: 'New title',
          isActive: false,
          priority: NotificationPriority.critical,
        );

        expect(updated.title, 'New title');
        expect(updated.isActive, isFalse);
        expect(updated.priority, NotificationPriority.critical);
        expect(updated.id, original.id);
        expect(updated.scheduledAt, original.scheduledAt);
      });
    });
  });
}
