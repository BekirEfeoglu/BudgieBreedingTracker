import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_settings_providers.dart';

import '../../../helpers/mocks.dart';

class _TestNotificationToggleSettingsNotifier
    extends NotificationToggleSettingsNotifier {
  @override
  NotificationToggleSettings build() => const NotificationToggleSettings();
}

void main() {
  late MockEggRepository eggRepo;
  late MockChickRepository chickRepo;
  late MockIncubationRepository incubationRepo;
  late MockBreedingPairRepository breedingPairRepo;
  late MockBirdRepository birdRepo;
  late MockNotificationScheduler mockScheduler;
  late MockCalendarEventGenerator mockCalendarGen;

  setUpAll(() {
    registerFallbackValue(Species.budgie);
  });

  setUp(() {
    eggRepo = MockEggRepository();
    chickRepo = MockChickRepository();
    incubationRepo = MockIncubationRepository();
    breedingPairRepo = MockBreedingPairRepository();
    birdRepo = MockBirdRepository();
    mockScheduler = MockNotificationScheduler();
    mockCalendarGen = MockCalendarEventGenerator();

    registerFallbackValue(
      Egg(id: 'fallback', userId: 'u', layDate: DateTime(2024)),
    );
    registerFallbackValue(
      Chick(
        id: 'fallback',
        userId: 'u',
        hatchDate: DateTime(2024),
        gender: BirdGender.unknown,
        healthStatus: ChickHealthStatus.healthy,
      ),
    );

    // Default stubs for side-effect services
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
      () => mockScheduler.scheduleBandingReminders(
        chickId: any(named: 'chickId'),
        chickLabel: any(named: 'chickLabel'),
        hatchDate: any(named: 'hatchDate'),
        bandingDay: any(named: 'bandingDay'),
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
    when(
      () => mockCalendarGen.generateChickEvents(
        userId: any(named: 'userId'),
        hatchDate: any(named: 'hatchDate'),
        chickLabel: any(named: 'chickLabel'),
        chickId: any(named: 'chickId'),
        bandingDay: any(named: 'bandingDay'),
      ),
    ).thenAnswer((_) async {});

    when(() => incubationRepo.getById(any())).thenAnswer(
      (_) async => const Incubation(
        id: 'inc-1',
        userId: 'user-1',
        breedingPairId: 'pair-1',
      ),
    );
    when(() => eggRepo.getByIncubation(any())).thenAnswer(
      (_) async => [
        Egg(
          id: 'existing-egg',
          userId: 'test-user',
          incubationId: 'inc-1',
          layDate: DateTime(2024, 1, 9),
        ),
      ],
    );
    when(() => breedingPairRepo.getById(any())).thenAnswer(
      (_) async => const BreedingPair(
        id: 'pair-1',
        userId: 'user-1',
        maleId: 'male-1',
        femaleId: 'female-1',
      ),
    );
    when(() => birdRepo.getById(any())).thenAnswer(
      (_) async => const Bird(
        id: 'male-1',
        userId: 'user-1',
        name: 'Male',
        gender: BirdGender.male,
        species: Species.budgie,
      ),
    );
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        eggRepositoryProvider.overrideWithValue(eggRepo),
        chickRepositoryProvider.overrideWithValue(chickRepo),
        incubationRepositoryProvider.overrideWithValue(incubationRepo),
        breedingPairRepositoryProvider.overrideWithValue(breedingPairRepo),
        birdRepositoryProvider.overrideWithValue(birdRepo),
        currentUserIdProvider.overrideWithValue('test-user'),
        notificationSchedulerProvider.overrideWithValue(mockScheduler),
        notificationToggleSettingsProvider.overrideWith(
          _TestNotificationToggleSettingsNotifier.new,
        ),
        calendarEventGeneratorProvider.overrideWithValue(mockCalendarGen),
      ],
    );
  }

  Egg testEgg({
    String id = 'egg-1',
    EggStatus status = EggStatus.incubating,
    int? eggNumber,
    String? incubationId,
  }) => Egg(
    id: id,
    userId: 'test-user',
    incubationId: incubationId ?? 'inc-1',
    layDate: DateTime(2024, 1, 10),
    status: status,
    eggNumber: eggNumber ?? 1,
    createdAt: DateTime(2024, 1, 10),
    updatedAt: DateTime(2024, 1, 10),
  );

  group('EggActionsNotifier - deleteEgg', () {
    test('transitions to success on successful delete', () async {
      when(() => eggRepo.remove('egg-1')).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).deleteEgg('egg-1');

      final state = container.read(eggActionsProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isTrue);
      expect(state.error, isNull);
    });

    test('sets error when delete fails', () async {
      when(() => eggRepo.remove('egg-1')).thenThrow(Exception('Delete failed'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).deleteEgg('egg-1');

      final state = container.read(eggActionsProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.error, contains(l10n('errors.unknown')));
    });

    test('loading state is set before async operation', () async {
      final completer = Completer<void>();
      when(() => eggRepo.remove('egg-1')).thenAnswer((_) => completer.future);

      final container = makeContainer();
      addTearDown(container.dispose);

      final future = container
          .read(eggActionsProvider.notifier)
          .deleteEgg('egg-1');

      expect(container.read(eggActionsProvider).isLoading, isTrue);

      completer.complete();
      await future;
    });
  });

  group('EggActionsNotifier - updateEggStatus with hatching', () {
    test('skips chick creation when chick already exists for egg', () async {
      when(() => eggRepo.save(any())).thenAnswer((_) async {});
      when(() => chickRepo.getByEggId('egg-1')).thenAnswer(
        (_) async => Chick(
          id: 'existing-chick',
          userId: 'test-user',
          eggId: 'egg-1',
          hatchDate: DateTime(2024, 1, 28),
          gender: BirdGender.unknown,
          healthStatus: ChickHealthStatus.healthy,
        ),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(eggActionsProvider.notifier)
          .updateEggStatus(testEgg(), EggStatus.hatched);

      final state = container.read(eggActionsProvider);
      expect(state.isSuccess, isTrue);
      // Chick already existed, so chickCreated should be false
      expect(state.chickCreated, isFalse);
      verifyNever(() => chickRepo.save(any()));
    });

    test('no chickCreated flag for non-hatched status', () async {
      when(() => eggRepo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(eggActionsProvider.notifier)
          .updateEggStatus(testEgg(), EggStatus.fertile);

      final state = container.read(eggActionsProvider);
      expect(state.chickCreated, isFalse);
      expect(state.isSuccess, isTrue);
    });

    test(
      'sets warning when scheduler side-effect fails during addEgg',
      () async {
        when(() => eggRepo.save(any())).thenAnswer((_) async {});
        when(
          () => mockScheduler.scheduleEggTurningReminders(
            eggId: any(named: 'eggId'),
            startDate: any(named: 'startDate'),
            eggLabel: any(named: 'eggLabel'),
            species: any(named: 'species'),
            settings: any(named: 'settings'),
          ),
        ).thenThrow(Exception('scheduler down'));

        final container = makeContainer();
        addTearDown(container.dispose);

        await container
            .read(eggActionsProvider.notifier)
            .addEgg(
              incubationId: 'inc-1',
              layDate: DateTime(2024, 1, 10),
              eggNumber: 1,
            );

        final state = container.read(eggActionsProvider);
        expect(state.isSuccess, isTrue);
        expect(state.warning, isNotNull);
      },
    );

    test(
      'sets warning when calendar side-effect fails during addEgg',
      () async {
        when(() => eggRepo.save(any())).thenAnswer((_) async {});
        when(
          () => mockCalendarGen.generateEggEvents(
            userId: any(named: 'userId'),
            layDate: any(named: 'layDate'),
            eggNumber: any(named: 'eggNumber'),
            incubationId: any(named: 'incubationId'),
            species: any(named: 'species'),
          ),
        ).thenThrow(Exception('calendar down'));

        final container = makeContainer();
        addTearDown(container.dispose);

        await container
            .read(eggActionsProvider.notifier)
            .addEgg(
              incubationId: 'inc-1',
              layDate: DateTime(2024, 1, 10),
              eggNumber: 1,
            );

        final state = container.read(eggActionsProvider);
        expect(state.isSuccess, isTrue);
        expect(state.warning, isNotNull);
      },
    );
  });

  group('EggActionsNotifier - state transitions', () {
    test('multiple sequential operations work after reset', () async {
      when(() => eggRepo.save(any())).thenAnswer((_) async {});
      when(() => eggRepo.remove(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      // Add egg
      await container
          .read(eggActionsProvider.notifier)
          .addEgg(
            incubationId: 'inc-1',
            layDate: DateTime(2024, 1, 10),
            eggNumber: 1,
          );
      expect(container.read(eggActionsProvider).isSuccess, isTrue);

      // Reset
      container.read(eggActionsProvider.notifier).reset();
      expect(container.read(eggActionsProvider).isSuccess, isFalse);

      // Delete egg
      await container.read(eggActionsProvider.notifier).deleteEgg('egg-1');
      expect(container.read(eggActionsProvider).isSuccess, isTrue);
    });

    test('error state cleared on new operation', () async {
      when(() => eggRepo.remove('e1')).thenThrow(Exception('fail'));
      when(() => eggRepo.remove('e2')).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(eggActionsProvider.notifier).deleteEgg('e1');
      expect(container.read(eggActionsProvider).error, isNotNull);

      // New operation should clear previous error
      await container.read(eggActionsProvider.notifier).deleteEgg('e2');
      expect(container.read(eggActionsProvider).error, isNull);
      expect(container.read(eggActionsProvider).isSuccess, isTrue);
    });
  });
}
