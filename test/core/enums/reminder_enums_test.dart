import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/reminder_enums.dart';

void main() {
  group('ReminderType', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in ReminderType.values) {
        expect(ReminderType.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(ReminderType.fromJson('invalid'), ReminderType.unknown);
      expect(ReminderType.fromJson(''), ReminderType.unknown);
      expect(ReminderType.fromJson('sms'), ReminderType.unknown);
    });

    test('has expected value count', () {
      expect(ReminderType.values.length, 4);
    });
  });
}
