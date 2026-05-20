import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_form_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_settings_providers.dart';
import '../../../helpers/mocks.dart';

class _MockToggleNotifier extends NotificationToggleSettingsNotifier {
  @override
  NotificationToggleSettings build() => const NotificationToggleSettings();
}

void main() {
  late MockHealthRecordRepository repo;
  late MockNotificationScheduler scheduler;
  final date = DateTime(2024, 6, 1);

  setUp(() {
    repo = MockHealthRecordRepository();
    scheduler = MockNotificationScheduler();
    registerFallbackValue(
      HealthRecord(
        id: '',
        date: date,
        type: HealthRecordType.checkup,
        title: '',
        userId: '',
      ),
    );
  });

  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [
      healthRecordRepositoryProvider.overrideWithValue(repo),
      notificationSchedulerProvider.overrideWithValue(scheduler),
      notificationToggleSettingsProvider.overrideWith(_MockToggleNotifier.new),
    ],
  );

  void stubScheduler() {
    when(
      () => scheduler.scheduleHealthCheckReminder(
        recordId: any(named: 'recordId'),
        birdId: any(named: 'birdId'),
        birdName: any(named: 'birdName'),
        hour: any(named: 'hour'),
        durationDays: any(named: 'durationDays'),
        settings: any(named: 'settings'),
      ),
    ).thenAnswer((_) async {});
  }

  group('HealthRecordFormState', () {
    test('initial state has default values', () {
      const s = HealthRecordFormState();
      expect(s.isLoading, isFalse);
      expect(s.error, isNull);
      expect(s.isSuccess, isFalse);
    });
    test('copyWith updates fields and clears error', () {
      expect(
        const HealthRecordFormState().copyWith(isLoading: true).isLoading,
        isTrue,
      );
      expect(const HealthRecordFormState().copyWith(error: 'e').error, 'e');
      expect(
        const HealthRecordFormState()
            .copyWith(error: 'e')
            .copyWith(error: null)
            .error,
        isNull,
      );
      expect(
        const HealthRecordFormState().copyWith(isSuccess: true).isSuccess,
        isTrue,
      );
    });
    test('copyWith preserves unchanged fields', () {
      final u = const HealthRecordFormState(
        isLoading: true,
      ).copyWith(isSuccess: true);
      expect(u.isLoading, isTrue);
      expect(u.isSuccess, isTrue);
    });
  });

  group('HealthRecordFormNotifier', () {
    group('createRecord', () {
      test('sets isSuccess on success', () async {
        when(() => repo.save(any())).thenAnswer((_) async {});
        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(healthRecordFormStateProvider.notifier)
            .createRecord(
              userId: 'u1',
              title: 'Checkup',
              type: HealthRecordType.checkup,
              date: date,
            );
        final s = c.read(healthRecordFormStateProvider);
        expect(s.isSuccess, isTrue);
        expect(s.isLoading, isFalse);
      });

      test('calls repo.save with correct data', () async {
        when(() => repo.save(any())).thenAnswer((_) async {});
        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(healthRecordFormStateProvider.notifier)
            .createRecord(
              userId: 'u1',
              title: 'Vaccine',
              type: HealthRecordType.vaccination,
              date: date,
              birdId: 'b1',
              description: 'Annual',
              cost: 50.0,
            );
        final r =
            verify(() => repo.save(captureAny())).captured.single
                as HealthRecord;
        expect(r.userId, 'u1');
        expect(r.title, 'Vaccine');
        expect(r.type, HealthRecordType.vaccination);
        expect(r.birdId, 'b1');
        expect(r.description, 'Annual');
        expect(r.cost, 50.0);
      });

      test('sets error on failure', () async {
        when(() => repo.save(any())).thenThrow(Exception('DB error'));
        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(healthRecordFormStateProvider.notifier)
            .createRecord(
              userId: 'u1',
              title: 'X',
              type: HealthRecordType.checkup,
              date: date,
            );
        final s = c.read(healthRecordFormStateProvider);
        expect(s.error, isNotNull);
        expect(s.isLoading, isFalse);
        expect(s.isSuccess, isFalse);
      });

      test('clears previous error on new attempt', () async {
        when(() => repo.save(any())).thenThrow(Exception('fail'));
        final c = makeContainer();
        addTearDown(c.dispose);
        final n = c.read(healthRecordFormStateProvider.notifier);
        await n.createRecord(
          userId: 'u',
          title: 't',
          type: HealthRecordType.checkup,
          date: date,
        );
        expect(c.read(healthRecordFormStateProvider).error, isNotNull);
        when(() => repo.save(any())).thenAnswer((_) async {});
        await n.createRecord(
          userId: 'u',
          title: 't',
          type: HealthRecordType.checkup,
          date: date,
        );
        expect(c.read(healthRecordFormStateProvider).error, isNull);
        expect(c.read(healthRecordFormStateProvider).isSuccess, isTrue);
      });

      test('schedules reminders when birdId is provided', () async {
        when(() => repo.save(any())).thenAnswer((_) async {});
        stubScheduler();
        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(healthRecordFormStateProvider.notifier)
            .createRecord(
              userId: 'u1',
              title: 'Checkup',
              type: HealthRecordType.checkup,
              date: date,
              birdId: 'b1',
            );
        verify(
          () => scheduler.scheduleHealthCheckReminder(
            recordId: any(named: 'recordId'),
            birdId: 'b1',
            birdName: 'Checkup',
            hour: 9,
            durationDays: any(named: 'durationDays'),
            settings: any(named: 'settings'),
          ),
        ).called(1);
      });

      test('does NOT schedule reminders when birdId is null', () async {
        when(() => repo.save(any())).thenAnswer((_) async {});
        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(healthRecordFormStateProvider.notifier)
            .createRecord(
              userId: 'u1',
              title: 'Checkup',
              type: HealthRecordType.checkup,
              date: date,
            );
        verifyNever(
          () => scheduler.scheduleHealthCheckReminder(
            recordId: any(named: 'recordId'),
            birdId: any(named: 'birdId'),
            birdName: any(named: 'birdName'),
            hour: any(named: 'hour'),
            durationDays: any(named: 'durationDays'),
            settings: any(named: 'settings'),
          ),
        );
      });
    });

    group('updateRecord', () {
      final record = HealthRecord(
        id: 'hr-1',
        date: date,
        type: HealthRecordType.illness,
        title: 'Flu',
        userId: 'u1',
      );
      test('sets isSuccess on success', () async {
        when(() => repo.save(any())).thenAnswer((_) async {});
        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(healthRecordFormStateProvider.notifier)
            .updateRecord(record);
        expect(c.read(healthRecordFormStateProvider).isSuccess, isTrue);
      });
      test('sets error on failure', () async {
        when(() => repo.save(any())).thenThrow(Exception('fail'));
        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(healthRecordFormStateProvider.notifier)
            .updateRecord(record);
        expect(c.read(healthRecordFormStateProvider).error, isNotNull);
        expect(c.read(healthRecordFormStateProvider).isLoading, isFalse);
      });
      test('calls repo.save with updated timestamp', () async {
        when(() => repo.save(any())).thenAnswer((_) async {});
        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(healthRecordFormStateProvider.notifier)
            .updateRecord(record);
        final r =
            verify(() => repo.save(captureAny())).captured.single
                as HealthRecord;
        expect(r.updatedAt, isNotNull);
      });
    });

    group('deleteRecord', () {
      test('sets isSuccess on success', () async {
        when(() => repo.remove(any())).thenAnswer((_) async {});
        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(healthRecordFormStateProvider.notifier)
            .deleteRecord('hr-1');
        expect(c.read(healthRecordFormStateProvider).isSuccess, isTrue);
      });
      test('sets error on failure', () async {
        when(() => repo.remove(any())).thenThrow(Exception('fail'));
        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(healthRecordFormStateProvider.notifier)
            .deleteRecord('hr-1');
        expect(c.read(healthRecordFormStateProvider).error, isNotNull);
        expect(c.read(healthRecordFormStateProvider).isLoading, isFalse);
      });
      test('calls repo.remove with correct id', () async {
        when(() => repo.remove(any())).thenAnswer((_) async {});
        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(healthRecordFormStateProvider.notifier)
            .deleteRecord('hr-42');
        verify(() => repo.remove('hr-42')).called(1);
      });
    });

    group('reset', () {
      test('resets state to defaults after success', () async {
        when(() => repo.save(any())).thenAnswer((_) async {});
        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(healthRecordFormStateProvider.notifier)
            .createRecord(
              userId: 'u',
              title: 't',
              type: HealthRecordType.checkup,
              date: date,
            );
        expect(c.read(healthRecordFormStateProvider).isSuccess, isTrue);
        c.read(healthRecordFormStateProvider.notifier).reset();
        final s = c.read(healthRecordFormStateProvider);
        expect(s.isLoading, isFalse);
        expect(s.error, isNull);
        expect(s.isSuccess, isFalse);
      });
      test('resets state to defaults after error', () async {
        when(() => repo.save(any())).thenThrow(Exception('fail'));
        final c = makeContainer();
        addTearDown(c.dispose);
        await c
            .read(healthRecordFormStateProvider.notifier)
            .createRecord(
              userId: 'u',
              title: 't',
              type: HealthRecordType.checkup,
              date: date,
            );
        expect(c.read(healthRecordFormStateProvider).error, isNotNull);
        c.read(healthRecordFormStateProvider.notifier).reset();
        final s = c.read(healthRecordFormStateProvider);
        expect(s.isLoading, isFalse);
        expect(s.error, isNull);
        expect(s.isSuccess, isFalse);
      });
    });
  });
}
