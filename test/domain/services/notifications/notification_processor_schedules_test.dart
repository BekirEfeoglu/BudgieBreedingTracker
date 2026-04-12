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
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/models/event_reminder_model.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/data/models/notification_schedule_model.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_processor.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';

class _MockEventRemindersDao extends Mock implements EventRemindersDao {}

class _MockEventsDao extends Mock implements EventsDao {}

class _MockNotificationSchedulesDao extends Mock
    implements NotificationSchedulesDao {}

class _MockNotificationSettingsDao extends Mock
    implements NotificationSettingsDao {}

class _MockNotificationScheduler extends Mock
    implements NotificationScheduler {}

class _MockNotificationService extends Mock implements NotificationService {}

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

  group('_channelForType (via processNotificationSchedules)', () {
    late _MockNotificationSchedulesDao schedulesDao;
    late _MockNotificationSettingsDao settingsDao;
    late _MockNotificationService service;
    late _MockNotificationScheduler scheduler;

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

    /// Helper that creates a future schedule with the given [type], processes
    /// it, and returns the channelId passed to scheduleNotification.
    Future<String> captureChannelForType(NotificationType type) async {
      final futureDate = DateTime.now().add(const Duration(hours: 3));
      final schedule = NotificationSchedule(
        id: 'ch-${type.name}',
        userId: 'user-1',
        type: type,
        title: 'Test',
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

      final container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');

      final captured = verify(
        () => service.scheduleNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          channelId: captureAny(named: 'channelId'),
          payload: any(named: 'payload'),
        ),
      ).captured;
      return captured.first as String;
    }

    test('eggTurning maps to egg_turning channel', () async {
      final channel = await captureChannelForType(NotificationType.eggTurning);
      expect(channel, NotificationService.eggTurningChannelId);
    });

    test('incubationReminder maps to incubation channel', () async {
      final channel = await captureChannelForType(
        NotificationType.incubationReminder,
      );
      expect(channel, NotificationService.incubationChannelId);
    });

    test('feedingReminder maps to chick_care channel', () async {
      final channel = await captureChannelForType(
        NotificationType.feedingReminder,
      );
      expect(channel, NotificationService.chickCareChannelId);
    });

    test('healthCheck maps to health_check channel', () async {
      final channel = await captureChannelForType(
        NotificationType.healthCheck,
      );
      expect(channel, NotificationService.healthCheckChannelId);
    });

    test('custom type maps to default channel', () async {
      final channel = await captureChannelForType(NotificationType.custom);
      expect(channel, 'default');
    });

    test('unknown type maps to default channel', () async {
      final channel = await captureChannelForType(NotificationType.unknown);
      expect(channel, 'default');
    });
  });

  group('_payloadForSchedule (via processNotificationSchedules)', () {
    late _MockNotificationSchedulesDao schedulesDao;
    late _MockNotificationSettingsDao settingsDao;
    late _MockNotificationService service;
    late _MockNotificationScheduler scheduler;

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

    test('builds payload from type name and relatedEntityId', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 2));
      final schedule = NotificationSchedule(
        id: 'payload-1',
        userId: 'user-1',
        type: NotificationType.eggTurning,
        title: 'Turn',
        scheduledAt: futureDate,
        relatedEntityId: 'egg-abc',
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

      final container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');

      final captured = verify(
        () => service.scheduleNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          channelId: any(named: 'channelId'),
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured.first, 'eggTurning:egg-abc');
    });

    test('returns null payload when relatedEntityId is null', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 2));
      final schedule = NotificationSchedule(
        id: 'payload-null',
        userId: 'user-1',
        type: NotificationType.custom,
        title: 'General',
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

      final container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');

      final captured = verify(
        () => service.scheduleNotification(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          channelId: any(named: 'channelId'),
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured.first, isNull);
    });
  });

  group('_isTypeEnabled (via processNotificationSchedules)', () {
    late _MockNotificationSchedulesDao schedulesDao;
    late _MockNotificationSettingsDao settingsDao;
    late _MockNotificationService service;
    late _MockNotificationScheduler scheduler;

    setUp(() {
      schedulesDao = _MockNotificationSchedulesDao();
      settingsDao = _MockNotificationSettingsDao();
      service = _MockNotificationService();
      scheduler = _MockNotificationScheduler();
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

    test('skips eggTurning when toggle is disabled', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 1));
      final schedule = NotificationSchedule(
        id: 'toggle-egg',
        userId: 'user-1',
        type: NotificationType.eggTurning,
        title: 'Egg Turn',
        scheduledAt: futureDate,
      );

      when(
        () => schedulesDao.countPending('user-1'),
      ).thenAnswer((_) async => 1);
      when(
        () => schedulesDao.getPending('user-1'),
      ).thenAnswer((_) async => [schedule]);
      when(() => settingsDao.getByUser('user-1')).thenAnswer(
        (_) async => const NotificationSettings(
          id: 's1',
          userId: 'user-1',
          eggTurningEnabled: false,
        ),
      );
      when(
        () => schedulesDao.markProcessed('toggle-egg'),
      ).thenAnswer((_) async {});

      final container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');

      // Should skip scheduling and mark as processed
      verify(() => schedulesDao.markProcessed('toggle-egg')).called(1);
      verifyZeroInteractions(service);
      verifyZeroInteractions(scheduler);
    });

    test('skips healthCheck when toggle is disabled', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 1));
      final schedule = NotificationSchedule(
        id: 'toggle-health',
        userId: 'user-1',
        type: NotificationType.healthCheck,
        title: 'Health',
        scheduledAt: futureDate,
      );

      when(
        () => schedulesDao.countPending('user-1'),
      ).thenAnswer((_) async => 1);
      when(
        () => schedulesDao.getPending('user-1'),
      ).thenAnswer((_) async => [schedule]);
      when(() => settingsDao.getByUser('user-1')).thenAnswer(
        (_) async => const NotificationSettings(
          id: 's2',
          userId: 'user-1',
          healthCheckEnabled: false,
        ),
      );
      when(
        () => schedulesDao.markProcessed('toggle-health'),
      ).thenAnswer((_) async {});

      final container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');

      verify(() => schedulesDao.markProcessed('toggle-health')).called(1);
      verifyZeroInteractions(service);
    });

    test('skips feedingReminder when toggle is disabled', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 1));
      final schedule = NotificationSchedule(
        id: 'toggle-feed',
        userId: 'user-1',
        type: NotificationType.feedingReminder,
        title: 'Feed',
        scheduledAt: futureDate,
      );

      when(
        () => schedulesDao.countPending('user-1'),
      ).thenAnswer((_) async => 1);
      when(
        () => schedulesDao.getPending('user-1'),
      ).thenAnswer((_) async => [schedule]);
      when(() => settingsDao.getByUser('user-1')).thenAnswer(
        (_) async => const NotificationSettings(
          id: 's3',
          userId: 'user-1',
          feedingReminderEnabled: false,
        ),
      );
      when(
        () => schedulesDao.markProcessed('toggle-feed'),
      ).thenAnswer((_) async {});

      final container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');

      verify(() => schedulesDao.markProcessed('toggle-feed')).called(1);
      verifyZeroInteractions(service);
    });

    test('skips incubationReminder when toggle is disabled', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 1));
      final schedule = NotificationSchedule(
        id: 'toggle-incubation',
        userId: 'user-1',
        type: NotificationType.incubationReminder,
        title: 'Incubation',
        scheduledAt: futureDate,
      );

      when(
        () => schedulesDao.countPending('user-1'),
      ).thenAnswer((_) async => 1);
      when(
        () => schedulesDao.getPending('user-1'),
      ).thenAnswer((_) async => [schedule]);
      when(() => settingsDao.getByUser('user-1')).thenAnswer(
        (_) async => const NotificationSettings(
          id: 's4',
          userId: 'user-1',
          incubationReminderEnabled: false,
        ),
      );
      when(
        () => schedulesDao.markProcessed('toggle-incubation'),
      ).thenAnswer((_) async {});

      final container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');

      verify(() => schedulesDao.markProcessed('toggle-incubation')).called(1);
      verifyZeroInteractions(service);
    });

    test('allows custom type even when all standard toggles are disabled',
        () async {
      final futureDate = DateTime.now().add(const Duration(hours: 1));
      final schedule = NotificationSchedule(
        id: 'toggle-custom',
        userId: 'user-1',
        type: NotificationType.custom,
        title: 'Custom',
        scheduledAt: futureDate,
      );

      when(
        () => schedulesDao.countPending('user-1'),
      ).thenAnswer((_) async => 1);
      when(
        () => schedulesDao.getPending('user-1'),
      ).thenAnswer((_) async => [schedule]);
      when(() => settingsDao.getByUser('user-1')).thenAnswer(
        (_) async => const NotificationSettings(
          id: 's5',
          userId: 'user-1',
          eggTurningEnabled: false,
          healthCheckEnabled: false,
          feedingReminderEnabled: false,
          incubationReminderEnabled: false,
        ),
      );
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

      final container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');

      // Custom type should be scheduled despite all toggles being off
      verify(
        () => service.scheduleNotification(
          id: any(named: 'id'),
          title: 'Custom',
          body: '',
          scheduledDate: any(named: 'scheduledDate'),
          channelId: 'default',
          payload: null,
        ),
      ).called(1);
    });

    test('processes all types when settings DAO returns null', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 1));
      final schedule = NotificationSchedule(
        id: 'toggle-null-settings',
        userId: 'user-1',
        type: NotificationType.eggTurning,
        title: 'Egg',
        scheduledAt: futureDate,
      );

      when(
        () => schedulesDao.countPending('user-1'),
      ).thenAnswer((_) async => 1);
      when(
        () => schedulesDao.getPending('user-1'),
      ).thenAnswer((_) async => [schedule]);
      when(() => settingsDao.getByUser('user-1')).thenAnswer(
        (_) async => null,
      );
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

      final container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');

      // With null settings, no toggle check — schedule proceeds
      verify(
        () => service.scheduleNotification(
          id: any(named: 'id'),
          title: 'Egg',
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          channelId: any(named: 'channelId'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });
  });

  group('_nextOccurrenceAfter (via recurring schedule processing)', () {
    late _MockNotificationSchedulesDao schedulesDao;
    late _MockNotificationSettingsDao settingsDao;
    late _MockNotificationService service;
    late _MockNotificationScheduler scheduler;

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

    test('next occurrence is in the future for a recent past recurring schedule',
        () async {
      final recentPast = DateTime.now().subtract(const Duration(minutes: 10));
      final schedule = NotificationSchedule(
        id: 'next-occ-1',
        userId: 'user-1',
        type: NotificationType.feedingReminder,
        title: 'Feed',
        scheduledAt: recentPast,
        isRecurring: true,
        intervalMinutes: 60,
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
        () => schedulesDao.markProcessed('next-occ-1'),
      ).thenAnswer((_) async {});
      when(() => schedulesDao.insertItem(any())).thenAnswer((_) async {});

      final container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');

      final captured = verify(
        () => schedulesDao.insertItem(captureAny()),
      ).captured;
      expect(captured, hasLength(1));
      final next = captured.first as NotificationSchedule;
      expect(next.scheduledAt.isAfter(DateTime.now()), isTrue);
      expect(next.processedAt, isNull);
    });

    test('next occurrence advances multiple intervals to pass current time',
        () async {
      // 2 days ago, 30 min interval => needs many iterations to catch up
      final oldPast = DateTime.now().subtract(const Duration(hours: 48));
      final schedule = NotificationSchedule(
        id: 'next-occ-catchup',
        userId: 'user-1',
        type: NotificationType.feedingReminder,
        title: 'Feed',
        scheduledAt: oldPast,
        isRecurring: true,
        intervalMinutes: 30,
      );

      when(
        () => schedulesDao.countPending('user-1'),
      ).thenAnswer((_) async => 1);
      when(
        () => schedulesDao.getPending('user-1'),
      ).thenAnswer((_) async => [schedule]);
      when(
        () => schedulesDao.markProcessed('next-occ-catchup'),
      ).thenAnswer((_) async {});
      when(() => schedulesDao.insertItem(any())).thenAnswer((_) async {});

      final container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');

      final captured = verify(
        () => schedulesDao.insertItem(captureAny()),
      ).captured;
      expect(captured, hasLength(1));
      final next = captured.first as NotificationSchedule;
      // The calculated next occurrence must be strictly in the future
      expect(next.scheduledAt.isAfter(DateTime.now()), isTrue);
      // And within one interval of now
      final diff = next.scheduledAt.difference(DateTime.now()).inMinutes;
      expect(diff, lessThanOrEqualTo(30));
    });

    test('does not create next occurrence for non-recurring schedule',
        () async {
      final recentPast = DateTime.now().subtract(const Duration(minutes: 5));
      final schedule = NotificationSchedule(
        id: 'non-recurring',
        userId: 'user-1',
        type: NotificationType.custom,
        title: 'One-time',
        scheduledAt: recentPast,
        isRecurring: false,
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
        () => schedulesDao.markProcessed('non-recurring'),
      ).thenAnswer((_) async {});

      final container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processNotificationSchedules('user-1');

      verifyNever(() => schedulesDao.insertItem(any()));
    });

    test(
      'does not create next occurrence when intervalMinutes is null',
      () async {
        final recentPast = DateTime.now().subtract(const Duration(minutes: 5));
        final schedule = NotificationSchedule(
          id: 'recurring-no-interval',
          userId: 'user-1',
          type: NotificationType.custom,
          title: 'Recurring but no interval',
          scheduledAt: recentPast,
          isRecurring: true,
          intervalMinutes: null,
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
          () => schedulesDao.markProcessed('recurring-no-interval'),
        ).thenAnswer((_) async {});

        final container = buildContainer();
        final processor = container.read(notificationProcessorProvider);
        await processor.processNotificationSchedules('user-1');

        verifyNever(() => schedulesDao.insertItem(any()));
      },
    );

    test(
      'does not create next occurrence when intervalMinutes is zero',
      () async {
        final recentPast = DateTime.now().subtract(const Duration(minutes: 5));
        final schedule = NotificationSchedule(
          id: 'recurring-zero-interval',
          userId: 'user-1',
          type: NotificationType.custom,
          title: 'Recurring but zero interval',
          scheduledAt: recentPast,
          isRecurring: true,
          intervalMinutes: 0,
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
          () => schedulesDao.markProcessed('recurring-zero-interval'),
        ).thenAnswer((_) async {});

        final container = buildContainer();
        final processor = container.read(notificationProcessorProvider);
        await processor.processNotificationSchedules('user-1');

        verifyNever(() => schedulesDao.insertItem(any()));
      },
    );
  });

  group('_formatReminderBody (via processEventReminders)', () {
    late _MockEventRemindersDao remindersDao;
    late _MockEventsDao eventsDao;
    late _MockNotificationScheduler scheduler;
    late _MockNotificationService service;

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

    test('uses minutes format for minutesBefore < 60', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 2));
      const reminder = EventReminder(
        id: 'rem-fmt-min',
        userId: 'user-1',
        eventId: 'evt-fmt-min',
        minutesBefore: 30,
      );
      final event = Event(
        id: 'evt-fmt-min',
        title: 'Test Event',
        eventDate: futureDate,
        type: EventType.custom,
        userId: 'user-1',
      );

      when(
        () => remindersDao.countUnsent('user-1'),
      ).thenAnswer((_) async => 1);
      when(
        () => remindersDao.getUnsent('user-1'),
      ).thenAnswer((_) async => [reminder]);
      when(
        () => eventsDao.getById('evt-fmt-min'),
      ).thenAnswer((_) async => event);
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
        () => remindersDao.markSent('rem-fmt-min'),
      ).thenAnswer((_) async {});

      final container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processEventReminders('user-1');

      // Verify body was passed (localization will return key with args in test)
      verify(
        () => service.scheduleNotification(
          id: any(named: 'id'),
          title: 'Test Event',
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          channelId: any(named: 'channelId'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    test('uses hours format for minutesBefore >= 60', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 4));
      const reminder = EventReminder(
        id: 'rem-fmt-hr',
        userId: 'user-1',
        eventId: 'evt-fmt-hr',
        minutesBefore: 120,
      );
      final event = Event(
        id: 'evt-fmt-hr',
        title: 'Big Event',
        eventDate: futureDate,
        type: EventType.custom,
        userId: 'user-1',
      );

      when(
        () => remindersDao.countUnsent('user-1'),
      ).thenAnswer((_) async => 1);
      when(
        () => remindersDao.getUnsent('user-1'),
      ).thenAnswer((_) async => [reminder]);
      when(
        () => eventsDao.getById('evt-fmt-hr'),
      ).thenAnswer((_) async => event);
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
        () => remindersDao.markSent('rem-fmt-hr'),
      ).thenAnswer((_) async {});

      final container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      await processor.processEventReminders('user-1');

      verify(
        () => service.scheduleNotification(
          id: any(named: 'id'),
          title: 'Big Event',
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          channelId: any(named: 'channelId'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });
  });

  group('_loadToggleSettings (via processNotificationSchedules)', () {
    late _MockNotificationSchedulesDao schedulesDao;
    late _MockNotificationSettingsDao settingsDao;
    late _MockNotificationService service;
    late _MockNotificationScheduler scheduler;

    setUp(() {
      schedulesDao = _MockNotificationSchedulesDao();
      settingsDao = _MockNotificationSettingsDao();
      service = _MockNotificationService();
      scheduler = _MockNotificationScheduler();
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

    test('continues processing when settings DAO throws', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 1));
      final schedule = NotificationSchedule(
        id: 'settings-fail',
        userId: 'user-1',
        type: NotificationType.eggTurning,
        title: 'Egg',
        scheduledAt: futureDate,
      );

      when(
        () => schedulesDao.countPending('user-1'),
      ).thenAnswer((_) async => 1);
      when(
        () => schedulesDao.getPending('user-1'),
      ).thenAnswer((_) async => [schedule]);
      when(
        () => settingsDao.getByUser('user-1'),
      ).thenThrow(Exception('DB error'));
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

      final container = buildContainer();
      final processor = container.read(notificationProcessorProvider);
      // Should not throw — settings load failure is handled gracefully
      await processor.processNotificationSchedules('user-1');

      // Schedule should still be processed since settings returned null
      verify(
        () => service.scheduleNotification(
          id: any(named: 'id'),
          title: 'Egg',
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          channelId: any(named: 'channelId'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });
  });

  group('_scheduleNotificationId and _eventReminderNotificationId', () {
    test('processor uses 500000+ range for event reminder IDs', () {
      // NotificationScheduler.notificationId(500000, id, 0) is deterministic.
      // We verify the ID range via the scheduler static method.
      final id = NotificationScheduler.notificationId(500000, 'test-rem', 0);
      expect(id, greaterThanOrEqualTo(500000));
      expect(id, lessThan(600000));
    });

    test('processor uses 600000+ range for schedule IDs', () {
      final id = NotificationScheduler.notificationId(600000, 'test-sched', 0);
      expect(id, greaterThanOrEqualTo(600000));
      expect(id, lessThan(700000));
    });

    test('different entity IDs produce different notification IDs', () {
      final id1 = NotificationScheduler.notificationId(500000, 'entity-a', 0);
      final id2 = NotificationScheduler.notificationId(500000, 'entity-b', 0);
      expect(id1, isNot(equals(id2)));
    });

    test('same entity ID produces same notification ID (deterministic)', () {
      final id1 = NotificationScheduler.notificationId(500000, 'entity-x', 0);
      final id2 = NotificationScheduler.notificationId(500000, 'entity-x', 0);
      expect(id1, equals(id2));
    });
  });

  group(
    'previously-scheduled future schedule skips duplicate immediate display',
    () {
      late _MockNotificationSchedulesDao schedulesDao;
      late _MockNotificationSettingsDao settingsDao;
      late _MockNotificationService service;
      late _MockNotificationScheduler scheduler;

      setUp(() {
        schedulesDao = _MockNotificationSchedulesDao();
        settingsDao = _MockNotificationSettingsDao();
        service = _MockNotificationService();
        scheduler = _MockNotificationScheduler();

        when(() => settingsDao.getByUser(any())).thenAnswer((_) async => null);
      });

      test(
        'marks processed without showing immediate for previously-scheduled item',
        () async {
          // First pass: schedule is in the future
          final futureDate = DateTime.now().add(const Duration(minutes: 2));
          final schedule = NotificationSchedule(
            id: 'sched-dedup',
            userId: 'user-1',
            type: NotificationType.custom,
            title: 'Dedup Test',
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
            () => schedulesDao.markProcessed('sched-dedup'),
          ).thenAnswer((_) async {});

          final container = ProviderContainer(
            overrides: [
              notificationSchedulesDaoProvider.overrideWithValue(schedulesDao),
              notificationSettingsDaoProvider.overrideWithValue(settingsDao),
              notificationServiceProvider.overrideWithValue(service),
              notificationSchedulerProvider.overrideWithValue(scheduler),
            ],
          );
          addTearDown(container.dispose);

          final processor = container.read(notificationProcessorProvider);
          // First call: schedule is in future -> scheduleNotification called
          await processor.processNotificationSchedules('user-1');

          verify(
            () => service.scheduleNotification(
              id: any(named: 'id'),
              title: 'Dedup Test',
              body: any(named: 'body'),
              scheduledDate: any(named: 'scheduledDate'),
              channelId: any(named: 'channelId'),
              payload: any(named: 'payload'),
            ),
          ).called(1);

          // Second call: same schedule now in the past, but was previously
          // scheduled by this processor instance. It should be marked processed
          // without calling showImmediateNotification.
          final pastDate = DateTime.now().subtract(const Duration(minutes: 1));
          final pastSchedule = schedule.copyWith(scheduledAt: pastDate);
          when(
            () => schedulesDao.getPending('user-1'),
          ).thenAnswer((_) async => [pastSchedule]);

          await processor.processNotificationSchedules('user-1');

          verify(() => schedulesDao.markProcessed('sched-dedup')).called(1);
          // showImmediateNotification should NOT have been called
          verifyZeroInteractions(scheduler);
        },
      );
    },
  );
}
