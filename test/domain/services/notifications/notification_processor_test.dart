import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/event_reminders_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/events_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notification_schedules_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notification_settings_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notifications_dao.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/models/event_reminder_model.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/data/models/notification_schedule_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_processor.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';

class _MockEventRemindersDao extends Mock implements EventRemindersDao {}

class _MockEventsDao extends Mock implements EventsDao {}

class _MockNotificationSchedulesDao extends Mock
    implements NotificationSchedulesDao {}

class _MockNotificationScheduler extends Mock
    implements NotificationScheduler {}

class _MockNotificationService extends Mock implements NotificationService {}

class _MockNotificationsDao extends Mock implements NotificationsDao {}

class _MockNotificationSettingsDao extends Mock
    implements NotificationSettingsDao {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      NotificationSchedule(
        id: '',
        userId: '',
        type: NotificationType.custom,
        title: '',
        scheduledAt: DateTime(2026),
      ),
    );
  });

  group('NotificationProcessor', () {
    test('processAll returns early for anonymous user', () async {
      final container = ProviderContainer(
        overrides: [currentUserIdProvider.overrideWithValue('anonymous')],
      );
      addTearDown(container.dispose);

      final processor = container.read(notificationProcessorProvider);
      await processor.processAll();
    });

    test('processEventReminders exits when no unsent reminders', () async {
      final remindersDao = _MockEventRemindersDao();
      final eventsDao = _MockEventsDao();
      final scheduler = _MockNotificationScheduler();

      when(() => remindersDao.countUnsent('user-1')).thenAnswer((_) async => 0);

      final container = ProviderContainer(
        overrides: [
          eventRemindersDaoProvider.overrideWithValue(remindersDao),
          eventsDaoProvider.overrideWithValue(eventsDao),
          notificationSchedulerProvider.overrideWithValue(scheduler),
        ],
      );
      addTearDown(container.dispose);

      final processor = container.read(notificationProcessorProvider);
      await processor.processEventReminders('user-1');

      verify(() => remindersDao.countUnsent('user-1')).called(1);
      verifyNever(() => remindersDao.getUnsent(any()));
      verifyNever(() => eventsDao.getById(any()));
      verifyZeroInteractions(scheduler);
    });

    test(
      'processNotificationSchedules exits when no pending schedules',
      () async {
        final schedulesDao = _MockNotificationSchedulesDao();
        final service = _MockNotificationService();
        final scheduler = _MockNotificationScheduler();

        when(
          () => schedulesDao.countPending('user-1'),
        ).thenAnswer((_) async => 0);

        final container = ProviderContainer(
          overrides: [
            notificationSchedulesDaoProvider.overrideWithValue(schedulesDao),
            notificationServiceProvider.overrideWithValue(service),
            notificationSchedulerProvider.overrideWithValue(scheduler),
          ],
        );
        addTearDown(container.dispose);

        final processor = container.read(notificationProcessorProvider);
        await processor.processNotificationSchedules('user-1');

        verify(() => schedulesDao.countPending('user-1')).called(1);
        verifyNever(() => schedulesDao.getPending(any()));
        verifyZeroInteractions(service);
        verifyZeroInteractions(scheduler);
      },
    );
  });

  group('NotificationProcessor.processEventReminders', () {
    late _MockEventRemindersDao remindersDao;
    late _MockEventsDao eventsDao;
    late _MockNotificationScheduler scheduler;
    late _MockNotificationService service;
    late ProviderContainer container;

    setUp(() {
      remindersDao = _MockEventRemindersDao();
      eventsDao = _MockEventsDao();
      scheduler = _MockNotificationScheduler();
      service = _MockNotificationService();
    });

    ProviderContainer buildContainer() {
      final c = ProviderContainer(
        overrides: [
          eventRemindersDaoProvider.overrideWithValue(remindersDao),
          eventsDaoProvider.overrideWithValue(eventsDao),
          notificationSchedulerProvider.overrideWithValue(scheduler),
          notificationServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('schedules future reminder via service', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 2));
      const reminder = EventReminder(
        id: 'rem-1',
        userId: 'user-1',
        eventId: 'evt-1',
        minutesBefore: 30,
      );
      final event = Event(
        id: 'evt-1',
        title: 'Vet Visit',
        eventDate: futureDate,
        type: EventType.custom,
        userId: 'user-1',
      );

      when(() => remindersDao.countUnsent('user-1')).thenAnswer((_) async => 1);
      when(
        () => remindersDao.getUnsent('user-1'),
      ).thenAnswer((_) async => [reminder]);
      when(() => eventsDao.getById('evt-1')).thenAnswer((_) async => event);
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
      when(() => remindersDao.markSent('rem-1')).thenAnswer((_) async {});

      container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processEventReminders('user-1');

      verify(
        () => service.scheduleNotification(
          id: any(named: 'id'),
          title: 'Vet Visit',
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          channelId: 'default',
          payload: 'event_reminder:evt-1',
        ),
      ).called(1);
      verify(() => remindersDao.markSent('rem-1')).called(1);
    });

    test('shows immediate notification for recent past reminder', () async {
      final recentPast = DateTime.now().subtract(const Duration(minutes: 10));
      const reminder = EventReminder(
        id: 'rem-2',
        userId: 'user-1',
        eventId: 'evt-2',
        minutesBefore: 0,
      );
      final event = Event(
        id: 'evt-2',
        title: 'Feeding',
        eventDate: recentPast,
        type: EventType.custom,
        userId: 'user-1',
      );

      when(() => remindersDao.countUnsent('user-1')).thenAnswer((_) async => 1);
      when(
        () => remindersDao.getUnsent('user-1'),
      ).thenAnswer((_) async => [reminder]);
      when(() => eventsDao.getById('evt-2')).thenAnswer((_) async => event);
      when(
        () => scheduler.showImmediateNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          type: any(named: 'type'),
          userId: any(named: 'userId'),
          payload: any(named: 'payload'),
          channelId: any(named: 'channelId'),
        ),
      ).thenAnswer((_) async => true);
      when(() => remindersDao.markSent('rem-2')).thenAnswer((_) async {});

      container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processEventReminders('user-1');

      verify(
        () => scheduler.showImmediateNotification(
          id: any(named: 'id'),
          title: 'Feeding',
          body: any(named: 'body'),
          type: 'event_reminder',
          userId: 'user-1',
          payload: 'event_reminder:evt-2',
          channelId: any(named: 'channelId'),
        ),
      ).called(1);
      verify(() => remindersDao.markSent('rem-2')).called(1);
    });

    test('marks old reminder as sent without showing', () async {
      final oldDate = DateTime.now().subtract(const Duration(hours: 48));
      const reminder = EventReminder(
        id: 'rem-3',
        userId: 'user-1',
        eventId: 'evt-3',
        minutesBefore: 0,
      );
      final event = Event(
        id: 'evt-3',
        title: 'Old Event',
        eventDate: oldDate,
        type: EventType.custom,
        userId: 'user-1',
      );

      when(() => remindersDao.countUnsent('user-1')).thenAnswer((_) async => 1);
      when(
        () => remindersDao.getUnsent('user-1'),
      ).thenAnswer((_) async => [reminder]);
      when(() => eventsDao.getById('evt-3')).thenAnswer((_) async => event);
      when(() => remindersDao.markSent('rem-3')).thenAnswer((_) async {});

      container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processEventReminders('user-1');

      verify(() => remindersDao.markSent('rem-3')).called(1);
      verifyZeroInteractions(service);
      verifyZeroInteractions(scheduler);
    });

    test('skips reminder when event not found', () async {
      const reminder = EventReminder(
        id: 'rem-4',
        userId: 'user-1',
        eventId: 'evt-missing',
        minutesBefore: 10,
      );

      when(() => remindersDao.countUnsent('user-1')).thenAnswer((_) async => 1);
      when(
        () => remindersDao.getUnsent('user-1'),
      ).thenAnswer((_) async => [reminder]);
      when(
        () => eventsDao.getById('evt-missing'),
      ).thenAnswer((_) async => null);
      when(() => remindersDao.markSent('rem-4')).thenAnswer((_) async {});

      container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processEventReminders('user-1');

      verify(() => remindersDao.markSent('rem-4')).called(1);
      verifyZeroInteractions(service);
      verifyZeroInteractions(scheduler);
    });

    test('does not mark sent when rate limiter blocks', () async {
      final recentPast = DateTime.now().subtract(const Duration(minutes: 5));
      const reminder = EventReminder(
        id: 'rem-5',
        userId: 'user-1',
        eventId: 'evt-5',
        minutesBefore: 0,
      );
      final event = Event(
        id: 'evt-5',
        title: 'Rate Limited',
        eventDate: recentPast,
        type: EventType.custom,
        userId: 'user-1',
      );

      when(() => remindersDao.countUnsent('user-1')).thenAnswer((_) async => 1);
      when(
        () => remindersDao.getUnsent('user-1'),
      ).thenAnswer((_) async => [reminder]);
      when(() => eventsDao.getById('evt-5')).thenAnswer((_) async => event);
      when(
        () => scheduler.showImmediateNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          type: any(named: 'type'),
          userId: any(named: 'userId'),
          payload: any(named: 'payload'),
          channelId: any(named: 'channelId'),
        ),
      ).thenAnswer((_) async => false);

      container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processEventReminders('user-1');

      verifyNever(() => remindersDao.markSent(any()));
    });

    test('continues processing when individual reminder fails', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 3));
      const reminder1 = EventReminder(
        id: 'rem-fail',
        userId: 'user-1',
        eventId: 'evt-fail',
        minutesBefore: 10,
      );
      const reminder2 = EventReminder(
        id: 'rem-ok',
        userId: 'user-1',
        eventId: 'evt-ok',
        minutesBefore: 0,
      );
      final event2 = Event(
        id: 'evt-ok',
        title: 'OK Event',
        eventDate: futureDate,
        type: EventType.custom,
        userId: 'user-1',
      );

      when(() => remindersDao.countUnsent('user-1')).thenAnswer((_) async => 2);
      when(
        () => remindersDao.getUnsent('user-1'),
      ).thenAnswer((_) async => [reminder1, reminder2]);
      when(
        () => eventsDao.getById('evt-fail'),
      ).thenThrow(Exception('DB error'));
      when(() => eventsDao.getById('evt-ok')).thenAnswer((_) async => event2);
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
      when(() => remindersDao.markSent('rem-ok')).thenAnswer((_) async {});

      container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processEventReminders('user-1');

      // First reminder failed but second processed successfully
      verify(
        () => service.scheduleNotification(
          id: any(named: 'id'),
          title: 'OK Event',
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          channelId: 'default',
          payload: 'event_reminder:evt-ok',
        ),
      ).called(1);
      verify(() => remindersDao.markSent('rem-ok')).called(1);
    });
  });

  group('NotificationProcessor.processNotificationSchedules', () {
    late _MockNotificationSchedulesDao schedulesDao;
    late _MockNotificationSettingsDao settingsDao;
    late _MockNotificationService service;
    late _MockNotificationScheduler scheduler;
    late ProviderContainer container;

    setUp(() {
      schedulesDao = _MockNotificationSchedulesDao();
      settingsDao = _MockNotificationSettingsDao();
      service = _MockNotificationService();
      scheduler = _MockNotificationScheduler();

      when(() => settingsDao.getByUser(any())).thenAnswer((_) async => null);
    });

    ProviderContainer buildContainer() {
      final c = ProviderContainer(
        overrides: [
          notificationSchedulesDaoProvider.overrideWithValue(schedulesDao),
          notificationSettingsDaoProvider.overrideWithValue(settingsDao),
          notificationServiceProvider.overrideWithValue(service),
          notificationSchedulerProvider.overrideWithValue(scheduler),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('schedules future notification via service', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 5));
      final schedule = NotificationSchedule(
        id: 'sched-1',
        userId: 'user-1',
        type: NotificationType.eggTurning,
        title: 'Turn Eggs',
        message: 'Time to turn',
        scheduledAt: futureDate,
      );

      when(
        () => schedulesDao.countPending('user-1'),
      ).thenAnswer((_) async => 1);
      when(
        () => schedulesDao.getPending('user-1'),
      ).thenAnswer((_) async => [schedule]);
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
      when(
        () => schedulesDao.markProcessed('sched-1'),
      ).thenAnswer((_) async {});

      container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');

      verify(
        () => service.scheduleNotification(
          id: any(named: 'id'),
          title: 'Turn Eggs',
          body: 'Time to turn',
          scheduledDate: any(named: 'scheduledDate'),
          channelId: NotificationService.eggTurningChannelId,
          payload: any(named: 'payload'),
        ),
      ).called(1);
      verifyNever(() => schedulesDao.markProcessed(any()));
    });

    test('does not reschedule same future schedule repeatedly', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 2));
      final schedule = NotificationSchedule(
        id: 'sched-future-once',
        userId: 'user-1',
        type: NotificationType.custom,
        title: 'Future once',
        scheduledAt: futureDate,
      );

      when(
        () => schedulesDao.countPending('user-1'),
      ).thenAnswer((_) async => 1);
      when(
        () => schedulesDao.getPending('user-1'),
      ).thenAnswer((_) async => [schedule]);
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

      container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');
      await processor.processNotificationSchedules('user-1');

      verify(
        () => service.scheduleNotification(
          id: any(named: 'id'),
          title: 'Future once',
          body: '',
          scheduledDate: any(named: 'scheduledDate'),
          channelId: 'default',
          payload: null,
        ),
      ).called(1);
      verifyNever(() => schedulesDao.markProcessed(any()));
      verifyZeroInteractions(scheduler);
    });

    test('shows immediate for recent past schedule', () async {
      final recentPast = DateTime.now().subtract(const Duration(minutes: 30));
      final schedule = NotificationSchedule(
        id: 'sched-2',
        userId: 'user-1',
        type: NotificationType.healthCheck,
        title: 'Health Check',
        scheduledAt: recentPast,
      );

      when(
        () => schedulesDao.countPending('user-1'),
      ).thenAnswer((_) async => 1);
      when(
        () => schedulesDao.getPending('user-1'),
      ).thenAnswer((_) async => [schedule]);
      when(
        () => scheduler.showImmediateNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          type: any(named: 'type'),
          userId: any(named: 'userId'),
          channelId: any(named: 'channelId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => schedulesDao.markProcessed('sched-2'),
      ).thenAnswer((_) async {});

      container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');

      verify(
        () => scheduler.showImmediateNotification(
          id: any(named: 'id'),
          title: 'Health Check',
          body: '',
          type: 'healthCheck',
          userId: 'user-1',
          channelId: NotificationService.healthCheckChannelId,
          payload: any(named: 'payload'),
        ),
      ).called(1);
      verify(() => schedulesDao.markProcessed('sched-2')).called(1);
    });

    test('marks old schedule as processed without showing', () async {
      final oldDate = DateTime.now().subtract(const Duration(hours: 48));
      final schedule = NotificationSchedule(
        id: 'sched-3',
        userId: 'user-1',
        type: NotificationType.custom,
        title: 'Old',
        scheduledAt: oldDate,
      );

      when(
        () => schedulesDao.countPending('user-1'),
      ).thenAnswer((_) async => 1);
      when(
        () => schedulesDao.getPending('user-1'),
      ).thenAnswer((_) async => [schedule]);
      when(
        () => schedulesDao.markProcessed('sched-3'),
      ).thenAnswer((_) async {});

      container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');

      verify(() => schedulesDao.markProcessed('sched-3')).called(1);
      verifyZeroInteractions(service);
      verifyZeroInteractions(scheduler);
    });

    test('creates next occurrence for recurring schedule', () async {
      final recentPast = DateTime.now().subtract(const Duration(minutes: 5));
      final schedule = NotificationSchedule(
        id: 'sched-recurring',
        userId: 'user-1',
        type: NotificationType.feedingReminder,
        title: 'Feed',
        scheduledAt: recentPast,
        isRecurring: true,
        intervalMinutes: 240,
      );

      when(
        () => schedulesDao.countPending('user-1'),
      ).thenAnswer((_) async => 1);
      when(
        () => schedulesDao.getPending('user-1'),
      ).thenAnswer((_) async => [schedule]);
      when(
        () => scheduler.showImmediateNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          type: any(named: 'type'),
          userId: any(named: 'userId'),
          channelId: any(named: 'channelId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => schedulesDao.markProcessed('sched-recurring'),
      ).thenAnswer((_) async {});
      when(() => schedulesDao.insertItem(any())).thenAnswer((_) async {});

      container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');

      // Should create next occurrence
      final captured = verify(
        () => schedulesDao.insertItem(captureAny()),
      ).captured;
      expect(captured, hasLength(1));
      final next = captured.first as NotificationSchedule;
      expect(next.scheduledAt.isAfter(recentPast), isTrue);
      expect(next.processedAt, isNull);
    });

    test(
      'creates catch-up next occurrence when interval was in the past',
      () async {
        // Recurring with very short interval that still results in past nextAt
        final oldDate = DateTime.now().subtract(const Duration(hours: 48));
        final schedule = NotificationSchedule(
          id: 'sched-old-recurring',
          userId: 'user-1',
          type: NotificationType.feedingReminder,
          title: 'Feed',
          scheduledAt: oldDate,
          isRecurring: true,
          intervalMinutes: 60, // 1 hour, but 48h ago + 1h = still 47h ago
        );

        when(
          () => schedulesDao.countPending('user-1'),
        ).thenAnswer((_) async => 1);
        when(
          () => schedulesDao.getPending('user-1'),
        ).thenAnswer((_) async => [schedule]);
        when(
          () => schedulesDao.markProcessed('sched-old-recurring'),
        ).thenAnswer((_) async {});
        when(() => schedulesDao.insertItem(any())).thenAnswer((_) async {});

        container = buildContainer();
        final processor = container.read(notificationProcessorProvider);
        await processor.processNotificationSchedules('user-1');

        final captured = verify(
          () => schedulesDao.insertItem(captureAny()),
        ).captured;
        expect(captured, hasLength(1));
        final next = captured.first as NotificationSchedule;
        expect(next.scheduledAt.isAfter(DateTime.now()), isTrue);
      },
    );

    test('continues processing when individual schedule fails', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 1));
      final schedule1 = NotificationSchedule(
        id: 'sched-fail',
        userId: 'user-1',
        type: NotificationType.custom,
        title: 'Fail',
        scheduledAt: futureDate,
      );
      final schedule2 = NotificationSchedule(
        id: 'sched-ok',
        userId: 'user-1',
        type: NotificationType.custom,
        title: 'OK',
        scheduledAt: futureDate,
      );

      when(
        () => schedulesDao.countPending('user-1'),
      ).thenAnswer((_) async => 2);
      when(
        () => schedulesDao.getPending('user-1'),
      ).thenAnswer((_) async => [schedule1, schedule2]);
      var callCount = 0;
      when(
        () => service.scheduleNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          channelId: any(named: 'channelId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('Plugin error');
      });
      container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');

      // First schedule failed but second schedule was still attempted.
      verify(
        () => service.scheduleNotification(
          id: any(named: 'id'),
          title: 'OK',
          body: '',
          scheduledDate: any(named: 'scheduledDate'),
          channelId: 'default',
          payload: null,
        ),
      ).called(1);
    });
  });

  group('NotificationProcessor.processAll', () {
    test('runs reminders, schedules and cleanup in parallel', () async {
      final remindersDao = _MockEventRemindersDao();
      final eventsDao = _MockEventsDao();
      final schedulesDao = _MockNotificationSchedulesDao();
      final service = _MockNotificationService();
      final scheduler = _MockNotificationScheduler();
      final notificationsDao = _MockNotificationsDao();
      final settingsDao = _MockNotificationSettingsDao();

      when(() => remindersDao.countUnsent(any())).thenAnswer((_) async => 0);
      when(() => schedulesDao.countPending(any())).thenAnswer((_) async => 0);
      when(() => settingsDao.getByUser(any())).thenAnswer((_) async => null);
      when(
        () => notificationsDao.deleteOldRead(
          any(),
          daysOld: any(named: 'daysOld'),
        ),
      ).thenAnswer((_) async => 3);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          eventRemindersDaoProvider.overrideWithValue(remindersDao),
          eventsDaoProvider.overrideWithValue(eventsDao),
          notificationSchedulesDaoProvider.overrideWithValue(schedulesDao),
          notificationServiceProvider.overrideWithValue(service),
          notificationSchedulerProvider.overrideWithValue(scheduler),
          notificationsDaoProvider.overrideWithValue(notificationsDao),
          notificationSettingsDaoProvider.overrideWithValue(settingsDao),
        ],
      );
      addTearDown(container.dispose);

      final processor = container.read(notificationProcessorProvider);
      await processor.processAll();

      expect(verify(() => remindersDao.countUnsent(any())).callCount, 1);
      expect(verify(() => schedulesDao.countPending(any())).callCount, 1);
      verify(
        () => notificationsDao.deleteOldRead(any(), daysOld: 30),
      ).called(1);
    });

    test('cleanup uses custom cleanupDaysOld from settings', () async {
      final remindersDao = _MockEventRemindersDao();
      final eventsDao = _MockEventsDao();
      final schedulesDao = _MockNotificationSchedulesDao();
      final service = _MockNotificationService();
      final scheduler = _MockNotificationScheduler();
      final notificationsDao = _MockNotificationsDao();
      final settingsDao = _MockNotificationSettingsDao();

      when(() => remindersDao.countUnsent(any())).thenAnswer((_) async => 0);
      when(() => schedulesDao.countPending(any())).thenAnswer((_) async => 0);
      when(() => settingsDao.getByUser(any())).thenAnswer(
        (_) async => const NotificationSettings(
          id: 's1',
          userId: 'user-1',
          cleanupDaysOld: 7,
        ),
      );
      when(
        () => notificationsDao.deleteOldRead(
          any(),
          daysOld: any(named: 'daysOld'),
        ),
      ).thenAnswer((_) async => 5);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          eventRemindersDaoProvider.overrideWithValue(remindersDao),
          eventsDaoProvider.overrideWithValue(eventsDao),
          notificationSchedulesDaoProvider.overrideWithValue(schedulesDao),
          notificationServiceProvider.overrideWithValue(service),
          notificationSchedulerProvider.overrideWithValue(scheduler),
          notificationsDaoProvider.overrideWithValue(notificationsDao),
          notificationSettingsDaoProvider.overrideWithValue(settingsDao),
        ],
      );
      addTearDown(container.dispose);

      final processor = container.read(notificationProcessorProvider);
      await processor.processAll();

      // Should use cleanupDaysOld=7 from settings
      verify(() => notificationsDao.deleteOldRead(any(), daysOld: 7)).called(1);
    });

    test('cleanup does not break processAll when it fails', () async {
      final remindersDao = _MockEventRemindersDao();
      final eventsDao = _MockEventsDao();
      final schedulesDao = _MockNotificationSchedulesDao();
      final service = _MockNotificationService();
      final scheduler = _MockNotificationScheduler();
      final notificationsDao = _MockNotificationsDao();
      final settingsDao = _MockNotificationSettingsDao();

      when(() => remindersDao.countUnsent(any())).thenAnswer((_) async => 0);
      when(() => schedulesDao.countPending(any())).thenAnswer((_) async => 0);
      when(() => settingsDao.getByUser(any())).thenAnswer((_) async => null);
      when(
        () => notificationsDao.deleteOldRead(
          any(),
          daysOld: any(named: 'daysOld'),
        ),
      ).thenAnswer((_) async {
        throw Exception('DB locked');
      });

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          eventRemindersDaoProvider.overrideWithValue(remindersDao),
          eventsDaoProvider.overrideWithValue(eventsDao),
          notificationSchedulesDaoProvider.overrideWithValue(schedulesDao),
          notificationServiceProvider.overrideWithValue(service),
          notificationSchedulerProvider.overrideWithValue(scheduler),
          notificationsDaoProvider.overrideWithValue(notificationsDao),
          notificationSettingsDaoProvider.overrideWithValue(settingsDao),
        ],
      );
      addTearDown(container.dispose);

      final processor = container.read(notificationProcessorProvider);
      // Should complete without throwing despite cleanup failure
      await processor.processAll();
    });
  });
}
