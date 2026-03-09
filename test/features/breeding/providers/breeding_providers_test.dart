import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/egg_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';

class MockBreedingPairRepository extends Mock
    implements BreedingPairRepository {}

class MockBirdRepository extends Mock implements BirdRepository {}

class MockEggRepository extends Mock implements EggRepository {}

class MockIncubationRepository extends Mock implements IncubationRepository {}

BreedingPair _pair({
  required String id,
  BreedingStatus status = BreedingStatus.active,
  String? maleId,
  String? femaleId,
  String? cage,
}) {
  return BreedingPair(
    id: id,
    userId: 'user-1',
    status: status,
    maleId: maleId,
    femaleId: femaleId,
    cageNumber: cage,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

Bird _bird({required String id, required String name}) {
  return Bird(
    id: id,
    userId: 'user-1',
    name: name,
    gender: BirdGender.unknown,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

Egg _egg({required String id, String? incubationId}) {
  return Egg(
    id: id,
    userId: 'user-1',
    layDate: DateTime(2024, 1, 1),
    incubationId: incubationId,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

Incubation _incubation({required String id, String? pairId}) {
  return Incubation(
    id: id,
    userId: 'user-1',
    breedingPairId: pairId,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  const userId = 'user-1';

  late MockBreedingPairRepository pairRepo;
  late MockBirdRepository birdRepo;
  late MockEggRepository eggRepo;
  late MockIncubationRepository incubationRepo;

  late List<BreedingPair> pairs;

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        breedingPairRepositoryProvider.overrideWithValue(pairRepo),
        birdRepositoryProvider.overrideWithValue(birdRepo),
        eggRepositoryProvider.overrideWithValue(eggRepo),
        incubationRepositoryProvider.overrideWithValue(incubationRepo),
        currentUserIdProvider.overrideWithValue(userId),
      ],
    );
  }

  setUp(() {
    pairRepo = MockBreedingPairRepository();
    birdRepo = MockBirdRepository();
    eggRepo = MockEggRepository();
    incubationRepo = MockIncubationRepository();

    pairs = [
      _pair(
        id: 'p1',
        status: BreedingStatus.active,
        maleId: 'm1',
        femaleId: 'f1',
        cage: 'C-01',
      ),
      _pair(
        id: 'p2',
        status: BreedingStatus.ongoing,
        maleId: 'm2',
        femaleId: 'f2',
        cage: 'C-02',
      ),
      _pair(
        id: 'p3',
        status: BreedingStatus.completed,
        maleId: 'm3',
        femaleId: 'f3',
        cage: 'C-03',
      ),
      _pair(
        id: 'p4',
        status: BreedingStatus.cancelled,
        maleId: 'm4',
        femaleId: 'f4',
        cage: 'C-04',
      ),
    ];

    when(() => pairRepo.watchAll(any())).thenAnswer((_) => Stream.value(pairs));
    when(
      () => pairRepo.watchActive(any()),
    ).thenAnswer((_) => Stream.value([pairs.first]));
    when(() => birdRepo.watchAll(any())).thenAnswer(
      (_) => Stream.value([
        _bird(id: 'm1', name: 'Apollo'),
        _bird(id: 'f1', name: 'Luna'),
        _bird(id: 'm2', name: 'Atlas'),
        _bird(id: 'f2', name: 'Nova'),
      ]),
    );
    when(() => eggRepo.watchAll(any())).thenAnswer(
      (_) => Stream.value([
        _egg(id: 'e1', incubationId: 'inc-1'),
        _egg(id: 'e2', incubationId: 'inc-1'),
        _egg(id: 'e3', incubationId: 'inc-2'),
        _egg(id: 'e4'),
      ]),
    );
    when(() => incubationRepo.watchAll(any())).thenAnswer(
      (_) => Stream.value([
        _incubation(id: 'inc-1', pairId: 'p1'),
        _incubation(id: 'inc-2', pairId: 'p2'),
        _incubation(id: 'inc-3', pairId: 'p1'),
        _incubation(id: 'inc-4'),
      ]),
    );
  });

  group('stream providers', () {
    test('breedingPairsStreamProvider delegates to watchAll', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(breedingPairsStreamProvider(userId), (_, __) {});
      final result = await container.read(
        breedingPairsStreamProvider(userId).future,
      );

      expect(result, hasLength(4));
      verify(() => pairRepo.watchAll(userId)).called(1);
    });

    test('activeBreedingPairsProvider delegates to watchActive', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(activeBreedingPairsProvider(userId), (_, __) {});
      final result = await container.read(
        activeBreedingPairsProvider(userId).future,
      );

      expect(result.map((e) => e.id), ['p1']);
      verify(() => pairRepo.watchActive(userId)).called(1);
    });
  });

  group('filteredBreedingPairsProvider', () {
    test('filters by all status variants', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(breedingFilterProvider.notifier).state =
          BreedingFilter.all;
      expect(
        container.read(filteredBreedingPairsProvider(pairs)),
        hasLength(4),
      );

      container.read(breedingFilterProvider.notifier).state =
          BreedingFilter.active;
      expect(
        container.read(filteredBreedingPairsProvider(pairs)).map((e) => e.id),
        ['p1'],
      );

      container.read(breedingFilterProvider.notifier).state =
          BreedingFilter.ongoing;
      expect(
        container.read(filteredBreedingPairsProvider(pairs)).map((e) => e.id),
        ['p2'],
      );

      container.read(breedingFilterProvider.notifier).state =
          BreedingFilter.completed;
      expect(
        container.read(filteredBreedingPairsProvider(pairs)).map((e) => e.id),
        ['p3'],
      );

      container.read(breedingFilterProvider.notifier).state =
          BreedingFilter.cancelled;
      expect(
        container.read(filteredBreedingPairsProvider(pairs)).map((e) => e.id),
        ['p4'],
      );
    });
  });

  group('searchedAndFilteredBreedingPairsProvider', () {
    test('matches cage number and bird names', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(birdsStreamProvider(userId), (_, __) {});
      await container.read(birdsStreamProvider(userId).future);

      container.read(breedingFilterProvider.notifier).state =
          BreedingFilter.all;

      container.read(breedingSearchQueryProvider.notifier).state = 'c-02';
      expect(
        container
            .read(searchedAndFilteredBreedingPairsProvider(pairs))
            .map((e) => e.id),
        ['p2'],
      );

      container.read(breedingSearchQueryProvider.notifier).state = 'apollo';
      expect(
        container
            .read(searchedAndFilteredBreedingPairsProvider(pairs))
            .map((e) => e.id),
        ['p1'],
      );

      container.read(breedingSearchQueryProvider.notifier).state = 'nova';
      expect(
        container
            .read(searchedAndFilteredBreedingPairsProvider(pairs))
            .map((e) => e.id),
        ['p2'],
      );
    });

    test('returns filtered list when query is empty', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.read(breedingFilterProvider.notifier).state =
          BreedingFilter.completed;
      container.read(breedingSearchQueryProvider.notifier).state = '';

      final result = container.read(
        searchedAndFilteredBreedingPairsProvider(pairs),
      );

      expect(result.map((e) => e.id), ['p3']);
    });
  });

  group('derived map providers', () {
    test(
      'incubationByPairMapProvider maps first incubation by pair id',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        // Ensure source stream emits before reading derived map.
        container.listen(allIncubationsStreamProvider(userId), (_, __) {});
        await container.read(allIncubationsStreamProvider(userId).future);

        final map = container.read(incubationByPairMapProvider(userId));

        expect(map.keys, containsAll(['p1', 'p2']));
        expect(map['p1']!.id, 'inc-1');
        expect(map['p2']!.id, 'inc-2');
      },
    );

    test('eggsByIncubationMapProvider groups eggs by incubation id', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      // Ensure source stream emits before reading derived map.
      container.listen(eggsStreamProvider(userId), (_, __) {});
      await container.read(eggsStreamProvider(userId).future);

      final map = container.read(eggsByIncubationMapProvider(userId));

      expect(map.keys, containsAll(['inc-1', 'inc-2']));
      expect(map['inc-1']!.map((e) => e.id), ['e1', 'e2']);
      expect(map['inc-2']!.map((e) => e.id), ['e3']);
    });
  });
}
