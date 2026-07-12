import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/streak_reminder_scheduler.dart';

class _MockNotificationService extends Mock implements NotificationService {}

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  late _MockNotificationService service;
  late StreakReminderScheduler scheduler;

  setUp(() {
    service = _MockNotificationService();
    when(() => service.cancel(any())).thenAnswer((_) async {});
    when(
      () => service.scheduleNotification(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        channelId: any(named: 'channelId'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    scheduler = StreakReminderScheduler(service);
  });

  test('always cancels the existing reminder before rescheduling', () async {
    await scheduler.scheduleNext(currentStreak: 5, enabled: true);
    verify(() => service.cancel(any())).called(1);
  });

  test('does not schedule when streak is below 3', () async {
    await scheduler.scheduleNext(currentStreak: 2, enabled: true);
    verifyNever(
      () => service.scheduleNotification(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        channelId: any(named: 'channelId'),
        payload: any(named: 'payload'),
      ),
    );
  });

  test('does not schedule when disabled, even with a long streak', () async {
    await scheduler.scheduleNext(currentStreak: 10, enabled: false);
    verifyNever(
      () => service.scheduleNotification(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        channelId: any(named: 'channelId'),
        payload: any(named: 'payload'),
      ),
    );
  });

  test(
    'schedules a single reminder for tomorrow 20:00 local when streak >= 3 and enabled',
    () async {
      final before = tz.TZDateTime.now(tz.local);

      await scheduler.scheduleNext(currentStreak: 5, enabled: true);

      final captured = verify(
        () => service.scheduleNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: captureAny(named: 'scheduledDate'),
          channelId: NotificationService.streakChannelId,
          payload: 'streak:reminder',
        ),
      ).captured;

      expect(captured, hasLength(1));
      final scheduledDate = captured.single as DateTime;
      final tomorrow = before.add(const Duration(days: 1));
      expect(scheduledDate.year, tomorrow.year);
      expect(scheduledDate.month, tomorrow.month);
      expect(scheduledDate.day, tomorrow.day);
      expect(scheduledDate.hour, 20);
    },
  );

  test('uses a deterministic id across reschedules', () async {
    await scheduler.scheduleNext(currentStreak: 5, enabled: true);
    final firstId =
        verify(
              () => service.scheduleNotification(
                id: captureAny(named: 'id'),
                title: any(named: 'title'),
                body: any(named: 'body'),
                scheduledDate: any(named: 'scheduledDate'),
                channelId: any(named: 'channelId'),
                payload: any(named: 'payload'),
              ),
            ).captured.single
            as int;

    await scheduler.scheduleNext(currentStreak: 7, enabled: true);
    final secondId =
        verify(
              () => service.scheduleNotification(
                id: captureAny(named: 'id'),
                title: any(named: 'title'),
                body: any(named: 'body'),
                scheduledDate: any(named: 'scheduledDate'),
                channelId: any(named: 'channelId'),
                payload: any(named: 'payload'),
              ),
            ).captured.single
            as int;

    expect(firstId, secondId);
  });

  test('cancel() cancels the streak reminder id', () async {
    await scheduler.cancel();
    verify(() => service.cancel(any())).called(1);
  });
}
