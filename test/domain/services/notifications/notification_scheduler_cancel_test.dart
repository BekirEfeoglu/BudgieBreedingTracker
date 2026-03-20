import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_ids.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler_cancel.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';

class _MockNotificationService extends Mock implements NotificationService {}

class _TestSchedulerCancel with NotificationSchedulerCancel {
  _TestSchedulerCancel(this._service);

  final NotificationService _service;

  @override
  NotificationService get notificationService => _service;
}

void main() {
  late _MockNotificationService mockService;
  late _TestSchedulerCancel scheduler;

  setUp(() {
    mockService = _MockNotificationService();
    scheduler = _TestSchedulerCancel(mockService);

    when(() => mockService.cancel(any())).thenAnswer((_) async {});
    when(() => mockService.cancelAll()).thenAnswer((_) async {});
  });

  group('cancelEggTurningReminders', () {
    test('cancels expected number of notifications', () async {
      await scheduler.cancelEggTurningReminders('egg-1');

      // 18 days * 3 turning hours = 54 cancellations
      verify(() => mockService.cancel(any())).called(54);
    });

    test('uses eggTurningBaseId for ID generation', () async {
      final cancelledIds = <int>[];
      when(() => mockService.cancel(any())).thenAnswer((inv) async {
        cancelledIds.add(inv.positionalArguments[0] as int);
      });

      await scheduler.cancelEggTurningReminders('egg-1');

      for (final id in cancelledIds) {
        expect(
          id,
          greaterThanOrEqualTo(NotificationIds.eggTurningBaseId),
        );
        expect(
          id,
          lessThan(NotificationIds.eggTurningBaseId + 100000),
        );
      }
    });
  });

  group('cancelIncubationMilestones', () {
    test('cancels 5 milestone notifications', () async {
      await scheduler.cancelIncubationMilestones('incubation-1');

      verify(() => mockService.cancel(any())).called(5);
    });

    test('uses incubationBaseId for ID generation', () async {
      final cancelledIds = <int>[];
      when(() => mockService.cancel(any())).thenAnswer((inv) async {
        cancelledIds.add(inv.positionalArguments[0] as int);
      });

      await scheduler.cancelIncubationMilestones('incubation-1');

      for (final id in cancelledIds) {
        expect(
          id,
          greaterThanOrEqualTo(NotificationIds.incubationBaseId),
        );
        expect(
          id,
          lessThan(NotificationIds.incubationBaseId + 100000),
        );
      }
    });
  });

  group('cancelHealthCheckReminders', () {
    test('uses clamped maxDays (default 365 clamped to 100)', () async {
      await scheduler.cancelHealthCheckReminders('bird-1');

      // maxDays=365 is clamped to idsPerEntitySlot=100
      verify(() => mockService.cancel(any())).called(100);
    });

    test('respects custom maxDays within range', () async {
      await scheduler.cancelHealthCheckReminders('bird-1', maxDays: 10);

      verify(() => mockService.cancel(any())).called(10);
    });

    test('clamps maxDays to 0 for negative values', () async {
      await scheduler.cancelHealthCheckReminders('bird-1', maxDays: -5);

      verifyNever(() => mockService.cancel(any()));
    });

    test('uses healthCheckBaseId for ID generation', () async {
      final cancelledIds = <int>[];
      when(() => mockService.cancel(any())).thenAnswer((inv) async {
        cancelledIds.add(inv.positionalArguments[0] as int);
      });

      await scheduler.cancelHealthCheckReminders('bird-1', maxDays: 5);

      for (final id in cancelledIds) {
        expect(
          id,
          greaterThanOrEqualTo(NotificationIds.healthCheckBaseId),
        );
        expect(
          id,
          lessThan(NotificationIds.healthCheckBaseId + 100000),
        );
      }
    });
  });

  group('cancelChickCareReminders', () {
    test('cancels based on interval and duration', () async {
      await scheduler.cancelChickCareReminders(
        'chick-1',
        intervalHours: 4,
        durationDays: 2,
      );

      // 24/4 = 6 reminders per day * 2 days = 12
      verify(() => mockService.cancel(any())).called(12);
    });

    test('returns early for invalid intervalHours <= 0', () async {
      await scheduler.cancelChickCareReminders(
        'chick-1',
        intervalHours: 0,
      );

      verifyNever(() => mockService.cancel(any()));
    });

    test('returns early for intervalHours > 24', () async {
      await scheduler.cancelChickCareReminders(
        'chick-1',
        intervalHours: 25,
      );

      verifyNever(() => mockService.cancel(any()));
    });

    test('stops at idsPerEntitySlot limit', () async {
      // 24/1 = 24 reminders per day, 30 days = 720 total
      // But capped at idsPerEntitySlot = 100
      await scheduler.cancelChickCareReminders(
        'chick-1',
        intervalHours: 1,
        durationDays: 30,
      );

      verify(() => mockService.cancel(any())).called(100);
    });

    test('uses chickCareBaseId for ID generation', () async {
      final cancelledIds = <int>[];
      when(() => mockService.cancel(any())).thenAnswer((inv) async {
        cancelledIds.add(inv.positionalArguments[0] as int);
      });

      await scheduler.cancelChickCareReminders(
        'chick-1',
        intervalHours: 12,
        durationDays: 1,
      );

      for (final id in cancelledIds) {
        expect(
          id,
          greaterThanOrEqualTo(NotificationIds.chickCareBaseId),
        );
        expect(
          id,
          lessThan(NotificationIds.chickCareBaseId + 100000),
        );
      }
    });
  });

  group('cancelAll', () {
    test('delegates to notificationService.cancelAll', () async {
      await scheduler.cancelAll();

      verify(() => mockService.cancelAll()).called(1);
    });
  });
}
