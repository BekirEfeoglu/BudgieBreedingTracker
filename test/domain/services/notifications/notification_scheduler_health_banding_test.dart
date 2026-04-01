import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler_health_banding.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_toggle_settings.dart';

import '../../../helpers/mocks.dart';

class _TestScheduler with NotificationSchedulerHealthBanding {
  _TestScheduler(this.notificationService);

  @override
  final NotificationService notificationService;
}

void main() {
  late MockNotificationService mockService;
  late _TestScheduler scheduler;

  setUp(() {
    mockService = MockNotificationService();
    scheduler = _TestScheduler(mockService);

    when(
      () => mockService.scheduleNotification(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        channelId: any(named: 'channelId'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(DateTime(2024));
  });

  group('NotificationSchedulerHealthBanding', () {
    group('scheduleHealthCheckReminder', () {
      test('schedules notifications for each day', () async {
        await scheduler.scheduleHealthCheckReminder(
          birdId: 'bird-1',
          birdName: 'Mavi',
          hour: 9,
          durationDays: 3,
          now: DateTime(2024, 1, 1, 8),
        );

        verify(
          () => mockService.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            channelId: any(named: 'channelId'),
            payload: any(named: 'payload'),
          ),
        ).called(3);
      });

      test('skips when healthCheck toggle is disabled', () async {
        await scheduler.scheduleHealthCheckReminder(
          birdId: 'bird-1',
          birdName: 'Mavi',
          hour: 9,
          durationDays: 3,
          settings: const NotificationToggleSettings(healthCheck: false),
          now: DateTime(2024, 1, 1, 8),
        );

        verifyNever(
          () => mockService.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            channelId: any(named: 'channelId'),
            payload: any(named: 'payload'),
          ),
        );
      });

      test('skips past dates', () async {
        // now is after the scheduled time on day 0
        await scheduler.scheduleHealthCheckReminder(
          birdId: 'bird-1',
          birdName: 'Mavi',
          hour: 8,
          durationDays: 2,
          now: DateTime(2024, 1, 1, 9), // 9:00, hour=8 means day 0 is past
        );

        // Day 0 at 8:00 is before now (9:00), so only day 1 should be scheduled
        verify(
          () => mockService.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            channelId: any(named: 'channelId'),
            payload: any(named: 'payload'),
          ),
        ).called(1);
      });
    });

    group('scheduleBandingReminders', () {
      test('schedules 4 banding notifications', () async {
        await scheduler.scheduleBandingReminders(
          chickId: 'chick-1',
          chickLabel: 'Chick #1',
          hatchDate: DateTime(2024, 1, 1),
          bandingDay: 10,
          now: DateTime(2024, 1, 1),
        );

        // 4 offsets: -1, 0, +1, +3 all in the future
        verify(
          () => mockService.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            channelId: any(named: 'channelId'),
            payload: any(named: 'payload'),
          ),
        ).called(4);
      });

      test('skips when banding toggle is disabled', () async {
        await scheduler.scheduleBandingReminders(
          chickId: 'chick-1',
          chickLabel: 'Chick #1',
          hatchDate: DateTime(2024, 1, 1),
          bandingDay: 10,
          settings: const NotificationToggleSettings(banding: false),
          now: DateTime(2024, 1, 1),
        );

        verifyNever(
          () => mockService.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            channelId: any(named: 'channelId'),
            payload: any(named: 'payload'),
          ),
        );
      });

      test('skips past banding dates', () async {
        // Hatch = Jan 1, banding day = 2, so dates are Jan 1,2,3,5
        // Now = Jan 4, so Jan 1,2,3 are past, only Jan 5 remains
        await scheduler.scheduleBandingReminders(
          chickId: 'chick-1',
          chickLabel: 'Chick #1',
          hatchDate: DateTime(2024, 1, 1),
          bandingDay: 2,
          now: DateTime(2024, 1, 4, 10),
        );

        verify(
          () => mockService.scheduleNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            channelId: any(named: 'channelId'),
            payload: any(named: 'payload'),
          ),
        ).called(1);
      });
    });
  });
}
