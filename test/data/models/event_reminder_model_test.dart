import 'package:budgie_breeding_tracker/core/enums/reminder_enums.dart';
import 'package:budgie_breeding_tracker/data/models/event_reminder_model.dart';
import 'package:flutter_test/flutter_test.dart';

EventReminder _buildReminder({
  String id = 'reminder-1',
  String userId = 'user-1',
  String eventId = 'event-1',
  int minutesBefore = 45,
  ReminderType type = ReminderType.push,
  bool isSent = true,
  bool isDeleted = true,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return EventReminder(
    id: id,
    userId: userId,
    eventId: eventId,
    minutesBefore: minutesBefore,
    type: type,
    isSent: isSent,
    isDeleted: isDeleted,
    createdAt: createdAt ?? DateTime(2024, 1, 1, 8, 0),
    updatedAt: updatedAt ?? DateTime(2024, 1, 1, 9, 0),
  );
}

void main() {
  group('EventReminder model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final reminder = _buildReminder();

        final restored = EventReminder.fromJson(reminder.toJson());
        expect(restored, reminder);
      });

      test('applies documented defaults', () {
        final reminder = EventReminder.fromJson({
          'id': 'reminder-1',
          'user_id': 'user-1',
          'event_id': 'event-1',
        });

        expect(reminder.minutesBefore, 30);
        expect(reminder.type, ReminderType.notification);
        expect(reminder.isSent, isFalse);
        expect(reminder.isDeleted, isFalse);
      });

      test('maps unknown enum values to ReminderType.unknown', () {
        final reminder = EventReminder.fromJson({
          'id': 'reminder-1',
          'user_id': 'user-1',
          'event_id': 'event-1',
          'type': 'invalid',
        });

        expect(reminder.type, ReminderType.unknown);
      });
    });

    group('copyWith', () {
      test('updates selected fields and preserves others', () {
        final original = _buildReminder(
          minutesBefore: 30,
          type: ReminderType.notification,
          isSent: false,
        );
        final updated = original.copyWith(
          minutesBefore: 15,
          type: ReminderType.email,
          isSent: true,
        );

        expect(updated.minutesBefore, 15);
        expect(updated.type, ReminderType.email);
        expect(updated.isSent, isTrue);
        expect(updated.id, original.id);
        expect(updated.eventId, original.eventId);
      });
    });
  });
}
