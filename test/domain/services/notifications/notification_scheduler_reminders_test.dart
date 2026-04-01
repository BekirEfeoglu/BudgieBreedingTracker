import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rate_limiter.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler_reminders.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_toggle_settings.dart';

import '../../../helpers/mocks.dart';

class MockNotificationRateLimiter extends Mock
    implements NotificationRateLimiter {}

class _TestScheduler with NotificationSchedulerReminders {
  _TestScheduler(this.notificationService, this.rateLimiter);

  @override
  final NotificationService notificationService;

  @override
  final NotificationRateLimiter rateLimiter;
}

void main() {
  late MockNotificationService mockService;
  late MockNotificationRateLimiter mockRateLimiter;
  late _TestScheduler scheduler;

  setUp(() {
    mockService = MockNotificationService();
    mockRateLimiter = MockNotificationRateLimiter();
    scheduler = _TestScheduler(mockService, mockRateLimiter);

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

    when(
      () => mockService.showNotification(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        channelId: any(named: 'channelId'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(DateTime(2024));
  });

  group('NotificationSchedulerReminders', () {
    group('scheduleChickCareReminder', () {
      test('schedules reminders based on interval and duration', () async {
        await scheduler.scheduleChickCareReminder(
          chickId: 'chick-1',
          chickLabel: 'Chick #1',
          startDate: DateTime(2024, 1, 1),
          intervalHours: 8,
          durationDays: 1,
          now: DateTime(2024, 1, 1, 0, 0),
        );

        // 24/8 = 3 reminders per day, 1 day
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

      test('skips when chickCare toggle is disabled', () async {
        await scheduler.scheduleChickCareReminder(
          chickId: 'chick-1',
          chickLabel: 'Chick #1',
          startDate: DateTime(2024, 1, 1),
          intervalHours: 8,
          durationDays: 1,
          settings: const NotificationToggleSettings(chickCare: false),
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

      test('skips invalid interval (0)', () async {
        await scheduler.scheduleChickCareReminder(
          chickId: 'chick-1',
          chickLabel: 'Chick #1',
          startDate: DateTime(2024, 1, 1),
          intervalHours: 0,
          durationDays: 1,
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

      test('skips invalid interval (>24)', () async {
        await scheduler.scheduleChickCareReminder(
          chickId: 'chick-1',
          chickLabel: 'Chick #1',
          startDate: DateTime(2024, 1, 1),
          intervalHours: 25,
          durationDays: 1,
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
    });

    group('showImmediateNotification', () {
      test('shows notification when rate limiter allows', () async {
        when(() => mockRateLimiter.canSend(any(), any())).thenReturn(true);
        when(() => mockRateLimiter.recordSent(any(), any())).thenReturn(null);

        final result = await scheduler.showImmediateNotification(
          id: 1,
          title: 'Test',
          body: 'Body',
          type: 'test_type',
          userId: 'user-1',
        );

        expect(result, isTrue);
        verify(
          () => mockService.showNotification(
            id: 1,
            title: 'Test',
            body: 'Body',
            channelId: 'default',
            payload: null,
          ),
        ).called(1);
        verify(() => mockRateLimiter.recordSent('test_type', 'user-1'))
            .called(1);
      });

      test('returns false when rate limited', () async {
        when(() => mockRateLimiter.canSend(any(), any())).thenReturn(false);

        final result = await scheduler.showImmediateNotification(
          id: 1,
          title: 'Test',
          body: 'Body',
          type: 'test_type',
          userId: 'user-1',
        );

        expect(result, isFalse);
        verifyNever(
          () => mockService.showNotification(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            channelId: any(named: 'channelId'),
            payload: any(named: 'payload'),
          ),
        );
      });
    });
  });
}
