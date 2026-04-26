import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_toggle_settings.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockEggRepository mockEggRepo;
  late MockIncubationRepository mockIncubationRepo;
  late MockNotificationScheduler mockScheduler;
  late MockCalendarEventGenerator mockCalendarGen;

  setUp(() {
    mockEggRepo = MockEggRepository();
    mockIncubationRepo = MockIncubationRepository();
    mockScheduler = MockNotificationScheduler();
    mockCalendarGen = MockCalendarEventGenerator();
    registerFallbackValue(
      Egg(
        id: 'fallback-egg',
        userId: 'fallback-user',
        incubationId: 'fallback-inc',
        layDate: DateTime(2024, 1, 1),
      ),
    );
    registerFallbackValue(
      const Incubation(id: 'fallback-inc', userId: 'fallback-user'),
    );
    registerFallbackValue(Species.budgie);
    registerFallbackValue(const NotificationToggleSettings());
  });

  Egg makeEgg({
    String id = 'egg-1',
    String userId = 'user-1',
    String? incubationId,
    EggStatus status = EggStatus.incubating,
  }) {
    return Egg(
      id: id,
      userId: userId,
      incubationId: incubationId ?? 'inc-1',
      layDate: DateTime(2024, 1, 10),
      status: status,
    );
  }

  Future<void> flushAsync() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  Incubation makeIncubation({
    String id = 'inc-1',
    DateTime? startDate,
    DateTime? expectedHatchDate,
  }) {
    return Incubation(
      id: id,
      userId: 'user-1',
      species: Species.budgie,
      breedingPairId: 'pair-1',
      startDate: startDate,
      expectedHatchDate: expectedHatchDate,
    );
  }

  void stubEggSideEffects() {
    when(
      () => mockScheduler.scheduleEggTurningReminders(
        eggId: any(named: 'eggId'),
        startDate: any(named: 'startDate'),
        eggLabel: any(named: 'eggLabel'),
        species: any(named: 'species'),
        settings: any(named: 'settings'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockCalendarGen.generateEggEvents(
        userId: any(named: 'userId'),
        layDate: any(named: 'layDate'),
        eggNumber: any(named: 'eggNumber'),
        incubationId: any(named: 'incubationId'),
        species: any(named: 'species'),
      ),
    ).thenAnswer((_) async {});
  }

  ProviderContainer createActionContainer() {
    return ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        eggRepositoryProvider.overrideWithValue(mockEggRepo),
        incubationRepositoryProvider.overrideWithValue(mockIncubationRepo),
        notificationSchedulerProvider.overrideWithValue(mockScheduler),
        calendarEventGeneratorProvider.overrideWithValue(mockCalendarGen),
      ],
    );
  }

  group('eggsStreamProvider', () {
    test('emits list of eggs from repository', () async {
      final eggs = [makeEgg(id: 'e1'), makeEgg(id: 'e2')];
      when(
        () => mockEggRepo.watchAll('user-1'),
      ).thenAnswer((_) => Stream.value(eggs));

      final container = ProviderContainer(
        overrides: [eggRepositoryProvider.overrideWithValue(mockEggRepo)],
      );
      addTearDown(container.dispose);

      // Subscribe to trigger the stream
      container.listen(eggsStreamProvider('user-1'), (_, __) {});
      await flushAsync();

      final result = container.read(eggsStreamProvider('user-1'));
      expect(result.value, hasLength(2));
      expect(result.value!.first.id, 'e1');
      expect(result.value!.last.id, 'e2');
    });

    test('emits empty list when no eggs exist', () async {
      when(
        () => mockEggRepo.watchAll('user-1'),
      ).thenAnswer((_) => Stream.value([]));

      final container = ProviderContainer(
        overrides: [eggRepositoryProvider.overrideWithValue(mockEggRepo)],
      );
      addTearDown(container.dispose);

      container.listen(eggsStreamProvider('user-1'), (_, __) {});
      await flushAsync();

      final result = container.read(eggsStreamProvider('user-1'));
      expect(result.value, isEmpty);
    });

    test('emits error when repository stream errors', () async {
      when(
        () => mockEggRepo.watchAll('user-1'),
      ).thenAnswer((_) => Stream.error(Exception('DB failure')));

      final container = ProviderContainer(
        overrides: [eggRepositoryProvider.overrideWithValue(mockEggRepo)],
      );
      addTearDown(container.dispose);

      container.listen(eggsStreamProvider('user-1'), (_, __) {});
      await flushAsync();

      final result = container.read(eggsStreamProvider('user-1'));
      // Stream error should propagate - value should not be available
      expect(result.hasError, isTrue);
    });

    test('uses different streams for different user IDs', () async {
      when(
        () => mockEggRepo.watchAll('user-1'),
      ).thenAnswer((_) => Stream.value([makeEgg(id: 'e1')]));
      when(
        () => mockEggRepo.watchAll('user-2'),
      ).thenAnswer((_) => Stream.value([makeEgg(id: 'e2')]));

      final container = ProviderContainer(
        overrides: [eggRepositoryProvider.overrideWithValue(mockEggRepo)],
      );
      addTearDown(container.dispose);

      container.listen(eggsStreamProvider('user-1'), (_, __) {});
      container.listen(eggsStreamProvider('user-2'), (_, __) {});
      await flushAsync();

      expect(
        container.read(eggsStreamProvider('user-1')).value!.first.id,
        'e1',
      );
      expect(
        container.read(eggsStreamProvider('user-2')).value!.first.id,
        'e2',
      );

      verify(() => mockEggRepo.watchAll('user-1')).called(1);
      verify(() => mockEggRepo.watchAll('user-2')).called(1);
    });

    test('re-emits when stream emits new data', () async {
      final controller = StreamController<List<Egg>>.broadcast();

      when(
        () => mockEggRepo.watchAll('user-1'),
      ).thenAnswer((_) => controller.stream);

      final container = ProviderContainer(
        overrides: [eggRepositoryProvider.overrideWithValue(mockEggRepo)],
      );
      addTearDown(container.dispose);
      addTearDown(() {
        controller.close();
      });

      container.listen(eggsStreamProvider('user-1'), (_, __) {});
      await flushAsync();

      // Initially loading
      expect(container.read(eggsStreamProvider('user-1')), isA<AsyncLoading>());

      // Emit first data
      controller.add([makeEgg(id: 'e1')]);
      await flushAsync();
      expect(container.read(eggsStreamProvider('user-1')).value, hasLength(1));

      // Emit updated data
      controller.add([makeEgg(id: 'e1'), makeEgg(id: 'e2')]);
      await flushAsync();
      expect(container.read(eggsStreamProvider('user-1')).value, hasLength(2));
    });
  });

  group('eggsForIncubationProvider', () {
    test('emits eggs for a specific incubation', () async {
      final eggs = [
        makeEgg(id: 'e1', incubationId: 'inc-1'),
        makeEgg(id: 'e2', incubationId: 'inc-1'),
      ];
      when(
        () => mockEggRepo.watchByIncubation('inc-1'),
      ).thenAnswer((_) => Stream.value(eggs));

      final container = ProviderContainer(
        overrides: [eggRepositoryProvider.overrideWithValue(mockEggRepo)],
      );
      addTearDown(container.dispose);

      container.listen(eggsForIncubationProvider('inc-1'), (_, __) {});
      await flushAsync();

      final result = container.read(eggsForIncubationProvider('inc-1'));
      expect(result.value, hasLength(2));
      verify(() => mockEggRepo.watchByIncubation('inc-1')).called(1);
    });

    test('emits empty list when no eggs for incubation', () async {
      when(
        () => mockEggRepo.watchByIncubation('inc-99'),
      ).thenAnswer((_) => Stream.value([]));

      final container = ProviderContainer(
        overrides: [eggRepositoryProvider.overrideWithValue(mockEggRepo)],
      );
      addTearDown(container.dispose);

      container.listen(eggsForIncubationProvider('inc-99'), (_, __) {});
      await flushAsync();

      final result = container.read(eggsForIncubationProvider('inc-99'));
      expect(result.value, isEmpty);
    });

    test('propagates stream errors', () async {
      when(
        () => mockEggRepo.watchByIncubation('inc-1'),
      ).thenAnswer((_) => Stream.error(Exception('stream error')));

      final container = ProviderContainer(
        overrides: [eggRepositoryProvider.overrideWithValue(mockEggRepo)],
      );
      addTearDown(container.dispose);

      container.listen(eggsForIncubationProvider('inc-1'), (_, __) {});
      await flushAsync();

      final result = container.read(eggsForIncubationProvider('inc-1'));
      expect(result.hasError, isTrue);
    });
  });

  group('EggActionsState', () {
    test('default state has correct values', () {
      const state = EggActionsState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.warning, isNull);
      expect(state.isSuccess, isFalse);
      expect(state.chickCreated, isFalse);
    });

    test('copyWith updates specified fields', () {
      const state = EggActionsState();
      final updated = state.copyWith(
        isLoading: true,
        error: 'test error',
        warning: 'test warning',
        isSuccess: true,
        chickCreated: true,
      );

      expect(updated.isLoading, isTrue);
      expect(updated.error, 'test error');
      expect(updated.warning, 'test warning');
      expect(updated.isSuccess, isTrue);
      expect(updated.chickCreated, isTrue);
    });

    test('copyWith clears error and warning when null', () {
      const state = EggActionsState(error: 'err', warning: 'warn');
      final updated = state.copyWith(error: null, warning: null);

      expect(updated.error, isNull);
      expect(updated.warning, isNull);
    });

    test('copyWith preserves unspecified fields', () {
      const state = EggActionsState(isLoading: true);
      final updated = state.copyWith(isSuccess: true);

      expect(updated.isLoading, isTrue);
      expect(updated.isSuccess, isTrue);
    });
  });

  group('EggActionsNotifier.addEgg', () {
    test('starts incubation from the first egg lay date', () async {
      final layDate = DateTime(2025, 2, 1);
      final incubation = makeIncubation(
        startDate: DateTime(2025, 1, 1),
        expectedHatchDate: DateTime(2025, 1, 19),
      );
      when(
        () => mockEggRepo.getByIncubation('inc-1'),
      ).thenAnswer((_) async => []);
      when(() => mockEggRepo.save(any())).thenAnswer((_) async {});
      when(
        () => mockIncubationRepo.getById('inc-1'),
      ).thenAnswer((_) async => incubation);
      when(() => mockIncubationRepo.save(any())).thenAnswer((_) async {});
      stubEggSideEffects();

      final container = createActionContainer();
      addTearDown(container.dispose);

      await container
          .read(eggActionsProvider.notifier)
          .addEgg(incubationId: 'inc-1', layDate: layDate, eggNumber: 1);

      final savedIncubation =
          verify(() => mockIncubationRepo.save(captureAny())).captured.single
              as Incubation;
      expect(savedIncubation.startDate, layDate);
      expect(savedIncubation.expectedHatchDate, DateTime(2025, 2, 19));
    });

    test('does not restart incubation when eggs already exist', () async {
      final incubation = makeIncubation(startDate: DateTime(2025, 2, 1));
      when(
        () => mockEggRepo.getByIncubation('inc-1'),
      ).thenAnswer((_) async => [makeEgg()]);
      when(() => mockEggRepo.save(any())).thenAnswer((_) async {});
      when(
        () => mockIncubationRepo.getById('inc-1'),
      ).thenAnswer((_) async => incubation);
      stubEggSideEffects();

      final container = createActionContainer();
      addTearDown(container.dispose);

      await container
          .read(eggActionsProvider.notifier)
          .addEgg(
            incubationId: 'inc-1',
            layDate: DateTime(2025, 2, 3),
            eggNumber: 2,
          );

      verifyNever(() => mockIncubationRepo.save(any()));
    });
  });
}
