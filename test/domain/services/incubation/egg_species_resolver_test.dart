import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/egg_species_resolver.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockIncubationRepository mockIncubationRepo;
  late MockBreedingPairRepository mockBreedingPairRepo;
  late MockBirdRepository mockBirdRepo;
  late MockClutchRepository mockClutchRepo;

  setUp(() {
    mockIncubationRepo = MockIncubationRepository();
    mockBreedingPairRepo = MockBreedingPairRepository();
    mockBirdRepo = MockBirdRepository();
    mockClutchRepo = MockClutchRepository();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        incubationRepositoryProvider.overrideWithValue(mockIncubationRepo),
        breedingPairRepositoryProvider.overrideWithValue(mockBreedingPairRepo),
        birdRepositoryProvider.overrideWithValue(mockBirdRepo),
        clutchRepositoryProvider.overrideWithValue(mockClutchRepo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Calls [resolveEggSpecies] inside a temporary provider so we get a [Ref].
  Future<Species> resolve(ProviderContainer container, Egg egg) async {
    final provider = FutureProvider<Species>((ref) => resolveEggSpecies(ref, egg));
    return container.read(provider.future);
  }

  Egg makeEgg({String? incubationId, String? clutchId}) => Egg(
    id: 'egg-1',
    layDate: DateTime(2026, 3, 1),
    userId: 'user-1',
    status: EggStatus.incubating,
    incubationId: incubationId,
    clutchId: clutchId,
  );

  Bird makeBird({
    required String id,
    required BirdGender gender,
    Species species = Species.budgie,
  }) =>
      Bird(
        id: id,
        userId: 'user-1',
        name: 'Bird-$id',
        gender: gender,
        species: species,
      );

  group('resolveEggSpecies', () {
    test('returns incubation species when known', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      when(() => mockIncubationRepo.getById('inc-1')).thenAnswer(
        (_) async => const Incubation(
          id: 'inc-1',
          userId: 'user-1',
          species: Species.canary,
        ),
      );

      final result = await resolve(container, makeEgg(incubationId: 'inc-1'));

      expect(result, Species.canary);
    });

    test('falls back to male bird via breeding pair', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      when(() => mockIncubationRepo.getById('inc-1')).thenAnswer(
        (_) async => const Incubation(
          id: 'inc-1',
          userId: 'user-1',
          breedingPairId: 'pair-1',
        ),
      );
      when(() => mockBreedingPairRepo.getById('pair-1')).thenAnswer(
        (_) async => const BreedingPair(
          id: 'pair-1',
          userId: 'user-1',
          maleId: 'male-1',
          femaleId: 'female-1',
        ),
      );
      when(() => mockBirdRepo.getById('male-1')).thenAnswer(
        (_) async => makeBird(
          id: 'male-1',
          gender: BirdGender.male,
          species: Species.cockatiel,
        ),
      );

      final result = await resolve(container, makeEgg(incubationId: 'inc-1'));

      expect(result, Species.cockatiel);
    });

    test('falls back to female bird when male species is unknown', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      when(() => mockIncubationRepo.getById('inc-1')).thenAnswer(
        (_) async => const Incubation(
          id: 'inc-1',
          userId: 'user-1',
          breedingPairId: 'pair-1',
        ),
      );
      when(() => mockBreedingPairRepo.getById('pair-1')).thenAnswer(
        (_) async => const BreedingPair(
          id: 'pair-1',
          userId: 'user-1',
          maleId: 'male-1',
          femaleId: 'female-1',
        ),
      );
      when(() => mockBirdRepo.getById('male-1')).thenAnswer(
        (_) async => makeBird(
          id: 'male-1',
          gender: BirdGender.male,
          species: Species.unknown,
        ),
      );
      when(() => mockBirdRepo.getById('female-1')).thenAnswer(
        (_) async => makeBird(
          id: 'female-1',
          gender: BirdGender.female,
          species: Species.finch,
        ),
      );

      final result = await resolve(container, makeEgg(incubationId: 'inc-1'));

      expect(result, Species.finch);
    });

    test('falls back to clutch birds when incubationId is null', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      when(() => mockClutchRepo.getById('clutch-1')).thenAnswer(
        (_) async => const Clutch(
          id: 'clutch-1',
          userId: 'user-1',
          maleBirdId: 'male-1',
          femaleBirdId: 'female-1',
        ),
      );
      when(() => mockBirdRepo.getById('male-1')).thenAnswer(
        (_) async => makeBird(
          id: 'male-1',
          gender: BirdGender.male,
          species: Species.canary,
        ),
      );

      final result = await resolve(container, makeEgg(clutchId: 'clutch-1'));

      expect(result, Species.canary);
    });

    test('falls back to clutch female bird when male is unknown', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      when(() => mockClutchRepo.getById('clutch-1')).thenAnswer(
        (_) async => const Clutch(
          id: 'clutch-1',
          userId: 'user-1',
          maleBirdId: 'male-1',
          femaleBirdId: 'female-1',
        ),
      );
      when(() => mockBirdRepo.getById('male-1')).thenAnswer(
        (_) async => makeBird(
          id: 'male-1',
          gender: BirdGender.male,
          species: Species.unknown,
        ),
      );
      when(() => mockBirdRepo.getById('female-1')).thenAnswer(
        (_) async => makeBird(
          id: 'female-1',
          gender: BirdGender.female,
          species: Species.cockatiel,
        ),
      );

      final result = await resolve(container, makeEgg(clutchId: 'clutch-1'));

      expect(result, Species.cockatiel);
    });

    test('tries clutch after incubation chain fails', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      when(() => mockIncubationRepo.getById('inc-1')).thenAnswer(
        (_) async => const Incubation(id: 'inc-1', userId: 'user-1'),
      );
      when(() => mockClutchRepo.getById('clutch-1')).thenAnswer(
        (_) async => const Clutch(
          id: 'clutch-1',
          userId: 'user-1',
          maleBirdId: 'male-1',
        ),
      );
      when(() => mockBirdRepo.getById('male-1')).thenAnswer(
        (_) async => makeBird(
          id: 'male-1',
          gender: BirdGender.male,
          species: Species.budgie,
        ),
      );

      final result = await resolve(
        container,
        makeEgg(incubationId: 'inc-1', clutchId: 'clutch-1'),
      );

      expect(result, Species.budgie);
    });

    test('returns unknown when both ids are null', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final result = await resolve(container, makeEgg());

      expect(result, Species.unknown);
    });

    test('returns unknown when incubation not found', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      when(() => mockIncubationRepo.getById('inc-1')).thenAnswer(
        (_) async => null,
      );

      final result = await resolve(container, makeEgg(incubationId: 'inc-1'));

      expect(result, Species.unknown);
    });

    test('returns unknown when clutch not found', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      when(() => mockClutchRepo.getById('clutch-1')).thenAnswer(
        (_) async => null,
      );

      final result = await resolve(container, makeEgg(clutchId: 'clutch-1'));

      expect(result, Species.unknown);
    });

    test('returns unknown when breeding pair has no birds', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      when(() => mockIncubationRepo.getById('inc-1')).thenAnswer(
        (_) async => const Incubation(
          id: 'inc-1',
          userId: 'user-1',
          breedingPairId: 'pair-1',
        ),
      );
      when(() => mockBreedingPairRepo.getById('pair-1')).thenAnswer(
        (_) async => const BreedingPair(
          id: 'pair-1',
          userId: 'user-1',
        ),
      );

      final result = await resolve(container, makeEgg(incubationId: 'inc-1'));

      expect(result, Species.unknown);
    });

    test('returns unknown when male bird not found and no female id', () async {
      final container = createContainer();
      addTearDown(container.dispose);
      when(() => mockIncubationRepo.getById('inc-1')).thenAnswer(
        (_) async => const Incubation(
          id: 'inc-1',
          userId: 'user-1',
          breedingPairId: 'pair-1',
        ),
      );
      when(() => mockBreedingPairRepo.getById('pair-1')).thenAnswer(
        (_) async => const BreedingPair(
          id: 'pair-1',
          userId: 'user-1',
          maleId: 'male-1',
        ),
      );
      when(() => mockBirdRepo.getById('male-1')).thenAnswer(
        (_) async => null,
      );

      final result = await resolve(container, makeEgg(incubationId: 'inc-1'));

      expect(result, Species.unknown);
    });
  });

  group('resolveEggSpeciesBatch', () {
    Future<Map<String, Species>> resolveBatch(
      ProviderContainer container,
      List<Egg> eggs,
    ) async {
      final provider = FutureProvider<Map<String, Species>>(
        (ref) => resolveEggSpeciesBatch(ref, eggs),
      );
      return container.read(provider.future);
    }

    test('resolves multiple eggs in one call', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      when(() => mockIncubationRepo.getById('inc-1')).thenAnswer(
        (_) async => const Incubation(
          id: 'inc-1',
          userId: 'user-1',
          species: Species.budgie,
        ),
      );
      when(() => mockIncubationRepo.getById('inc-2')).thenAnswer(
        (_) async => const Incubation(
          id: 'inc-2',
          userId: 'user-1',
          species: Species.canary,
        ),
      );

      final eggs = [
        makeEgg(incubationId: 'inc-1'),
        Egg(
          id: 'egg-2',
          layDate: DateTime(2026, 3, 2),
          userId: 'user-1',
          incubationId: 'inc-2',
        ),
      ];

      final result = await resolveBatch(container, eggs);

      expect(result['egg-1'], Species.budgie);
      expect(result['egg-2'], Species.canary);
    });

    test('deduplicates lookups for shared incubation', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      when(() => mockIncubationRepo.getById('inc-shared')).thenAnswer(
        (_) async => const Incubation(
          id: 'inc-shared',
          userId: 'user-1',
          species: Species.finch,
        ),
      );

      final eggs = [
        makeEgg(incubationId: 'inc-shared'),
        Egg(
          id: 'egg-2',
          layDate: DateTime(2026, 3, 2),
          userId: 'user-1',
          incubationId: 'inc-shared',
        ),
      ];

      final result = await resolveBatch(container, eggs);

      expect(result['egg-1'], Species.finch);
      expect(result['egg-2'], Species.finch);
      // Incubation should be fetched only once
      verify(() => mockIncubationRepo.getById('inc-shared')).called(1);
    });

    test('returns empty map for empty list', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final result = await resolveBatch(container, []);

      expect(result, isEmpty);
    });
  });
}
