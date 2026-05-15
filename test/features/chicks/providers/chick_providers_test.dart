import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_form_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';

import '../../../helpers/mocks.dart';

Chick _chick({
  required String id,
  ChickHealthStatus healthStatus = ChickHealthStatus.healthy,
  DateTime? hatchDate,
  DateTime? weanDate,
  String? birdId,
  String? name,
  String? ring,
}) {
  return Chick(
    id: id,
    userId: 'user-1',
    healthStatus: healthStatus,
    hatchDate: hatchDate ?? DateTime(2024, 1, 1),
    weanDate: weanDate,
    birdId: birdId,
    name: name,
    ringNumber: ring,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

Future<void> _flushEventQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  late MockChickRepository chickRepo;
  late MockBirdRepository birdRepo;
  late MockEggRepository eggRepo;
  late MockIncubationRepository incubationRepo;
  late MockBreedingPairRepository breedingPairRepo;
  late MockClutchRepository clutchRepo;
  late MockGrowthMeasurementRepository growthRepo;

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        chickRepositoryProvider.overrideWithValue(chickRepo),
        birdRepositoryProvider.overrideWithValue(birdRepo),
        eggRepositoryProvider.overrideWithValue(eggRepo),
        incubationRepositoryProvider.overrideWithValue(incubationRepo),
        breedingPairRepositoryProvider.overrideWithValue(breedingPairRepo),
        clutchRepositoryProvider.overrideWithValue(clutchRepo),
        growthMeasurementRepositoryProvider.overrideWithValue(growthRepo),
      ],
    );
  }

  setUpAll(() {
    registerFallbackValue(
      const Chick(
        id: 'fallback-chick',
        userId: 'user-1',
        healthStatus: ChickHealthStatus.healthy,
      ),
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    chickRepo = MockChickRepository();
    birdRepo = MockBirdRepository();
    eggRepo = MockEggRepository();
    incubationRepo = MockIncubationRepository();
    breedingPairRepo = MockBreedingPairRepository();
    clutchRepo = MockClutchRepository();
    growthRepo = MockGrowthMeasurementRepository();
    registerFallbackValue(
      const Bird(
        id: 'fallback',
        name: 'Fallback',
        gender: BirdGender.unknown,
        userId: 'user-1',
      ),
    );

    when(() => chickRepo.watchAll(any())).thenAnswer(
      (_) => Stream.value([
        _chick(
          id: 'c1',
          healthStatus: ChickHealthStatus.healthy,
          name: 'Lemon',
          ring: 'R-1',
        ),
        _chick(
          id: 'c2',
          healthStatus: ChickHealthStatus.sick,
          name: 'Sky',
          ring: 'R-2',
        ),
      ]),
    );
    when(() => chickRepo.save(any())).thenAnswer((_) async {});
    when(() => birdRepo.save(any())).thenAnswer((_) async {});
  });

  group('growthMeasurementsByChickProvider', () {
    test('watches growth measurements for a chick', () async {
      final measurements = [
        GrowthMeasurement(
          id: 'gm-1',
          chickId: 'chick-1',
          weight: 3.2,
          measurementDate: DateTime(2025, 3, 2),
          userId: 'user-1',
        ),
      ];
      when(
        () => growthRepo.watchByChick('chick-1'),
      ).thenAnswer((_) => Stream.value(measurements));

      final container = makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(
        growthMeasurementsByChickProvider('chick-1').future,
      );

      expect(result, measurements);
    });
  });

  group('chicksStreamProvider', () {
    test('delegates to repository.watchAll', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(chicksStreamProvider('user-1'), (_, __) {});
      final chicks = await container.read(
        chicksStreamProvider('user-1').future,
      );

      expect(chicks, hasLength(2));
      verify(() => chickRepo.watchAll('user-1')).called(1);
    });
  });

  group('filter/search providers', () {
    test('filteredChicksProvider respects filter state', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final chicks = [
        _chick(id: 'healthy', healthStatus: ChickHealthStatus.healthy),
        _chick(id: 'sick', healthStatus: ChickHealthStatus.sick),
        _chick(id: 'deceased', healthStatus: ChickHealthStatus.deceased),
      ];

      container.read(chickFilterProvider.notifier).state = ChickFilter.healthy;
      expect(container.read(filteredChicksProvider(chicks)).map((e) => e.id), [
        'healthy',
      ]);

      container.read(chickFilterProvider.notifier).state = ChickFilter.sick;
      expect(container.read(filteredChicksProvider(chicks)).map((e) => e.id), [
        'sick',
      ]);

      container.read(chickFilterProvider.notifier).state = ChickFilter.deceased;
      expect(container.read(filteredChicksProvider(chicks)).map((e) => e.id), [
        'deceased',
      ]);

      container.read(chickFilterProvider.notifier).state = ChickFilter.unweaned;
      final unweanedChicks = [
        _chick(id: 'unweaned'),
        _chick(id: 'promoted', birdId: 'bird-1'),
      ];
      expect(
        container.read(filteredChicksProvider(unweanedChicks)).map((e) => e.id),
        ['unweaned'],
      );
    });

    test('searchedAndFilteredChicksProvider applies query', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final chicks = [
        _chick(id: 'c1', name: 'Lemon', ring: 'TR-001'),
        _chick(id: 'c2', name: 'Sky', ring: 'TR-ABC'),
      ];
      container.read(chickFilterProvider.notifier).state = ChickFilter.all;
      container.read(chickSearchQueryProvider.notifier).state = 'abc';

      final result = container.read(searchedAndFilteredChicksProvider(chicks));
      expect(result.single.id, 'c2');
    });
  });

  group('chick parent providers', () {
    test(
      'batched lookup updates when related records arrive after the egg',
      () async {
        final eggController = StreamController<List<Egg>>.broadcast();
        final incubationController =
            StreamController<List<Incubation>>.broadcast();
        final clutchController = StreamController<List<Clutch>>.broadcast();
        final pairController = StreamController<List<BreedingPair>>.broadcast();
        final birdController = StreamController<List<Bird>>.broadcast();
        addTearDown(() async {
          await eggController.close();
          await incubationController.close();
          await clutchController.close();
          await pairController.close();
          await birdController.close();
        });

        when(
          () => eggRepo.watchAll('user-1'),
        ).thenAnswer((_) => eggController.stream);
        when(
          () => incubationRepo.watchAll('user-1'),
        ).thenAnswer((_) => incubationController.stream);
        when(
          () => clutchRepo.watchAll('user-1'),
        ).thenAnswer((_) => clutchController.stream);
        when(
          () => breedingPairRepo.watchAll('user-1'),
        ).thenAnswer((_) => pairController.stream);
        when(
          () => birdRepo.watchAll('user-1'),
        ).thenAnswer((_) => birdController.stream);

        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(chickParentsByEggProvider('user-1'), (_, __) {});
        await _flushEventQueue();

        eggController.add([
          Egg(
            id: 'egg-1',
            userId: 'user-1',
            incubationId: 'inc-1',
            layDate: DateTime(2024, 1),
          ),
        ]);
        incubationController.add(const []);
        clutchController.add(const []);
        pairController.add(const []);
        birdController.add(const []);
        await _flushEventQueue();

        incubationController.add(const [
          Incubation(
            id: 'inc-1',
            userId: 'user-1',
            species: Species.canary,
            breedingPairId: 'pair-1',
          ),
        ]);
        pairController.add(const [
          BreedingPair(
            id: 'pair-1',
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            cageNumber: 'A-17',
          ),
        ]);
        birdController.add(const [
          Bird(
            id: 'male-1',
            name: 'Mavi',
            gender: BirdGender.male,
            userId: 'user-1',
          ),
          Bird(
            id: 'female-1',
            name: 'Sarı',
            gender: BirdGender.female,
            userId: 'user-1',
          ),
        ]);
        await _flushEventQueue();

        final result = container
            .read(chickParentsByEggProvider('user-1'))
            .requireValue;
        expect(result['egg-1']?.maleName, 'Mavi');
        expect(result['egg-1']?.femaleName, 'Sarı');
        expect(result['egg-1']?.cageNumber, 'A-17');
      },
    );

    test(
      'batched lookup resolves parents and cage through clutch fallback',
      () async {
        when(() => eggRepo.watchAll('user-1')).thenAnswer(
          (_) => Stream.value([
            Egg(
              id: 'egg-1',
              userId: 'user-1',
              clutchId: 'clutch-1',
              layDate: DateTime(2024, 1),
            ),
          ]),
        );
        when(
          () => incubationRepo.watchAll('user-1'),
        ).thenAnswer((_) => Stream.value([]));
        when(() => clutchRepo.watchAll('user-1')).thenAnswer(
          (_) => Stream.value(const [
            Clutch(
              id: 'clutch-1',
              userId: 'user-1',
              breedingId: 'pair-1',
              maleBirdId: 'male-1',
              femaleBirdId: 'female-1',
            ),
          ]),
        );
        when(() => breedingPairRepo.watchAll('user-1')).thenAnswer(
          (_) => Stream.value(const [
            BreedingPair(
              id: 'pair-1',
              userId: 'user-1',
              maleId: 'male-1',
              femaleId: 'female-1',
              cageNumber: 'A-17',
            ),
          ]),
        );
        when(() => birdRepo.watchAll('user-1')).thenAnswer(
          (_) => Stream.value(const [
            Bird(
              id: 'male-1',
              name: 'Mavi',
              gender: BirdGender.male,
              userId: 'user-1',
            ),
            Bird(
              id: 'female-1',
              name: 'Sarı',
              gender: BirdGender.female,
              userId: 'user-1',
            ),
          ]),
        );

        final container = makeContainer();
        addTearDown(container.dispose);

        container.listen(chickParentsByEggProvider('user-1'), (_, __) {});
        final result = await container.read(
          chickParentsByEggProvider('user-1').future,
        );

        expect(result['egg-1']?.maleName, 'Mavi');
        expect(result['egg-1']?.femaleName, 'Sarı');
        expect(result['egg-1']?.cageNumber, 'A-17');
      },
    );
  });

  group('chick form actions', () {
    test('promoteToBird inherits species from egg incubation chain', () async {
      final chick = _chick(
        id: 'c1',
        name: 'Lemon',
        ring: 'R-1',
      ).copyWith(eggId: 'egg-1');
      when(() => eggRepo.getById('egg-1')).thenAnswer(
        (_) async => Egg(
          id: 'egg-1',
          userId: 'user-1',
          incubationId: 'inc-1',
          layDate: DateTime(2024, 1, 1),
        ),
      );
      when(() => incubationRepo.getById('inc-1')).thenAnswer(
        (_) async => const Incubation(
          id: 'inc-1',
          userId: 'user-1',
          species: Species.unknown,
          breedingPairId: 'pair-1',
        ),
      );
      when(() => breedingPairRepo.getById('pair-1')).thenAnswer(
        (_) async => const BreedingPair(
          id: 'pair-1',
          userId: 'user-1',
          maleId: 'male-1',
          femaleId: 'female-1',
        ),
      );
      when(() => birdRepo.getById('male-1')).thenAnswer(
        (_) async => const Bird(
          id: 'male-1',
          name: 'Father',
          gender: BirdGender.male,
          userId: 'user-1',
          species: Species.canary,
        ),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .promoteToBird(chick);

      final savedBird =
          verify(() => birdRepo.save(captureAny())).captured.single as Bird;
      expect(savedBird.species, Species.canary);
    });
  });
}
