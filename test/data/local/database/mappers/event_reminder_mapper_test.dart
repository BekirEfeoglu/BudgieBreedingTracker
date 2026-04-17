import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/reminder_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/event_reminder_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/event_reminder_model.dart';

void main() {
  group('EventReminderRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      final row = EventReminderRow(
        id: 'er1',
        userId: 'u1',
        eventId: 'ev1',
        minutesBefore: 60,
        type: ReminderType.email,
        isSent: true,
        isDeleted: false,
        createdAt: DateTime.utc(2024, 4, 1),
        updatedAt: DateTime.utc(2024, 4, 2),
      );
      final model = row.toModel();

      expect(model.id, 'er1');
      expect(model.userId, 'u1');
      expect(model.eventId, 'ev1');
      expect(model.minutesBefore, 60);
      expect(model.type, ReminderType.email);
      expect(model.isSent, true);
      expect(model.isDeleted, false);
    });

    test('maps push type correctly', () {
      const row = EventReminderRow(
        id: 'er2',
        userId: 'u1',
        eventId: 'ev2',
        minutesBefore: 15,
        type: ReminderType.push,
        isSent: false,
        isDeleted: false,
      );
      final model = row.toModel();

      expect(model.type, ReminderType.push);
      expect(model.isSent, false);
      expect(model.minutesBefore, 15);
    });
  });

  group('EventReminderModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      const model = EventReminder(
        id: 'er1',
        userId: 'u1',
        eventId: 'ev1',
        minutesBefore: 30,
        type: ReminderType.notification,
        isSent: false,
        isDeleted: false,
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'er1');
      expect(companion.userId.value, 'u1');
      expect(companion.eventId.value, 'ev1');
      expect(companion.minutesBefore.value, 30);
      expect(companion.type.value, ReminderType.notification);
      expect(companion.isSent.value, false);
      expect(companion.isDeleted.value, false);
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      const model = EventReminder(id: 'er1', userId: 'u1', eventId: 'ev1');
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
