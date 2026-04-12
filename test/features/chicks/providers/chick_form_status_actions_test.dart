import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_form_providers.dart';

import '../../../helpers/mocks.dart';

Chick _chick({
  String id = 'chick-1',
  String? name,
  String? eggId,
  String? ringNumber,
  BirdGender gender = BirdGender.unknown,
  ChickHealthStatus healthStatus = ChickHealthStatus.healthy,
  DateTime? hatchDate,
  DateTime? weanDate,
  String? birdId,
}) {
  return Chick(
    id: id,
    userId: 'user-1',
    name: name,
    eggId: eggId,
    ringNumber: ringNumber,
    gender: gender,
    healthStatus: healthStatus,
    hatchDate: hatchDate ?? DateTime(2025, 3, 1),
    weanDate: weanDate,
    birdId: birdId,
    createdAt: DateTime(2025, 3, 1),
    updatedAt: DateTime(2025, 3, 1),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockChickRepository mockChickRepo;
  late MockBirdRepository mockBirdRepo;
  late MockEggRepository mockEggRepo;
  late MockIncubationRepository mockIncubationRepo;
  late MockBreedingPairRepository mockBreedingPairRepo;
  late MockClutchRepository mockClutchRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockChickRepo = MockChickRepository();
    mockBirdRepo = MockBirdRepository();
    mockEggRepo = MockEggRepository();
    mockIncubationRepo = MockIncubationRepository();
    mockBreedingPairRepo = MockBreedingPairRepository();
    mockClutchRepo = MockClutchRepository();

    registerFallbackValue(_chick());
    registerFallbackValue(
      const Bird(
        id: 'b',
        userId: 'u',
        name: 'B',
        gender: BirdGender.unknown,
      ),
    );
    registerFallbackValue(
      Egg(id: 'e', userId: 'u', layDate: DateTime(2024)),
    );

    // Default stub for birdRepo.getById (species resolution)
    when(() => mockBirdRepo.getById(any())).thenAnswer(
      (_) async => const Bird(
        id: 'bird-any',
        userId: 'user-1',
        name: 'Bird',
        gender: BirdGender.unknown,
        species: Species.budgie,
      ),
    );
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        chickRepositoryProvider.overrideWithValue(mockChickRepo),
        birdRepositoryProvider.overrideWithValue(mockBirdRepo),
        eggRepositoryProvider.overrideWithValue(mockEggRepo),
        incubationRepositoryProvider.overrideWithValue(mockIncubationRepo),
        breedingPairRepositoryProvider.overrideWithValue(mockBreedingPairRepo),
        clutchRepositoryProvider.overrideWithValue(mockClutchRepo),
      ],
    );
  }

  group('ChickFormStatusActions - markAsWeaned', () {
    test('sets wean date and saves successfully', () async {
      final chick = _chick();
      when(() => mockChickRepo.getById('chick-1'))
          .thenAnswer((_) async => chick);
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      final weanDate = DateTime(2025, 4, 15);
      await container
          .read(chickFormStateProvider.notifier)
          .markAsWeaned('chick-1', weanDate: weanDate);

      final state = container.read(chickFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);

      final captured =
          verify(() => mockChickRepo.save(captureAny())).captured;
      final saved = captured.first as Chick;
      expect(saved.weanDate, weanDate);
    });

    test('uses current date when weanDate is not provided', () async {
      final chick = _chick();
      when(() => mockChickRepo.getById('chick-1'))
          .thenAnswer((_) async => chick);
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      final before = DateTime.now();
      await container
          .read(chickFormStateProvider.notifier)
          .markAsWeaned('chick-1');
      final after = DateTime.now();

      final captured =
          verify(() => mockChickRepo.save(captureAny())).captured;
      final saved = captured.first as Chick;
      expect(saved.weanDate, isNotNull);
      expect(
        saved.weanDate!.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        saved.weanDate!.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('is a no-op when chick not found', () async {
      when(() => mockChickRepo.getById('missing'))
          .thenAnswer((_) async => null);

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .markAsWeaned('missing');

      final state = container.read(chickFormStateProvider);
      expect(state.isSuccess, isTrue);
      verifyNever(() => mockChickRepo.save(any()));
    });

    test('sets error state when getById throws', () async {
      when(() => mockChickRepo.getById('chick-1'))
          .thenThrow(Exception('DB error'));

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .markAsWeaned('chick-1');

      final state = container.read(chickFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNotNull);
    });
  });

  group('ChickFormStatusActions - markAsDeceased', () {
    test('updates health status to deceased', () async {
      final chick = _chick();
      when(() => mockChickRepo.getById('chick-1'))
          .thenAnswer((_) async => chick);
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      final deathDate = DateTime(2025, 4, 20);
      await container
          .read(chickFormStateProvider.notifier)
          .markAsDeceased('chick-1', deathDate: deathDate);

      final captured =
          verify(() => mockChickRepo.save(captureAny())).captured;
      final saved = captured.first as Chick;
      expect(saved.healthStatus, ChickHealthStatus.deceased);
      expect(saved.deathDate, deathDate);
    });

    test('uses current date when deathDate is not provided', () async {
      final chick = _chick();
      when(() => mockChickRepo.getById('chick-1'))
          .thenAnswer((_) async => chick);
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .markAsDeceased('chick-1');

      final captured =
          verify(() => mockChickRepo.save(captureAny())).captured;
      final saved = captured.first as Chick;
      expect(saved.healthStatus, ChickHealthStatus.deceased);
      expect(saved.deathDate, isNotNull);
    });

    test('is a no-op when chick not found', () async {
      when(() => mockChickRepo.getById('missing'))
          .thenAnswer((_) async => null);

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .markAsDeceased('missing');

      final state = container.read(chickFormStateProvider);
      expect(state.isSuccess, isTrue);
      verifyNever(() => mockChickRepo.save(any()));
    });

    test('sets error when save fails', () async {
      when(() => mockChickRepo.getById('chick-1'))
          .thenAnswer((_) async => _chick());
      when(() => mockChickRepo.save(any()))
          .thenThrow(Exception('Save failed'));

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .markAsDeceased('chick-1');

      final state = container.read(chickFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNotNull);
    });
  });

  group('ChickFormStatusActions - promoteToBird', () {
    test('creates bird and links chick on successful promotion', () async {
      final chick = _chick(
        name: 'Pamuk',
        eggId: 'egg-1',
        gender: BirdGender.female,
        ringNumber: 'R-001',
        hatchDate: DateTime(2025, 3, 1),
      );

      when(() => mockBirdRepo.save(any())).thenAnswer((_) async {});
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});
      when(() => mockEggRepo.getById('egg-1')).thenAnswer(
        (_) async => Egg(
          id: 'egg-1',
          userId: 'user-1',
          incubationId: 'inc-1',
          layDate: DateTime(2025, 2, 10),
        ),
      );
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
          maleId: 'father-1',
          femaleId: 'mother-1',
        ),
      );

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .promoteToBird(chick);

      final state = container.read(chickFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);

      // Verify bird was created
      final birdCaptures =
          verify(() => mockBirdRepo.save(captureAny())).captured;
      final savedBird = birdCaptures.first as Bird;
      expect(savedBird.name, 'Pamuk');
      expect(savedBird.gender, BirdGender.female);
      expect(savedBird.ringNumber, 'R-001');
      expect(savedBird.fatherId, 'father-1');
      expect(savedBird.motherId, 'mother-1');
      expect(savedBird.status, BirdStatus.alive);

      // Verify chick was updated with birdId
      final chickCaptures =
          verify(() => mockChickRepo.save(captureAny())).captured;
      final updatedChick = chickCaptures.first as Chick;
      expect(updatedChick.birdId, isNotNull);
      expect(updatedChick.weanDate, isNotNull);
    });

    test('promotes chick without egg (no parent resolution)', () async {
      final chick = _chick(name: 'Orphan', eggId: null);

      when(() => mockBirdRepo.save(any())).thenAnswer((_) async {});
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .promoteToBird(chick);

      final state = container.read(chickFormStateProvider);
      expect(state.isSuccess, isTrue);

      final birdCaptures =
          verify(() => mockBirdRepo.save(captureAny())).captured;
      final savedBird = birdCaptures.first as Bird;
      expect(savedBird.fatherId, isNull);
      expect(savedBird.motherId, isNull);
    });

    test('sets error when bird save fails', () async {
      final chick = _chick(eggId: null);
      when(() => mockBirdRepo.save(any())).thenThrow(Exception('Save failed'));

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .promoteToBird(chick);

      final state = container.read(chickFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNotNull);
    });

    test('resolves to null parents when breeding pair not found', () async {
      final chick = _chick(eggId: 'egg-1');

      when(() => mockBirdRepo.save(any())).thenAnswer((_) async {});
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});
      when(() => mockEggRepo.getById('egg-1')).thenAnswer(
        (_) async => Egg(
          id: 'egg-1',
          userId: 'user-1',
          incubationId: 'inc-1',
          layDate: DateTime(2025, 2, 10),
        ),
      );
      when(() => mockIncubationRepo.getById('inc-1')).thenAnswer(
        (_) async => const Incubation(
          id: 'inc-1',
          userId: 'user-1',
          breedingPairId: 'pair-missing',
        ),
      );
      when(() => mockBreedingPairRepo.getById('pair-missing'))
          .thenAnswer((_) async => null);

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .promoteToBird(chick);

      final birdCaptures =
          verify(() => mockBirdRepo.save(captureAny())).captured;
      final savedBird = birdCaptures.first as Bird;
      expect(savedBird.fatherId, isNull);
      expect(savedBird.motherId, isNull);
    });

    test('preserves existing weanDate on promotion', () async {
      final existingWeanDate = DateTime(2025, 3, 20);
      final chick = _chick(eggId: null, weanDate: existingWeanDate);

      when(() => mockBirdRepo.save(any())).thenAnswer((_) async {});
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(chickFormStateProvider.notifier)
          .promoteToBird(chick);

      final chickCaptures =
          verify(() => mockChickRepo.save(captureAny())).captured;
      final updatedChick = chickCaptures.first as Chick;
      expect(updatedChick.weanDate, existingWeanDate);
    });
  });
}
