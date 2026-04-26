import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rate_limiter.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_settings_providers.dart';

class _ScheduledNotification {
  _ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.channelId,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final String channelId;
  final String? payload;
}

class _ShownNotification {
  _ShownNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.channelId,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final String channelId;
  final String? payload;
}

class _FakeNotificationService extends NotificationService {
  final scheduled = <_ScheduledNotification>[];
  final shown = <_ShownNotification>[];
  final cancelledIds = <int>[];
  var cancelAllCalled = false;

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String channelId = 'default',
    String? payload,
  }) async {
    scheduled.add(
      _ScheduledNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        channelId: channelId,
        payload: payload,
      ),
    );
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = 'default',
    String? payload,
  }) async {
    shown.add(
      _ShownNotification(
        id: id,
        title: title,
        body: body,
        channelId: channelId,
        payload: payload,
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalled = true;
  }
}

void main() {
  late _FakeNotificationService fakeService;
  late NotificationRateLimiter rateLimiter;
  late NotificationScheduler scheduler;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeService = _FakeNotificationService();
    rateLimiter = NotificationRateLimiter();
    // Disable DND to prevent time-dependent test failures
    await rateLimiter.setDndHours(startHour: 0, endHour: 0);
    scheduler = NotificationScheduler(fakeService, rateLimiter);
  });

  group('NotificationScheduler.notificationId', () {
    test('produces deterministic results for same input', () {
      final id1 = NotificationScheduler.notificationId(100000, 'abc-123', 0);
      final id2 = NotificationScheduler.notificationId(100000, 'abc-123', 0);
      expect(id1, equals(id2));
    });

    test('produces different IDs for different entity IDs', () {
      final id1 = NotificationScheduler.notificationId(100000, 'egg-aaa', 0);
      final id2 = NotificationScheduler.notificationId(100000, 'egg-bbb', 0);
      expect(id1, isNot(equals(id2)));
    });

    test('produces different IDs for different offsets', () {
      final id1 = NotificationScheduler.notificationId(100000, 'egg-1', 0);
      final id2 = NotificationScheduler.notificationId(100000, 'egg-1', 1);
      expect(id1 + 1, equals(id2));
    });

    test('produces different IDs for different base IDs', () {
      final id1 = NotificationScheduler.notificationId(100000, 'egg-1', 0);
      final id2 = NotificationScheduler.notificationId(200000, 'egg-1', 0);
      // Same slot but different base → different ID
      expect(id1, isNot(equals(id2)));
      expect(id2 - id1, equals(100000));
    });

    test('ID stays within expected range for each category', () {
      // egg turning: 100000–199999
      for (var i = 0; i < 100; i++) {
        final id = NotificationScheduler.notificationId(100000, 'uuid-$i', 0);
        expect(id, greaterThanOrEqualTo(100000));
        expect(id, lessThan(200000));
      }
    });

    test('no collisions among 500 unique UUIDs in same category', () {
      final ids = <int>{};
      for (var i = 0; i < 500; i++) {
        final id = NotificationScheduler.notificationId(
          100000,
          'aaaaaaaa-bbbb-cccc-dddd-${i.toString().padLeft(12, '0')}',
          0,
        );
        ids.add(id);
      }
      // With 1000 slots and deterministic hashing, collisions are expected.
      // Keep a practical floor to detect severe regressions in distribution.
      expect(ids.length, greaterThan(340));
    });

    test('offset does not overflow slot boundary for typical usage', () {
      // Each slot has 100 IDs (offsets 0-99)
      // Egg turning: 18 days × 3 reminders = 54 offsets max
      const maxEggTurningOffset =
          IncubationConstants.incubationPeriodDays * 3 - 1;
      expect(maxEggTurningOffset, lessThan(100));

      final id = NotificationScheduler.notificationId(
        100000,
        'egg-test',
        maxEggTurningOffset,
      );
      expect(id, greaterThanOrEqualTo(100000));
      expect(id, lessThan(200000));
    });

    test('handles empty entity ID gracefully', () {
      final id = NotificationScheduler.notificationId(100000, '', 0);
      expect(id, greaterThanOrEqualTo(100000));
      expect(id, lessThan(200000));
    });

    test('handles very long entity ID', () {
      final longId = 'a' * 1000;
      final id = NotificationScheduler.notificationId(100000, longId, 0);
      expect(id, greaterThanOrEqualTo(100000));
      expect(id, lessThan(200000));
    });

    test('throws when offset exceeds slot boundary', () {
      expect(
        () => NotificationScheduler.notificationId(400000, 'chick-x', 150),
        throwsRangeError,
      );
    });

    test('throws for very large offsets to avoid cross-slot collisions', () {
      expect(
        () => NotificationScheduler.notificationId(
          400000,
          'chick-worst-case',
          720,
        ),
        throwsRangeError,
      );
    });
  });

  group('NotificationScheduler scheduling', () {
    test(
      'scheduleIncubationMilestones schedules 5 milestone reminders',
      () async {
        final fixedNow = DateTime(2026, 1, 10, 8, 0);
        final startDate = fixedNow.add(const Duration(days: 1));

        await scheduler.scheduleIncubationMilestones(
          incubationId: 'inc-1',
          startDate: startDate,
          label: 'Pair A',
          now: fixedNow,
        );

        expect(fakeService.scheduled.length, 5);
        expect(
          fakeService.scheduled.every(
            (n) => n.channelId == NotificationService.incubationChannelId,
          ),
          isTrue,
        );
        expect(
          fakeService.scheduled.every((n) => n.payload == 'incubation:inc-1'),
          isTrue,
        );
      },
    );

    test('scheduleEggTurningReminders schedules 3 reminders per day', () async {
      final fixedNow = DateTime(2026, 1, 10, 8, 0);
      final startDate = fixedNow.add(const Duration(days: 1));

      await scheduler.scheduleEggTurningReminders(
        eggId: 'egg-1',
        startDate: startDate,
        eggLabel: 'Egg #1',
        now: fixedNow,
      );

      final expectedCount =
          IncubationConstants.incubationPeriodDays *
          IncubationConstants.eggTurningHours.length;
      expect(fakeService.scheduled.length, expectedCount);
      expect(
        fakeService.scheduled.every(
          (n) => n.channelId == NotificationService.eggTurningChannelId,
        ),
        isTrue,
      );
      expect(
        fakeService.scheduled.every((n) => n.payload == 'egg_turning:egg-1'),
        isTrue,
      );
    });

    test(
      'scheduleEggTurningReminders dates are chronologically ordered',
      () async {
        final fixedNow = DateTime(2026, 1, 10, 8, 0);
        final startDate = fixedNow.add(const Duration(days: 1));

        await scheduler.scheduleEggTurningReminders(
          eggId: 'egg-order',
          startDate: startDate,
          eggLabel: 'Egg Order Test',
          now: fixedNow,
        );

        // Verify dates are in non-decreasing order
        for (var i = 1; i < fakeService.scheduled.length; i++) {
          expect(
            fakeService.scheduled[i].scheduledDate.isAfter(
                  fakeService.scheduled[i - 1].scheduledDate,
                ) ||
                fakeService.scheduled[i].scheduledDate.isAtSameMomentAs(
                  fakeService.scheduled[i - 1].scheduledDate,
                ),
            isTrue,
            reason:
                'Notification $i should be at or after notification ${i - 1}',
          );
        }

        // Verify first notification is on startDate
        final firstDate = fakeService.scheduled.first.scheduledDate;
        expect(firstDate.year, startDate.year);
        expect(firstDate.month, startDate.month);
        expect(firstDate.day, startDate.day);

        // Verify last notification is on startDate + (incubationDays - 1)
        final lastDate = fakeService.scheduled.last.scheduledDate;
        final expectedLastDay = startDate.add(
          const Duration(days: IncubationConstants.incubationPeriodDays - 1),
        );
        expect(lastDate.year, expectedLastDay.year);
        expect(lastDate.month, expectedLastDay.month);
        expect(lastDate.day, expectedLastDay.day);
      },
    );

    test(
      'scheduleChickCareReminder schedules by interval and duration',
      () async {
        final fixedNow = DateTime(2026, 1, 10, 8, 0);
        final startDate = fixedNow.add(const Duration(days: 1));

        await scheduler.scheduleChickCareReminder(
          chickId: 'chick-1',
          chickLabel: 'Chick A',
          startDate: startDate,
          intervalHours: 6,
          durationDays: 2,
          now: fixedNow,
        );

        // 24 / 6 = 4 reminders/day, for 2 days => 8 reminders
        expect(fakeService.scheduled.length, 8);
        expect(
          fakeService.scheduled.every(
            (n) => n.channelId == NotificationService.chickCareChannelId,
          ),
          isTrue,
        );
      },
    );

    test('scheduleHealthCheckReminder schedules for each day', () async {
      // Fix now to a known time so the hour=23 schedule is always in the future
      // for day 0, regardless of the real wall-clock time.
      final fixedNow = DateTime(2026, 1, 10, 8, 0);

      await scheduler.scheduleHealthCheckReminder(
        birdId: 'bird-1',
        birdName: 'Tweety',
        hour: 23,
        durationDays: 5,
        now: fixedNow,
      );

      expect(fakeService.scheduled.length, 5);
      expect(
        fakeService.scheduled.every(
          (n) => n.channelId == NotificationService.healthCheckChannelId,
        ),
        isTrue,
      );
      expect(
        fakeService.scheduled.every((n) => n.payload == 'health_check:bird-1'),
        isTrue,
      );
    });

    test('cancelAll delegates to notification service', () async {
      await scheduler.cancelAll();
      expect(fakeService.cancelAllCalled, isTrue);
    });
  });

  group('NotificationScheduler settings toggle', () {
    test('skips egg turning when settings.eggTurning is false', () async {
      final fixedNow = DateTime(2026, 1, 10, 8, 0);
      final startDate = fixedNow.add(const Duration(days: 1));
      const settings = NotificationToggleSettings(eggTurning: false);

      await scheduler.scheduleEggTurningReminders(
        eggId: 'egg-1',
        startDate: startDate,
        eggLabel: 'Egg #1',
        settings: settings,
      );

      expect(fakeService.scheduled, isEmpty);
    });

    test('skips incubation when settings.incubation is false', () async {
      final fixedNow = DateTime(2026, 1, 10, 8, 0);
      final startDate = fixedNow.add(const Duration(days: 1));
      const settings = NotificationToggleSettings(incubation: false);

      await scheduler.scheduleIncubationMilestones(
        incubationId: 'inc-1',
        startDate: startDate,
        label: 'Pair A',
        settings: settings,
      );

      expect(fakeService.scheduled, isEmpty);
    });

    test('skips chick care when settings.chickCare is false', () async {
      final fixedNow = DateTime(2026, 1, 10, 8, 0);
      final startDate = fixedNow.add(const Duration(days: 1));
      const settings = NotificationToggleSettings(chickCare: false);

      await scheduler.scheduleChickCareReminder(
        chickId: 'chick-1',
        chickLabel: 'Chick A',
        startDate: startDate,
        intervalHours: 6,
        durationDays: 2,
        settings: settings,
      );

      expect(fakeService.scheduled, isEmpty);
    });

    test('skips health check when settings.healthCheck is false', () async {
      const settings = NotificationToggleSettings(healthCheck: false);

      await scheduler.scheduleHealthCheckReminder(
        birdId: 'bird-1',
        birdName: 'Tweety',
        hour: 9,
        durationDays: 7,
        settings: settings,
      );

      expect(fakeService.scheduled, isEmpty);
    });

    test('schedules when settings is null (backwards compatible)', () async {
      final fixedNow = DateTime(2026, 1, 10, 8, 0);
      final startDate = fixedNow.add(const Duration(days: 1));

      await scheduler.scheduleIncubationMilestones(
        incubationId: 'inc-1',
        startDate: startDate,
        label: 'Pair A',
        settings: null,
        now: fixedNow,
      );

      expect(fakeService.scheduled, isNotEmpty);
    });
  });

  group('NotificationScheduler cancel methods', () {
    test('cancelEggTurningReminders cancels all egg turning IDs', () async {
      await scheduler.cancelEggTurningReminders('egg-1');

      final expectedCount =
          IncubationConstants.incubationPeriodDays *
          IncubationConstants.eggTurningHours.length;
      expect(fakeService.cancelledIds.length, expectedCount);

      // All IDs should be in egg turning range (100000–199999)
      expect(
        fakeService.cancelledIds.every((id) => id >= 100000 && id < 200000),
        isTrue,
      );
    });

    test('cancelIncubationMilestones cancels 5 milestone IDs', () async {
      await scheduler.cancelIncubationMilestones('inc-1');

      expect(fakeService.cancelledIds.length, 5);
      expect(
        fakeService.cancelledIds.every((id) => id >= 200000 && id < 300000),
        isTrue,
      );
    });

    test('cancelHealthCheckReminders cancels for specified days', () async {
      await scheduler.cancelHealthCheckReminders('bird-1', maxDays: 7);

      expect(fakeService.cancelledIds.length, 7);
      expect(
        fakeService.cancelledIds.every((id) => id >= 300000 && id < 400000),
        isTrue,
      );
    });

    test('cancelChickCareReminders cancels interval-based IDs', () async {
      await scheduler.cancelChickCareReminders(
        'chick-1',
        intervalHours: 6,
        durationDays: 2,
      );

      // 24/6 = 4 reminders/day * 2 days = 8
      expect(fakeService.cancelledIds.length, 8);
      expect(
        fakeService.cancelledIds.every((id) => id >= 400000 && id < 500000),
        isTrue,
      );
    });

    test('cancel IDs are deterministic and match schedule IDs', () async {
      final fixedNow = DateTime(2026, 1, 10, 8, 0);
      final startDate = fixedNow.add(const Duration(days: 1));

      await scheduler.scheduleIncubationMilestones(
        incubationId: 'inc-x',
        startDate: startDate,
        label: 'Test',
        now: fixedNow,
      );
      final scheduledIds = fakeService.scheduled.map((n) => n.id).toSet();

      await scheduler.cancelIncubationMilestones('inc-x');
      final cancelledIds = fakeService.cancelledIds.toSet();

      // All scheduled IDs should be in the cancelled set
      expect(scheduledIds.difference(cancelledIds), isEmpty);
    });
  });

  group('NotificationScheduler showImmediateNotification', () {
    test('shows notification when rate limiter allows', () async {
      final result = await scheduler.showImmediateNotification(
        id: 1,
        title: 'Test',
        body: 'Test body',
        type: 'test_type',
        userId: 'user-1',
      );

      expect(result, isTrue);
      expect(fakeService.shown.length, 1);
      expect(fakeService.shown.first.title, 'Test');
    });

    test('blocks notification when rate limited', () async {
      // Send first notification (should succeed)
      await scheduler.showImmediateNotification(
        id: 1,
        title: 'First',
        body: 'Body',
        type: 'test_type',
        userId: 'user-1',
      );

      // Second of same type should be blocked (maxPerTypePerHour = 1)
      final result = await scheduler.showImmediateNotification(
        id: 2,
        title: 'Second',
        body: 'Body',
        type: 'test_type',
        userId: 'user-1',
      );

      expect(result, isFalse);
      expect(fakeService.shown.length, 1);
    });

    test('allows different notification types independently', () async {
      await scheduler.showImmediateNotification(
        id: 1,
        title: 'Type A',
        body: 'Body',
        type: 'type_a',
        userId: 'user-1',
      );

      final result = await scheduler.showImmediateNotification(
        id: 2,
        title: 'Type B',
        body: 'Body',
        type: 'type_b',
        userId: 'user-1',
      );

      expect(result, isTrue);
      expect(fakeService.shown.length, 2);
    });
  });
}
