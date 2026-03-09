import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';

void main() {
  group('NotificationType', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in NotificationType.values) {
        expect(NotificationType.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(NotificationType.fromJson('invalid'), NotificationType.unknown);
      expect(NotificationType.fromJson(''), NotificationType.unknown);
    });

    test('has expected value count', () {
      expect(NotificationType.values.length, 8);
    });
  });

  group('NotificationPriority', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in NotificationPriority.values) {
        expect(NotificationPriority.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(
        NotificationPriority.fromJson('invalid'),
        NotificationPriority.unknown,
      );
      expect(
        NotificationPriority.fromJson('urgent'),
        NotificationPriority.unknown,
      );
    });

    test('has expected value count', () {
      expect(NotificationPriority.values.length, 5);
    });
  });
}
