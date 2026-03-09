import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notification_settings_dao.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_settings_providers.dart';

class MockNotificationService extends Mock implements NotificationService {}

class MockNotificationSettingsDao extends Mock
    implements NotificationSettingsDao {}

Future<void> _flushAsync() async {
  await Future<void>.delayed(const Duration(milliseconds: 1));
  await Future<void>.delayed(const Duration(milliseconds: 1));
}

const _testUserId = 'test-user-123';

void main() {
  late MockNotificationService service;
  late MockNotificationSettingsDao dao;

  setUpAll(() {
    registerFallbackValue(
      const NotificationSettings(id: 'fallback', userId: 'fallback'),
    );
  });

  setUp(() {
    service = MockNotificationService();
    dao = MockNotificationSettingsDao();
    when(
      () => service.cancelByIdRange(any(), any()),
    ).thenAnswer((_) async => 0);
    when(() => dao.upsert(any())).thenAnswer((_) async {});
  });

  ProviderContainer createContainer({NotificationSettings? initialSettings}) {
    when(
      () => dao.getByUser(_testUserId),
    ).thenAnswer((_) async => initialSettings);

    return ProviderContainer(
      overrides: [
        notificationServiceProvider.overrideWithValue(service),
        notificationSettingsDaoProvider.overrideWithValue(dao),
        currentUserIdProvider.overrideWithValue(_testUserId),
      ],
    );
  }

  group('notificationToggleSettingsProvider', () {
    test('loads initial values from Drift DAO', () async {
      final container = createContainer(
        initialSettings: const NotificationSettings(
          id: 'ns-1',
          userId: _testUserId,
          eggTurningEnabled: false,
          incubationReminderEnabled: true,
          feedingReminderEnabled: false,
          healthCheckEnabled: true,
        ),
      );
      addTearDown(container.dispose);

      final initial = container.read(notificationToggleSettingsProvider);
      expect(initial.eggTurning, isTrue);
      expect(initial.chickCare, isTrue);

      await _flushAsync();
      final loaded = container.read(notificationToggleSettingsProvider);

      expect(loaded.eggTurning, isFalse);
      expect(loaded.incubation, isTrue);
      expect(loaded.chickCare, isFalse);
      expect(loaded.healthCheck, isTrue);
      verifyNever(() => service.cancelByIdRange(any(), any()));
    });

    test(
      'setEggTurning(false) persists to DAO and cancels by ID range',
      () async {
        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(notificationToggleSettingsProvider.notifier)
            .setEggTurning(false);

        final state = container.read(notificationToggleSettingsProvider);
        expect(state.eggTurning, isFalse);
        verify(() => dao.upsert(any())).called(1);
        verify(
          () => service.cancelByIdRange(
            NotificationScheduler.eggTurningBaseId,
            NotificationScheduler.eggTurningBaseId + 100000,
          ),
        ).called(1);
      },
    );

    test('setIncubation(true) persists value and does not cancel', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(notificationToggleSettingsProvider.notifier)
          .setIncubation(true);

      final state = container.read(notificationToggleSettingsProvider);
      expect(state.incubation, isTrue);
      verify(() => dao.upsert(any())).called(1);
      verifyNever(() => service.cancelByIdRange(any(), any()));
    });

    test('setChickCare(false) cancels correct ID range', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(notificationToggleSettingsProvider.notifier)
          .setChickCare(false);

      final state = container.read(notificationToggleSettingsProvider);
      expect(state.chickCare, isFalse);
      verify(() => dao.upsert(any())).called(1);
      verify(
        () => service.cancelByIdRange(
          NotificationScheduler.chickCareBaseId,
          NotificationScheduler.chickCareBaseId + 100000,
        ),
      ).called(1);
    });

    test('setHealthCheck(false) cancels correct ID range', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(notificationToggleSettingsProvider.notifier)
          .setHealthCheck(false);

      final state = container.read(notificationToggleSettingsProvider);
      expect(state.healthCheck, isFalse);
      verify(() => dao.upsert(any())).called(1);
      verify(
        () => service.cancelByIdRange(
          NotificationScheduler.healthCheckBaseId,
          NotificationScheduler.healthCheckBaseId + 100000,
        ),
      ).called(1);
    });

    test('setChickCare(false) swallows cancellation errors', () async {
      when(
        () => service.cancelByIdRange(any(), any()),
      ).thenThrow(Exception('cancel failed'));

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(notificationToggleSettingsProvider.notifier)
          .setChickCare(false);

      final state = container.read(notificationToggleSettingsProvider);
      expect(state.chickCare, isFalse);
      verify(() => dao.upsert(any())).called(1);
      verify(() => service.cancelByIdRange(any(), any())).called(1);
    });

    test('defaults are all true when DAO returns null', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await _flushAsync();
      final state = container.read(notificationToggleSettingsProvider);

      expect(state.eggTurning, isTrue);
      expect(state.incubation, isTrue);
      expect(state.chickCare, isTrue);
      expect(state.healthCheck, isTrue);
    });
  });
}
