import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/birds/bird_lifecycle_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';

import '../../../helpers/mocks.dart';

BreedingPair _pair({
  String id = 'pair-1',
  BreedingStatus status = BreedingStatus.active,
}) {
  return BreedingPair(
    id: id,
    userId: 'user-1',
    status: status,
    maleId: 'male-1',
    femaleId: 'female-1',
    pairingDate: DateTime(2025, 1, 1),
  );
}

Incubation _incubation({
  String id = 'inc-1',
  IncubationStatus status = IncubationStatus.active,
  String breedingPairId = 'pair-1',
  Species species = Species.budgie,
}) {
  return Incubation(
    id: id,
    userId: 'user-1',
    species: species,
    status: status,
    breedingPairId: breedingPairId,
    startDate: DateTime(2025, 1, 1),
  );
}

Egg _egg({String id = 'egg-1', String? incubationId = 'inc-1'}) {
  return Egg(
    id: id,
    userId: 'user-1',
    layDate: DateTime(2025, 1, 5),
    incubationId: incubationId,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBreedingPairRepository mockPairRepo;
  late MockIncubationRepository mockIncubationRepo;
  late MockEggRepository mockEggRepo;
  late MockEventRepository mockEventRepo;
  late MockNotificationScheduler mockScheduler;

  setUp(() {
    mockPairRepo = MockBreedingPairRepository();
    mockIncubationRepo = MockIncubationRepository();
    mockEggRepo = MockEggRepository();
    mockEventRepo = MockEventRepository();
    mockScheduler = MockNotificationScheduler();

    registerFallbackValue(_pair());
    registerFallbackValue(
      const Incubation(id: 'fallback', userId: 'fallback-user'),
    );
    registerFallbackValue(Species.unknown);

    when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
    when(() => mockIncubationRepo.save(any())).thenAnswer((_) async {});
    when(
      () => mockIncubationRepo.getByBreedingPairIds(any()),
    ).thenAnswer((_) async => []);
    when(() => mockEggRepo.getByIncubationIds(any())).thenAnswer((_) async => []);
    when(
      () => mockEventRepo.removeByBreedingPairIds(any()),
    ).thenAnswer((_) async => 0);
    when(
      () => mockScheduler.cancelIncubationMilestones(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockScheduler.cancelEggTurningReminders(
        any(),
        species: any(named: 'species'),
      ),
    ).thenAnswer((_) async {});
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        breedingPairRepositoryProvider.overrideWithValue(mockPairRepo),
        incubationRepositoryProvider.overrideWithValue(mockIncubationRepo),
        eggRepositoryProvider.overrideWithValue(mockEggRepo),
        eventRepositoryProvider.overrideWithValue(mockEventRepo),
        notificationSchedulerProvider.overrideWithValue(mockScheduler),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('BirdLifecycleService.cancelActiveBreedingsForBird', () {
    test('cancels active pair, incubation, reminders and events', () async {
      when(
        () => mockPairRepo.getByBirdId('bird-1'),
      ).thenAnswer((_) async => [_pair()]);
      when(
        () => mockIncubationRepo.getByBreedingPairIds(['pair-1']),
      ).thenAnswer((_) async => [_incubation()]);
      when(
        () => mockEggRepo.getByIncubationIds(['inc-1']),
      ).thenAnswer((_) async => [_egg()]);

      final container = createContainer();
      await container
          .read(birdLifecycleServiceProvider)
          .cancelActiveBreedingsForBird('bird-1');

      // Pair cancelled
      final savedPair =
          verify(() => mockPairRepo.save(captureAny())).captured.single
              as BreedingPair;
      expect(savedPair.status, BreedingStatus.cancelled);
      expect(savedPair.separationDate, isNotNull);

      // Incubation cancelled
      final savedInc =
          verify(() => mockIncubationRepo.save(captureAny())).captured.single
              as Incubation;
      expect(savedInc.status, IncubationStatus.cancelled);

      // Reminders cancelled (milestone + egg-turning with resolved species)
      verify(() => mockScheduler.cancelIncubationMilestones('inc-1')).called(1);
      verify(
        () => mockScheduler.cancelEggTurningReminders(
          'egg-1',
          species: Species.budgie,
        ),
      ).called(1);

      // Calendar/events cleaned up
      verify(() => mockEventRepo.removeByBreedingPairIds(['pair-1'])).called(1);
    });

    test('skips non-active pairs', () async {
      when(() => mockPairRepo.getByBirdId('bird-1')).thenAnswer(
        (_) async => [_pair(status: BreedingStatus.completed)],
      );

      final container = createContainer();
      await container
          .read(birdLifecycleServiceProvider)
          .cancelActiveBreedingsForBird('bird-1');

      verifyNever(() => mockPairRepo.save(any()));
      verifyNever(() => mockEventRepo.removeByBreedingPairIds(any()));
    });

    test('swallows errors so primary bird mutation is not undone', () async {
      when(
        () => mockPairRepo.getByBirdId('bird-1'),
      ).thenThrow(Exception('db down'));

      final container = createContainer();

      // Must not throw.
      await expectLater(
        container
            .read(birdLifecycleServiceProvider)
            .cancelActiveBreedingsForBird('bird-1'),
        completes,
      );
    });

    test('does not cancel reminders when there are no active incubations',
        () async {
      when(
        () => mockPairRepo.getByBirdId('bird-1'),
      ).thenAnswer((_) async => [_pair()]);
      when(
        () => mockIncubationRepo.getByBreedingPairIds(['pair-1']),
      ).thenAnswer((_) async => []);

      final container = createContainer();
      await container
          .read(birdLifecycleServiceProvider)
          .cancelActiveBreedingsForBird('bird-1');

      verifyNever(() => mockScheduler.cancelIncubationMilestones(any()));
      verifyNever(
        () => mockScheduler.cancelEggTurningReminders(
          any(),
          species: any(named: 'species'),
        ),
      );
      // Pair still cancelled + events still cleaned.
      verify(() => mockPairRepo.save(any())).called(1);
      verify(() => mockEventRepo.removeByBreedingPairIds(['pair-1'])).called(1);
    });
  });
}
