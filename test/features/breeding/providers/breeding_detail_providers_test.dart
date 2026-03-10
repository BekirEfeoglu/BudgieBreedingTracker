import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/egg_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';

class MockBreedingPairRepository extends Mock
    implements BreedingPairRepository {}

class MockBirdRepository extends Mock implements BirdRepository {}

class MockEggRepository extends Mock implements EggRepository {}

class MockIncubationRepository extends Mock implements IncubationRepository {}

void main() {
  late MockBreedingPairRepository breedingPairRepo;
  late MockBirdRepository birdRepo;
  late MockEggRepository eggRepo;
  late MockIncubationRepository incubationRepo;

  setUp(() {
    breedingPairRepo = MockBreedingPairRepository();
    birdRepo = MockBirdRepository();
    eggRepo = MockEggRepository();
    incubationRepo = MockIncubationRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        breedingPairRepositoryProvider.overrideWithValue(breedingPairRepo),
        birdRepositoryProvider.overrideWithValue(birdRepo),
        eggRepositoryProvider.overrideWithValue(eggRepo),
        incubationRepositoryProvider.overrideWithValue(incubationRepo),
      ],
    );
  }

  group('breedingPairByIdProvider', () {
    test('delegates to repository.watchById', () async {
      const pair = BreedingPair(
        id: 'bp1',
        maleId: 'm1',
        femaleId: 'f1',
        userId: 'u1',
        status: BreedingStatus.active,
      );
      when(
        () => breedingPairRepo.watchById('bp1'),
      ).thenAnswer((_) => Stream.value(pair));

      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(breedingPairByIdProvider('bp1'), (_, __) {});
      final result = await container.read(
        breedingPairByIdProvider('bp1').future,
      );

      expect(result, isNotNull);
      expect(result!.id, 'bp1');
      expect(result.status, BreedingStatus.active);
    });

    test('returns null when pair not found', () async {
      when(
        () => breedingPairRepo.watchById('missing'),
      ).thenAnswer((_) => Stream.value(null));

      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(breedingPairByIdProvider('missing'), (_, __) {});
      final result = await container.read(
        breedingPairByIdProvider('missing').future,
      );

      expect(result, isNull);
    });
  });

  group('incubationsByPairProvider', () {
    test('delegates to repository.getByBreedingPair', () async {
      final incubations = [
        Incubation(
          id: 'i1',
          breedingPairId: 'bp1',
          userId: 'u1',
          status: IncubationStatus.active,
          startDate: DateTime(2024, 1, 1),
        ),
      ];
      when(
        () => incubationRepo.getByBreedingPair('bp1'),
      ).thenAnswer((_) async => incubations);

      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(
        incubationsByPairProvider('bp1').future,
      );

      expect(result, hasLength(1));
      expect(result.first.breedingPairId, 'bp1');
    });
  });

  group('eggsByIncubationProvider', () {
    test('delegates to repository.watchByIncubation', () async {
      final eggs = [
        Egg(
          id: 'e1',
          incubationId: 'i1',
          userId: 'u1',
          status: EggStatus.incubating,
          layDate: DateTime(2024, 1, 5),
        ),
      ];
      when(
        () => eggRepo.watchByIncubation('i1'),
      ).thenAnswer((_) => Stream.value(eggs));

      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(eggsByIncubationProvider('i1'), (_, __) {});
      final result = await container.read(
        eggsByIncubationProvider('i1').future,
      );

      expect(result, hasLength(1));
      expect(result.first.incubationId, 'i1');
    });
  });

  group('birdByIdProvider', () {
    test('delegates to repository.watchById', () async {
      const bird = Bird(
        id: 'b1',
        name: 'Tweety',
        gender: BirdGender.male,
        userId: 'u1',
      );
      when(
        () => birdRepo.watchById('b1'),
      ).thenAnswer((_) => Stream.value(bird));

      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(birdByIdProvider('b1'), (_, __) {});
      final result = await container.read(birdByIdProvider('b1').future);

      expect(result, isNotNull);
      expect(result!.name, 'Tweety');
    });
  });

  group('selectPrimaryIncubation', () {
    test('prefers most recent active incubation', () {
      final incubations = [
        Incubation(
          id: 'inc-old-active',
          userId: 'u1',
          status: IncubationStatus.active,
          startDate: DateTime(2024, 1, 1),
        ),
        Incubation(
          id: 'inc-new-completed',
          userId: 'u1',
          status: IncubationStatus.completed,
          startDate: DateTime(2024, 2, 1),
        ),
        Incubation(
          id: 'inc-new-active',
          userId: 'u1',
          status: IncubationStatus.active,
          startDate: DateTime(2024, 3, 1),
        ),
      ];

      final selected = selectPrimaryIncubation(incubations);
      expect(selected?.id, 'inc-new-active');
    });

    test('falls back to most recent incubation when none is active', () {
      final incubations = [
        Incubation(
          id: 'inc-1',
          userId: 'u1',
          status: IncubationStatus.completed,
          startDate: DateTime(2024, 1, 1),
        ),
        Incubation(
          id: 'inc-2',
          userId: 'u1',
          status: IncubationStatus.cancelled,
          startDate: DateTime(2024, 4, 1),
        ),
      ];

      final selected = selectPrimaryIncubation(incubations);
      expect(selected?.id, 'inc-2');
    });

    test('returns null for empty list', () {
      expect(selectPrimaryIncubation(const []), isNull);
    });
  });
}
