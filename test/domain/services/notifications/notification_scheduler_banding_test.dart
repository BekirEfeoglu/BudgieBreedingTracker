import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rate_limiter.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_toggle_settings.dart';

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

class _FakeNotificationService extends NotificationService {
  final scheduled = <_ScheduledNotification>[];

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
  }) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}
}

void main() {
  late _FakeNotificationService fakeService;
  late NotificationRateLimiter rateLimiter;
  late NotificationScheduler scheduler;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeService = _FakeNotificationService();
    rateLimiter = NotificationRateLimiter();
    await rateLimiter.setDndHours(startHour: 0, endHour: 0);
    scheduler = NotificationScheduler(fakeService, rateLimiter);
  });

  group('NotificationScheduler.scheduleBandingReminders', () {
    test('schedules 4 notifications for a future banding day', () async {
      // hatchDate = 2026-01-01, bandingDay = 10, now = 2026-01-01
      // Offsets: -1=day9, 0=day10, +1=day11, +3=day13 — all future
      final hatchDate = DateTime(2026, 1, 1);
      final fixedNow = DateTime(2026, 1, 1, 7, 0);

      await scheduler.scheduleBandingReminders(
        chickId: 'chick-band-1',
        chickLabel: 'Chick B1',
        hatchDate: hatchDate,
        bandingDay: 10,
        now: fixedNow,
      );

      expect(fakeService.scheduled.length, 4);
    });

    test('all notifications use chickCareChannelId', () async {
      final hatchDate = DateTime(2026, 1, 1);
      final fixedNow = DateTime(2026, 1, 1, 7, 0);

      await scheduler.scheduleBandingReminders(
        chickId: 'chick-band-2',
        chickLabel: 'Chick B2',
        hatchDate: hatchDate,
        bandingDay: 10,
        now: fixedNow,
      );

      expect(
        fakeService.scheduled.every(
          (n) => n.channelId == NotificationService.chickCareChannelId,
        ),
        isTrue,
      );
    });

    test('all notifications have banding payload', () async {
      final hatchDate = DateTime(2026, 1, 1);
      final fixedNow = DateTime(2026, 1, 1, 7, 0);

      await scheduler.scheduleBandingReminders(
        chickId: 'chick-band-3',
        chickLabel: 'Chick B3',
        hatchDate: hatchDate,
        bandingDay: 10,
        now: fixedNow,
      );

      expect(
        fakeService.scheduled.every((n) => n.payload == 'banding:chick-band-3'),
        isTrue,
      );
    });

    test(
      'all notification IDs are in the banding range (500000–599999)',
      () async {
        final hatchDate = DateTime(2026, 1, 1);
        final fixedNow = DateTime(2026, 1, 1, 7, 0);

        await scheduler.scheduleBandingReminders(
          chickId: 'chick-band-4',
          chickLabel: 'Chick B4',
          hatchDate: hatchDate,
          bandingDay: 10,
          now: fixedNow,
        );

        expect(
          fakeService.scheduled.every(
            (n) =>
                n.id >= NotificationIds.bandingBaseId &&
                n.id < NotificationIds.bandingBaseId + 100000,
          ),
          isTrue,
        );
      },
    );

    test('notifications are scheduled at 09:00', () async {
      final hatchDate = DateTime(2026, 1, 1);
      final fixedNow = DateTime(2026, 1, 1, 7, 0);

      await scheduler.scheduleBandingReminders(
        chickId: 'chick-band-5',
        chickLabel: 'Chick B5',
        hatchDate: hatchDate,
        bandingDay: 10,
        now: fixedNow,
      );

      expect(
        fakeService.scheduled.every((n) => n.scheduledDate.hour == 9),
        isTrue,
      );
    });

    test('skips past notifications and only schedules future ones', () async {
      // fixedNow is after banding day 10 and follow-ups at day 11
      // but before follow-up at day 13
      // hatch = 2026-01-01, banding = day 10 => 2026-01-11
      // offsets: -1 => 2026-01-10 (past), 0 => 2026-01-11 09:00 (past if now is after)
      //           +1 => 2026-01-12 (past), +3 => 2026-01-14 (future)
      final hatchDate = DateTime(2026, 1, 1);
      final fixedNow = DateTime(
        2026,
        1,
        13,
        10,
        0,
      ); // after day 12, before day 14

      await scheduler.scheduleBandingReminders(
        chickId: 'chick-band-skip',
        chickLabel: 'Chick Skip',
        hatchDate: hatchDate,
        bandingDay: 10,
        now: fixedNow,
      );

      // Only the day+3 (2026-01-14) notification should be scheduled
      expect(fakeService.scheduled.length, 1);
      expect(fakeService.scheduled.first.scheduledDate.day, 14);
    });

    test('skips all when banding day is in the past', () async {
      final hatchDate = DateTime(2026, 1, 1);
      // now is after all 4 offsets (day 9, 10, 11, 13)
      final fixedNow = DateTime(2026, 2, 1, 10, 0);

      await scheduler.scheduleBandingReminders(
        chickId: 'chick-band-allpast',
        chickLabel: 'Chick AllPast',
        hatchDate: hatchDate,
        bandingDay: 10,
        now: fixedNow,
      );

      expect(fakeService.scheduled, isEmpty);
    });

    test('respects banding toggle when disabled', () async {
      final hatchDate = DateTime(2026, 1, 1);
      final fixedNow = DateTime(2026, 1, 1, 7, 0);
      const settings = NotificationToggleSettings(banding: false);

      await scheduler.scheduleBandingReminders(
        chickId: 'chick-band-disabled',
        chickLabel: 'Chick Disabled',
        hatchDate: hatchDate,
        bandingDay: 10,
        settings: settings,
        now: fixedNow,
      );

      expect(fakeService.scheduled, isEmpty);
    });

    test('schedules when settings is null (backwards compatible)', () async {
      final hatchDate = DateTime(2026, 1, 1);
      final fixedNow = DateTime(2026, 1, 1, 7, 0);

      await scheduler.scheduleBandingReminders(
        chickId: 'chick-band-null-settings',
        chickLabel: 'Chick NullSettings',
        hatchDate: hatchDate,
        bandingDay: 10,
        settings: null,
        now: fixedNow,
      );

      expect(fakeService.scheduled, isNotEmpty);
    });

    test('schedules when banding toggle is enabled', () async {
      final hatchDate = DateTime(2026, 1, 1);
      final fixedNow = DateTime(2026, 1, 1, 7, 0);
      const settings = NotificationToggleSettings(banding: true);

      await scheduler.scheduleBandingReminders(
        chickId: 'chick-band-enabled',
        chickLabel: 'Chick Enabled',
        hatchDate: hatchDate,
        bandingDay: 10,
        settings: settings,
        now: fixedNow,
      );

      expect(fakeService.scheduled.length, 4);
    });
  });
}
