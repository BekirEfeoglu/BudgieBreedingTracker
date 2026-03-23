import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_settings_providers.dart';

import '../../../helpers/mocks.dart';

class _TestNotificationToggleSettingsNotifier
    extends NotificationToggleSettingsNotifier {
  @override
  NotificationToggleSettings build() => const NotificationToggleSettings();
}

void main() {
  late MockEggRepository eggRepo;
  late MockChickRepository chickRepo;
  late MockNotificationScheduler mockScheduler;
  late MockCalendarEventGenerator mockCalendarGen;

  setUp(() {
    eggRepo = MockEggRepository();
    chickRepo = MockChickRepository();
    mockScheduler = MockNotificationScheduler();
    mockCalendarGen = MockCalendarEventGenerator();
    registerFallbackValue(
      Egg(
        id: 'fallback',
        userId: 'user-1',
        layDate: DateTime(2024, 1, 1),
      ),
    );
    registerFallbackValue(
      Chick(
        id: 'fallback-chick',
        userId: 'user-1',
        hatchDate: DateTime(2024, 1, 1),
        gender: BirdGender.unknown,
        healthStatus: ChickHealthStatus.healthy,
      ),
    );

    // Stub notification/calendar mocks so they don't crash
    when(
      () => mockScheduler.scheduleEggTurningReminders(
        eggId: any(named: 'eggId'),
        startDate: any(named: 'startDate'),
        eggLabel: any(named: 'eggLabel'),
        settings: any(named: 'settings'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockScheduler.scheduleChickCareReminder(
        chickId: any(named: 'chickId'),
        chickLabel: any(named: 'chickLabel'),
        startDate: any(named: 'startDate'),
        intervalHours: any(named: 'intervalHours'),
        durationDays: any(named: 'durationDays'),
        settings: any(named: 'settings'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockCalendarGen.generateEggEvents(
        userId: any(named: 'userId'),
        layDate: any(named: 'layDate'),
        eggNumber: any(named: 'eggNumber'),
        incubationId: any(named: 'incubationId'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockCalendarGen.generateChickEvents(
        userId: any(named: 'userId'),
        hatchDate: any(named: 'hatchDate'),
        chickLabel: any(named: 'chickLabel'),
      ),
    ).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        eggRepositoryProvider.overrideWithValue(eggRepo),
        chickRepositoryProvider.overrideWithValue(chickRepo),
        currentUserIdProvider.overrideWithValue('test-user'),
        notificationSchedulerProvider.overrideWithValue(mockScheduler),
        notificationToggleSettingsProvider.overrideWith(
          _TestNotificationToggleSettingsNotifier.new,
        ),
        calendarEventGeneratorProvider.overrideWithValue(mockCalendarGen),
      ],
    );
  }

  group('EggActionsNotifier - Initial State', () {
    test('build returns default EggActionsState', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(eggActionsProvider);

      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
      expect(state.chickCreated, isFalse);
    });

    test('notifier is accessible from container', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final notifier = container.read(eggActionsProvider.notifier);
      expect(notifier, isNotNull);
    });
  });

  group('EggActionsNotifier - addEgg', () {
    test('transitions through loading to success on addEgg', () async {
      when(() => eggRepo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      final states = <EggActionsState>[];
      container.listen(eggActionsProvider, (_, next) => states.add(next));

      await container.read(eggActionsProvider.notifier).addEgg(
        incubationId: 'inc-1',
        layDate: DateTime(2024, 1, 10),
        eggNumber: 1,
      );

      // Should have at least loading and success states
      expect(states.any((s) => s.isLoading), isTrue);
      expect(states.last.isSuccess, isTrue);
      expect(states.last.isLoading, isFalse);
    });

    test('calls repository save with correct egg data', () async {
      when(() => eggRepo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).addEgg(
        incubationId: 'inc-1',
        layDate: DateTime(2024, 1, 10),
        eggNumber: 3,
        notes: 'Test notes',
      );

      final captured = verify(() => eggRepo.save(captureAny())).captured;
      expect(captured, hasLength(1));

      final savedEgg = captured.first as Egg;
      expect(savedEgg.incubationId, 'inc-1');
      expect(savedEgg.eggNumber, 3);
      expect(savedEgg.status, EggStatus.incubating);
      expect(savedEgg.notes, 'Test notes');
      expect(savedEgg.userId, 'test-user');
    });

    test('sets error state when save fails', () async {
      when(() => eggRepo.save(any())).thenThrow(
        Exception('Database error'),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).addEgg(
        incubationId: 'inc-1',
        layDate: DateTime(2024, 1, 10),
        eggNumber: 1,
      );

      final state = container.read(eggActionsProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNotNull);
      expect(state.error, contains('errors.unknown'));
    });

    test('generates unique id for each egg', () async {
      when(() => eggRepo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).addEgg(
        incubationId: 'inc-1',
        layDate: DateTime(2024, 1, 10),
        eggNumber: 1,
      );

      container.read(eggActionsProvider.notifier).reset();

      await container.read(eggActionsProvider.notifier).addEgg(
        incubationId: 'inc-1',
        layDate: DateTime(2024, 1, 11),
        eggNumber: 2,
      );

      final captured = verify(() => eggRepo.save(captureAny())).captured;
      final egg1 = captured[0] as Egg;
      final egg2 = captured[1] as Egg;
      expect(egg1.id, isNot(equals(egg2.id)));
    });

    test('addEgg without notes sets notes to null', () async {
      when(() => eggRepo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).addEgg(
        incubationId: 'inc-1',
        layDate: DateTime(2024, 1, 10),
        eggNumber: 1,
      );

      final captured = verify(() => eggRepo.save(captureAny())).captured;
      final savedEgg = captured.first as Egg;
      expect(savedEgg.notes, isNull);
    });
  });

  group('EggActionsNotifier - updateEggStatus', () {
    Egg testEgg({EggStatus status = EggStatus.laid}) => Egg(
      id: 'egg-1',
      userId: 'test-user',
      layDate: DateTime(2024, 1, 10),
      status: status,
      eggNumber: 1,
      createdAt: DateTime(2024, 1, 10),
      updatedAt: DateTime(2024, 1, 10),
    );

    test('transitions loading to success on status update', () async {
      when(() => eggRepo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).updateEggStatus(
        testEgg(),
        EggStatus.fertile,
      );

      final state = container.read(eggActionsProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isTrue);
    });

    test('sets fertileCheckDate when marking fertile', () async {
      when(() => eggRepo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).updateEggStatus(
        testEgg(),
        EggStatus.fertile,
      );

      final captured = verify(() => eggRepo.save(captureAny())).captured;
      final savedEgg = captured.first as Egg;
      expect(savedEgg.status, EggStatus.fertile);
      expect(savedEgg.fertileCheckDate, isNotNull);
    });

    test('sets discardDate when marking discarded', () async {
      when(() => eggRepo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).updateEggStatus(
        testEgg(),
        EggStatus.discarded,
      );

      final captured = verify(() => eggRepo.save(captureAny())).captured;
      final savedEgg = captured.first as Egg;
      expect(savedEgg.status, EggStatus.discarded);
      expect(savedEgg.discardDate, isNotNull);
    });

    test('sets hatchDate when marking hatched', () async {
      when(() => eggRepo.save(any())).thenAnswer((_) async {});
      when(() => chickRepo.getByEggId(any())).thenAnswer((_) async => null);
      when(() => chickRepo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).updateEggStatus(
        testEgg(status: EggStatus.incubating),
        EggStatus.hatched,
      );

      final captured = verify(() => eggRepo.save(captureAny())).captured;
      final savedEgg = captured.first as Egg;
      expect(savedEgg.status, EggStatus.hatched);
      expect(savedEgg.hatchDate, isNotNull);
    });

    test('sets chickCreated flag when hatching creates a chick', () async {
      when(() => eggRepo.save(any())).thenAnswer((_) async {});
      when(() => chickRepo.getByEggId(any())).thenAnswer((_) async => null);
      when(() => chickRepo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).updateEggStatus(
        testEgg(status: EggStatus.incubating),
        EggStatus.hatched,
      );

      final state = container.read(eggActionsProvider);
      expect(state.chickCreated, isTrue);
      expect(state.isSuccess, isTrue);
    });

    test('sets error state when status update fails', () async {
      when(() => eggRepo.save(any())).thenThrow(
        Exception('Save failed'),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).updateEggStatus(
        testEgg(),
        EggStatus.fertile,
      );

      final state = container.read(eggActionsProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.error, contains('errors.unknown'));
    });

    test('loading state is set before async operation', () async {
      final completer = Completer<void>();
      when(() => eggRepo.save(any())).thenAnswer((_) => completer.future);

      final container = makeContainer();
      addTearDown(container.dispose);

      final future = container.read(
        eggActionsProvider.notifier,
      ).updateEggStatus(testEgg(), EggStatus.fertile);

      final state = container.read(eggActionsProvider);
      expect(state.isLoading, isTrue);
      expect(state.isSuccess, isFalse);

      completer.complete();
      await future;
    });
  });

  group('EggActionsNotifier - reset', () {
    test('reset restores initial state after success', () async {
      when(() => eggRepo.remove('e1')).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).deleteEgg('e1');
      expect(container.read(eggActionsProvider).isSuccess, isTrue);

      container.read(eggActionsProvider.notifier).reset();

      final state = container.read(eggActionsProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNull);
      expect(state.chickCreated, isFalse);
    });

    test('reset restores initial state after error', () async {
      when(() => eggRepo.remove('e1')).thenThrow(StateError('fail'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).deleteEgg('e1');
      expect(container.read(eggActionsProvider).error, isNotNull);

      container.read(eggActionsProvider.notifier).reset();

      final state = container.read(eggActionsProvider);
      expect(state, const EggActionsState());
    });

    test('can perform new action after reset', () async {
      when(() => eggRepo.remove(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      // First action
      await container.read(eggActionsProvider.notifier).deleteEgg('e1');
      container.read(eggActionsProvider.notifier).reset();

      // Second action after reset
      await container.read(eggActionsProvider.notifier).deleteEgg('e2');

      final state = container.read(eggActionsProvider);
      expect(state.isSuccess, isTrue);
      expect(state.error, isNull);
    });
  });
}
