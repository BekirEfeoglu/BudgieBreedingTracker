@Tags(['e2e'])
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_form_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';

import '../helpers/e2e_test_harness.dart';

Future<T> _awaitProviderValue<T>(
  ProviderContainer container,
  dynamic provider,
) async {
  final completer = Completer<T>();
  late final ProviderSubscription<AsyncValue<T>> subscription;
  subscription = container.listen<AsyncValue<T>>(provider, (_, next) {
    if (next.hasValue && !completer.isCompleted) {
      completer.complete(next.requireValue);
      return;
    }
    if (next.hasError && !completer.isCompleted) {
      completer.completeError(
        next.error!,
        next.stackTrace ?? StackTrace.current,
      );
    }
  }, fireImmediately: true);
  try {
    return await completer.future.timeout(const Duration(seconds: 5));
  } finally {
    subscription.close();
  }
}

void main() {
  ensureE2EBinding();

  group('Breeding Flow E2E', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test(
      'GIVEN male and female birds WHEN a breeding pair is created THEN pair is active and repository.save is called',
      () async {
        final mockPairRepository = MockBreedingPairRepository();
        final mockIncubationRepository = MockIncubationRepository();
        final mockNotificationScheduler = MockNotificationScheduler();
        final mockCalendarGenerator = MockCalendarEventGenerator();

        when(() => mockPairRepository.save(any())).thenAnswer((_) async {});
        when(
          () => mockPairRepository.getAll(any()),
        ).thenAnswer((_) async => []);
        when(
          () => mockIncubationRepository.save(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockIncubationRepository.getAll(any()),
        ).thenAnswer((_) async => []);
        when(
          () => mockNotificationScheduler.scheduleIncubationMilestones(
            incubationId: any(named: 'incubationId'),
            startDate: any(named: 'startDate'),
            label: any(named: 'label'),
            settings: any(named: 'settings'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockNotificationScheduler.scheduleEggTurningReminders(
            eggId: any(named: 'eggId'),
            startDate: any(named: 'startDate'),
            eggLabel: any(named: 'eggLabel'),
            settings: any(named: 'settings'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockCalendarGenerator.generateIncubationEvents(
            userId: any(named: 'userId'),
            breedingPairId: any(named: 'breedingPairId'),
            startDate: any(named: 'startDate'),
            pairLabel: any(named: 'pairLabel'),
          ),
        ).thenAnswer((_) async {});

        final container = createTestContainer(
          overrides: [
            breedingPairRepositoryProvider.overrideWithValue(
              mockPairRepository,
            ),
            incubationRepositoryProvider.overrideWithValue(
              mockIncubationRepository,
            ),
            notificationSchedulerProvider.overrideWithValue(
              mockNotificationScheduler,
            ),
            calendarEventGeneratorProvider.overrideWithValue(
              mockCalendarGenerator,
            ),
          ],
        );
        addTearDown(container.dispose);

        final pairingDate = DateTime.now();

        await container
            .read(breedingFormStateProvider.notifier)
            .createBreeding(
              userId: 'test-user',
              maleId: 'male-1',
              femaleId: 'female-1',
              pairingDate: pairingDate,
              cageNumber: 'B2',
            );

        final savedPair =
            verify(() => mockPairRepository.save(captureAny())).captured.single
                as BreedingPair;
        expect(savedPair.status, BreedingStatus.active);
        expect(savedPair.cageNumber, 'B2');

        verify(() => mockIncubationRepository.save(any())).called(1);
        expect(container.read(breedingFormStateProvider).isSuccess, isTrue);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN active breeding pair WHEN detail providers are read THEN pair, incubation summary and clutch context are available',
      () async {
        final mockPairRepository = MockBreedingPairRepository();
        final mockIncubationRepository = MockIncubationRepository();

        final pair = BreedingPair(
          id: 'pair-1',
          userId: 'test-user',
          maleId: 'male-1',
          femaleId: 'female-1',
          status: BreedingStatus.active,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );
        final incubation = Incubation(
          id: 'inc-1',
          userId: 'test-user',
          breedingPairId: 'pair-1',
          startDate: DateTime.now().subtract(const Duration(days: 3)),
          expectedHatchDate: DateTime.now().add(const Duration(days: 15)),
          status: IncubationStatus.active,
        );

        when(
          () => mockPairRepository.watchById('pair-1'),
        ).thenAnswer((_) => Stream.value(pair));
        when(
          () => mockIncubationRepository.getByBreedingPair('pair-1'),
        ).thenAnswer((_) async => [incubation]);

        final container = createTestContainer(
          overrides: [
            breedingPairRepositoryProvider.overrideWithValue(
              mockPairRepository,
            ),
            incubationRepositoryProvider.overrideWithValue(
              mockIncubationRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final pairData = await _awaitProviderValue<BreedingPair?>(
          container,
          breedingPairByIdProvider('pair-1'),
        );
        final incubations = await _awaitProviderValue<List<Incubation>>(
          container,
          incubationsByPairProvider('pair-1'),
        );

        expect(pairData?.status, BreedingStatus.active);
        expect(incubations, hasLength(1));
        expect(incubations.first.daysElapsed, greaterThanOrEqualTo(0));
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN active clutch context WHEN 4 eggs are added THEN all eggs are incubating and hatch date calculation/calendar generation runs',
      () async {
        final mockEggRepository = MockEggRepository();
        final mockCalendarGenerator = MockCalendarEventGenerator();
        final mockNotificationScheduler = MockNotificationScheduler();

        when(() => mockEggRepository.save(any())).thenAnswer((_) async {});
        when(
          () => mockCalendarGenerator.generateEggEvents(
            userId: any(named: 'userId'),
            layDate: any(named: 'layDate'),
            eggNumber: any(named: 'eggNumber'),
            incubationId: any(named: 'incubationId'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockNotificationScheduler.scheduleEggTurningReminders(
            eggId: any(named: 'eggId'),
            startDate: any(named: 'startDate'),
            eggLabel: any(named: 'eggLabel'),
            settings: any(named: 'settings'),
          ),
        ).thenAnswer((_) async {});

        final container = createTestContainer(
          overrides: [
            eggRepositoryProvider.overrideWithValue(mockEggRepository),
            calendarEventGeneratorProvider.overrideWithValue(
              mockCalendarGenerator,
            ),
            notificationSchedulerProvider.overrideWithValue(
              mockNotificationScheduler,
            ),
          ],
        );
        addTearDown(container.dispose);

        final today = DateTime.now();
        for (var eggNo = 1; eggNo <= 4; eggNo++) {
          await container
              .read(eggActionsProvider.notifier)
              .addEgg(incubationId: 'inc-1', layDate: today, eggNumber: eggNo);
        }

        final savedEggs = verify(
          () => mockEggRepository.save(captureAny()),
        ).captured.cast<Egg>();
        expect(savedEggs, hasLength(4));
        expect(
          savedEggs.every((egg) => egg.status == EggStatus.incubating),
          isTrue,
        );
        expect(
          savedEggs.every(
            (egg) => egg.expectedHatchDate.difference(today).inDays == 18,
          ),
          isTrue,
        );
        verify(
          () => mockCalendarGenerator.generateEggEvents(
            userId: any(named: 'userId'),
            layDate: any(named: 'layDate'),
            eggNumber: any(named: 'eggNumber'),
            incubationId: any(named: 'incubationId'),
          ),
        ).called(4);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN eggs in management WHEN status changes fertile then hatched THEN egg save runs and chick creation is triggered',
      () async {
        final mockEggRepository = MockEggRepository();
        final mockChickRepository = MockChickRepository();

        when(() => mockEggRepository.save(any())).thenAnswer((_) async {});
        when(
          () => mockChickRepository.getByEggId('egg-1'),
        ).thenAnswer((_) async => null);
        when(() => mockChickRepository.save(any())).thenAnswer((_) async {});

        final container = createTestContainer(
          overrides: [
            eggRepositoryProvider.overrideWithValue(mockEggRepository),
            chickRepositoryProvider.overrideWithValue(mockChickRepository),
          ],
        );
        addTearDown(container.dispose);

        final egg = Egg(
          id: 'egg-1',
          userId: 'test-user',
          incubationId: 'inc-1',
          layDate: DateTime.now().subtract(const Duration(days: 1)),
          eggNumber: 1,
          status: EggStatus.incubating,
        );

        await container
            .read(eggActionsProvider.notifier)
            .updateEggStatus(egg, EggStatus.fertile);
        await container
            .read(eggActionsProvider.notifier)
            .updateEggStatus(
              egg.copyWith(status: EggStatus.fertile),
              EggStatus.hatched,
            );

        verify(() => mockEggRepository.save(any())).called(2);
        verify(() => mockChickRepository.save(any())).called(1);
        expect(container.read(eggActionsProvider).chickCreated, isTrue);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN active pair WHEN complete-breeding action runs THEN status is completed and separation date is persisted',
      () async {
        final mockPairRepository = MockBreedingPairRepository();
        final mockIncubationRepository = MockIncubationRepository();
        final mockNotificationScheduler = MockNotificationScheduler();

        final pair = BreedingPair(
          id: 'pair-1',
          userId: 'test-user',
          status: BreedingStatus.active,
          maleId: 'male-1',
          femaleId: 'female-1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        when(
          () => mockPairRepository.getById('pair-1'),
        ).thenAnswer((_) async => pair);
        when(() => mockPairRepository.save(any())).thenAnswer((_) async {});
        when(
          () => mockIncubationRepository.getByBreedingPairIds(any()),
        ).thenAnswer((_) async => []);
        when(
          () => mockNotificationScheduler.cancelIncubationMilestones(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockNotificationScheduler.cancelEggTurningReminders(any()),
        ).thenAnswer((_) async {});

        final container = createTestContainer(
          overrides: [
            breedingPairRepositoryProvider.overrideWithValue(
              mockPairRepository,
            ),
            incubationRepositoryProvider.overrideWithValue(
              mockIncubationRepository,
            ),
            notificationSchedulerProvider.overrideWithValue(
              mockNotificationScheduler,
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(breedingFormStateProvider.notifier)
            .completeBreeding('pair-1');

        final completedPair =
            verify(() => mockPairRepository.save(captureAny())).captured.single
                as BreedingPair;
        expect(completedPair.status, BreedingStatus.completed);
        expect(completedPair.separationDate, isNotNull);
      },
      timeout: e2eTimeout,
    );
  });
}
