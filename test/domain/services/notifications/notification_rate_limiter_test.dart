import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rate_limiter.dart';

void main() {
  late NotificationRateLimiter limiter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    limiter = NotificationRateLimiter();
    // Disable DND to prevent time-dependent test failures
    await limiter.setDndHours(startHour: 0, endHour: 0);
  });

  group('NotificationRateLimiter', () {
    test('recordSent increments recent count and reset clears it', () {
      expect(limiter.getRecentCount('egg_turning', 'user-1'), 0);
      limiter.recordSent('egg_turning', 'user-1');
      expect(limiter.getRecentCount('egg_turning', 'user-1'), 1);

      limiter.reset();
      expect(limiter.getRecentCount('egg_turning', 'user-1'), 0);
    });

    test('isDoNotDisturbActive returns false when DND is disabled', () {
      expect(limiter.isDoNotDisturbActive(), isFalse);
    });

    test(
      'isDoNotDisturbActive returns true when current hour is in DND window',
      () async {
        final currentHour = DateTime.now().hour;
        // Create a 1-hour DND window guaranteed to include the current hour
        await limiter.setDndHours(
          startHour: currentHour,
          endHour: (currentHour + 1) % 24,
        );
        expect(limiter.isDoNotDisturbActive(), isTrue);
      },
    );

    test('canSend respects hourly per-type limit', () {
      expect(limiter.canSend('health_check', 'user-1'), isTrue);

      limiter.recordSent('health_check', 'user-1');
      expect(limiter.canSend('health_check', 'user-1'), isFalse);
      expect(limiter.canSend('other_type', 'user-1'), isTrue);
    });

    test('canSend blocks when DND is active', () async {
      final currentHour = DateTime.now().hour;
      await limiter.setDndHours(
        startHour: currentHour,
        endHour: (currentHour + 1) % 24,
      );
      expect(limiter.canSend('health_check', 'user-1'), isFalse);
    });
  });
}
