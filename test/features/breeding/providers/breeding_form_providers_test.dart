import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_form_providers.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/species_incubation_config.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/inbreeding_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/test_fixtures.dart';

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
  Species species = Species.budgie,
  DateTime? startDate,
  DateTime? expectedHatchDate,
}) {
  return Incubation(
    id: id,
    userId: 'user-1',
    status: status,
    species: species,
    breedingPairId: 'pair-1',
    startDate: startDate ?? DateTime(2025, 1, 1),
    expectedHatchDate: expectedHatchDate,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBreedingPairRepository mockPairRepo;
  late MockIncubationRepository mockIncubationRepo;
  late MockEggRepository mockEggRepo;
  late MockBirdRepository mockBirdRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockPairRepo = MockBreedingPairRepository();
    mockIncubationRepo = MockIncubationRepository();
    mockEggRepo = MockEggRepository();
    mockBirdRepo = MockBirdRepository();
    registerFallbackValue(_pair());
    registerFallbackValue(
      const Incubation(id: 'fallback', userId: 'fallback-user'),
    );
    when(() => mockBirdRepo.getById('male-1')).thenAnswer(
      (_) async => const Bird(
        id: 'male-1',
        userId: 'user-1',
        name: 'Male',
        gender: BirdGender.male,
        species: Species.budgie,
      ),
    );
    when(() => mockBirdRepo.getById('female-1')).thenAnswer(
      (_) async => const Bird(
        id: 'female-1',
        userId: 'user-1',
        name: 'Female',
        gender: BirdGender.female,
        species: Species.budgie,
      ),
    );
  });

  ProviderContainer createContainer({bool isPremium = false}) {
    return ProviderContainer(
      overrides: [
        breedingPairRepositoryProvider.overrideWithValue(mockPairRepo),
        incubationRepositoryProvider.overrideWithValue(mockIncubationRepo),
        eggRepositoryProvider.overrideWithValue(mockEggRepo),
        birdRepositoryProvider.overrideWithValue(mockBirdRepo),
        isPremiumProvider.overrideWithValue(isPremium),
        effectivePremiumProvider.overrideWithValue(isPremium),
      ],
    );
  }

  /// Stubs repository methods to return counts under the free tier limits.
  void stubUnderLimits() {
    when(() => mockPairRepo.getAll(any())).thenAnswer((_) async => [_pair()]);
    when(
      () => mockIncubationRepo.getAll(any()),
    ).thenAnswer((_) async => [_incubation()]);
    when(() => mockPairRepo.getActiveCount(any())).thenAnswer((_) async => 1);
    when(
      () => mockIncubationRepo.getActiveCount(any()),
    ).thenAnswer((_) async => 1);
  }

  void stubDeleteCleanupDeps() {
    when(
      () => mockIncubationRepo.getByBreedingPairIds(any()),
    ).thenAnswer((_) async => const []);
  }

  group('BreedingFormState', () {
    test('default state is not loading, no error, not success', () {
      const state = BreedingFormState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
      expect(state.isBreedingLimitReached, isFalse);
      expect(state.isIncubationLimitReached, isFalse);
    });

    test('copyWith updates isLoading', () {
      const state = BreedingFormState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
    });

    test('copyWith clears error', () {
      const state = BreedingFormState(error: 'Some error');
      final updated = state.copyWith(error: null);
      expect(updated.error, isNull);
    });

    test('copyWith preserves other fields', () {
      const state = BreedingFormState(isLoading: true, isSuccess: false);
      final updated = state.copyWith(isSuccess: true);
      expect(updated.isLoading, isTrue);
      expect(updated.isSuccess, isTrue);
    });

    test('copyWith resets limit flags to false by default', () {
      const state = BreedingFormState(
        isBreedingLimitReached: true,
        isIncubationLimitReached: true,
      );
      final updated = state.copyWith(isSuccess: true);
      expect(updated.isBreedingLimitReached, isFalse);
      expect(updated.isIncubationLimitReached, isFalse);
    });
  });

  group('calculateBreedingCandidateInbreeding', () {
    test('returns none when either bird is missing', () {
      final result = calculateBreedingCandidateInbreeding(
        birds: const [],
        maleBird: null,
        femaleBird: null,
      );

      expect(result.coefficient, 0);
      expect(result.risk, InbreedingRisk.none);
      expect(result.shouldConfirm, isFalse);
    });

    test('calculates moderate risk for parent-offspring pairing', () {
      final father = createTestBird(id: 'father', gender: BirdGender.male);
      final daughter = createTestBird(
        id: 'daughter',
        gender: BirdGender.female,
        fatherId: father.id,
      );

      final result = calculateBreedingCandidateInbreeding(
        birds: [father, daughter],
        maleBird: father,
        femaleBird: daughter,
      );

      expect(result.coefficient, closeTo(0.25, 0.001));
      expect(result.risk, InbreedingRisk.moderate);
      expect(result.shouldConfirm, isTrue);
      expect(result.commonAncestorIds, contains(father.id));
    });

    test('keeps distant relation visible without confirm threshold', () {
      final pedigree = createInbredPedigree(
        subjectId: 'candidate-child',
        fatherId: 'male-1',
        motherId: 'female-1',
        commonAncestorId: 'grandparent',
      );

      final result = calculateBreedingCandidateInbreeding(
        birds: pedigree.values.toList(),
        maleBird: pedigree['male-1'],
        femaleBird: pedigree['female-1'],
      );

      expect(result.coefficient, closeTo(0.125, 0.001));
      expect(result.risk, InbreedingRisk.low);
      expect(result.shouldConfirm, isFalse);
    });
  });

  group('BreedingFormNotifier.createBreeding', () {
    test('sets isSuccess on success', () async {
      stubUnderLimits();
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      when(() => mockIncubationRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .createBreeding(
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            pairingDate: DateTime(2025, 1, 1),
          );

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('saves both pair and incubation', () async {
      stubUnderLimits();
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      when(() => mockIncubationRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .createBreeding(
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            pairingDate: DateTime(2025, 1, 1),
          );

      verify(() => mockPairRepo.save(any())).called(1);
      final savedIncubation =
          verify(() => mockIncubationRepo.save(captureAny())).captured.single
              as Incubation;
      expect(savedIncubation.startDate, isNull);
      expect(savedIncubation.expectedHatchDate, isNull);
    });

    test('sets incubation species from validated male bird species', () async {
      stubUnderLimits();
      when(() => mockBirdRepo.getById('male-1')).thenAnswer(
        (_) async => const Bird(
          id: 'male-1',
          userId: 'user-1',
          name: 'Male',
          gender: BirdGender.male,
          species: Species.canary,
        ),
      );
      when(() => mockBirdRepo.getById('female-1')).thenAnswer(
        (_) async => const Bird(
          id: 'female-1',
          userId: 'user-1',
          name: 'Female',
          gender: BirdGender.female,
          species: Species.canary,
        ),
      );
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      when(() => mockIncubationRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .createBreeding(
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            pairingDate: DateTime(2025, 1, 1),
          );

      final savedIncubation =
          verify(() => mockIncubationRepo.save(captureAny())).captured.single
              as Incubation;
      expect(savedIncubation.species, Species.canary);
      expect(savedIncubation.status, IncubationStatus.active);
    });

    test('rolls back saved pair when incubation save fails', () async {
      stubUnderLimits();
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      when(
        () => mockIncubationRepo.save(any()),
      ).thenThrow(Exception('incubation save failed'));
      when(() => mockPairRepo.remove(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .createBreeding(
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            pairingDate: DateTime(2025, 1, 1),
          );

      final savedPair =
          verify(() => mockPairRepo.save(captureAny())).captured.single
              as BreedingPair;
      verify(() => mockPairRepo.remove(savedPair.id)).called(1);

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('ignores duplicate create while first create is loading', () async {
      stubUnderLimits();
      final pairSave = Completer<void>();
      when(() => mockPairRepo.save(any())).thenAnswer((_) => pairSave.future);
      when(() => mockIncubationRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);
      final notifier = container.read(breedingFormStateProvider.notifier);

      final first = notifier.createBreeding(
        userId: 'user-1',
        maleId: 'male-1',
        femaleId: 'female-1',
        pairingDate: DateTime(2025, 1, 1),
      );
      final second = notifier.createBreeding(
        userId: 'user-1',
        maleId: 'male-1',
        femaleId: 'female-1',
        pairingDate: DateTime(2025, 1, 2),
      );

      await Future<void>.delayed(Duration.zero);
      verify(() => mockPairRepo.save(any())).called(1);

      pairSave.complete();
      await Future.wait([first, second]);
      verify(() => mockIncubationRepo.save(any())).called(1);
    });

    test('sets error state when pair repo throws', () async {
      stubUnderLimits();
      when(() => mockPairRepo.save(any())).thenThrow(Exception('DB error'));
      when(() => mockIncubationRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .createBreeding(
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            pairingDate: DateTime(2025, 1, 1),
          );

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('maps DB invalid female gender error to localized message', () async {
      stubUnderLimits();
      when(() => mockPairRepo.save(any())).thenThrow(
        const DatabaseException('breeding_pair_invalid_female_gender'),
      );
      when(() => mockIncubationRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .createBreeding(
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            pairingDate: DateTime(2025, 1, 1),
          );

      final state = container.read(breedingFormStateProvider);
      expect(state.error, 'breeding.invalid_female');
    });

    test('rejects pairing birds from different species', () async {
      stubUnderLimits();
      when(() => mockBirdRepo.getById('female-1')).thenAnswer(
        (_) async => const Bird(
          id: 'female-1',
          userId: 'user-1',
          name: 'Female',
          gender: BirdGender.female,
          species: Species.canary,
        ),
      );

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .createBreeding(
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            pairingDate: DateTime(2025, 1, 1),
          );

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNotNull);
      verifyNever(() => mockPairRepo.save(any()));
    });

    test('rejects pairing when selected male bird is not male', () async {
      stubUnderLimits();
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      when(() => mockIncubationRepo.save(any())).thenAnswer((_) async {});
      when(() => mockBirdRepo.getById('male-1')).thenAnswer(
        (_) async => const Bird(
          id: 'male-1',
          userId: 'user-1',
          name: 'Wrong Male',
          gender: BirdGender.female,
          species: Species.budgie,
        ),
      );

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .createBreeding(
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            pairingDate: DateTime(2025, 1, 1),
          );

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'breeding.invalid_male');
      verifyNever(() => mockPairRepo.save(any()));
    });

    test('rejects pairing when either selected bird is not alive', () async {
      stubUnderLimits();
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      when(() => mockIncubationRepo.save(any())).thenAnswer((_) async {});
      when(() => mockBirdRepo.getById('female-1')).thenAnswer(
        (_) async => const Bird(
          id: 'female-1',
          userId: 'user-1',
          name: 'Female',
          gender: BirdGender.female,
          status: BirdStatus.dead,
          species: Species.budgie,
        ),
      );

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .createBreeding(
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            pairingDate: DateTime(2025, 1, 1),
          );

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'breeding.birds_must_be_alive');
      verifyNever(() => mockPairRepo.save(any()));
    });
  });

  group('BreedingFormNotifier.updateBreeding', () {
    test(
      'rejects updated pair when birds are from different species',
      () async {
        when(() => mockBirdRepo.getById('male-1')).thenAnswer(
          (_) async => const Bird(
            id: 'male-1',
            userId: 'user-1',
            name: 'Male',
            gender: BirdGender.male,
            species: Species.budgie,
          ),
        );
        when(() => mockBirdRepo.getById('female-1')).thenAnswer(
          (_) async => const Bird(
            id: 'female-1',
            userId: 'user-1',
            name: 'Female',
            gender: BirdGender.female,
            species: Species.canary,
          ),
        );

        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(breedingFormStateProvider.notifier)
            .updateBreeding(_pair());

        final state = container.read(breedingFormStateProvider);
        expect(state.isSuccess, isFalse);
        expect(state.error, 'breeding.same_species_required');
        verifyNever(() => mockPairRepo.save(any()));
      },
    );

    test(
      'updates linked incubation species when pair species changes',
      () async {
        final startDate = DateTime(2025, 1, 1);
        final oldExpectedHatchDate = startDate.add(
          Duration(days: incubationDaysForSpecies(Species.budgie)),
        );
        when(() => mockBirdRepo.getById('male-1')).thenAnswer(
          (_) async => const Bird(
            id: 'male-1',
            userId: 'user-1',
            name: 'Male',
            gender: BirdGender.male,
            species: Species.canary,
          ),
        );
        when(() => mockBirdRepo.getById('female-1')).thenAnswer(
          (_) async => const Bird(
            id: 'female-1',
            userId: 'user-1',
            name: 'Female',
            gender: BirdGender.female,
            species: Species.canary,
          ),
        );
        when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
        when(() => mockIncubationRepo.getByBreedingPair('pair-1')).thenAnswer(
          (_) async => [
            _incubation(
              species: Species.budgie,
              startDate: startDate,
              expectedHatchDate: oldExpectedHatchDate,
            ),
          ],
        );
        when(() => mockIncubationRepo.save(any())).thenAnswer((_) async {});

        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(breedingFormStateProvider.notifier)
            .updateBreeding(_pair());

        final updatedIncubation =
            verify(() => mockIncubationRepo.save(captureAny())).captured.single
                as Incubation;
        expect(updatedIncubation.species, Species.canary);
        expect(
          updatedIncubation.expectedHatchDate,
          startDate.add(
            Duration(days: incubationDaysForSpecies(Species.canary)),
          ),
        );
      },
    );
  });

  group('BreedingFormNotifier.createBreeding - free tier limits', () {
    test('blocks when breeding pair limit reached', () async {
      // Return exactly freeTierMaxBreedingPairs active pairs
      when(
        () => mockPairRepo.getActiveCount(any()),
      ).thenAnswer((_) async => AppConstants.freeTierMaxBreedingPairs);

      final container = createContainer(isPremium: false);
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .createBreeding(
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            pairingDate: DateTime(2025, 1, 1),
          );

      final state = container.read(breedingFormStateProvider);
      expect(state.isBreedingLimitReached, isTrue);
      expect(state.isSuccess, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
      verifyNever(() => mockPairRepo.save(any()));
    });

    test('blocks when active incubation limit reached', () async {
      // Pairs under limit
      when(() => mockPairRepo.getActiveCount(any())).thenAnswer((_) async => 1);
      // Incubations at limit
      when(
        () => mockIncubationRepo.getActiveCount(any()),
      ).thenAnswer((_) async => AppConstants.freeTierMaxActiveIncubations);

      final container = createContainer(isPremium: false);
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .createBreeding(
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            pairingDate: DateTime(2025, 1, 1),
          );

      final state = container.read(breedingFormStateProvider);
      expect(state.isIncubationLimitReached, isTrue);
      expect(state.isSuccess, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
      verifyNever(() => mockPairRepo.save(any()));
    });

    test('allows creation when under both limits', () async {
      stubUnderLimits();
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      when(() => mockIncubationRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer(isPremium: false);
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .createBreeding(
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            pairingDate: DateTime(2025, 1, 1),
          );

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isBreedingLimitReached, isFalse);
      expect(state.isIncubationLimitReached, isFalse);
    });

    test('premium user bypasses all limits', () async {
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      when(() => mockIncubationRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer(isPremium: true);
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .createBreeding(
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            pairingDate: DateTime(2025, 1, 1),
          );

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isBreedingLimitReached, isFalse);
      // getActiveCount should NOT have been called since premium skips checks
      verifyNever(() => mockPairRepo.getActiveCount(any()));
    });

    test('ignores completed/cancelled pairs in limit count', () async {
      // getActiveCount returns only active+ongoing pairs (4 of 5)
      when(() => mockPairRepo.getActiveCount(any())).thenAnswer((_) async => 4);
      when(
        () => mockIncubationRepo.getActiveCount(any()),
      ).thenAnswer((_) async => 1);
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      when(() => mockIncubationRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer(isPremium: false);
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .createBreeding(
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            pairingDate: DateTime(2025, 1, 1),
          );

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isBreedingLimitReached, isFalse);
    });

    test('counts ongoing pairs toward breeding limit', () async {
      // getActiveCount includes both active and ongoing pairs
      when(
        () => mockPairRepo.getActiveCount(any()),
      ).thenAnswer((_) async => AppConstants.freeTierMaxBreedingPairs);

      final container = createContainer(isPremium: false);
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .createBreeding(
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            pairingDate: DateTime(2025, 1, 1),
          );

      final state = container.read(breedingFormStateProvider);
      expect(state.isBreedingLimitReached, isTrue);
      expect(state.isSuccess, isFalse);
      verifyNever(() => mockPairRepo.save(any()));
    });

    test('ignores completed incubations in limit count', () async {
      // getActiveCount returns only active incubations (2 of 3)
      when(() => mockPairRepo.getActiveCount(any())).thenAnswer((_) async => 1);
      when(
        () => mockIncubationRepo.getActiveCount(any()),
      ).thenAnswer((_) async => 2);
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      when(() => mockIncubationRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer(isPremium: false);
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .createBreeding(
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            pairingDate: DateTime(2025, 1, 1),
          );

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isIncubationLimitReached, isFalse);
    });
  });

  group('BreedingFormNotifier.updateBreeding', () {
    test('sets isSuccess after saving updated pair', () async {
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      when(
        () => mockIncubationRepo.getByBreedingPair(any()),
      ).thenAnswer((_) async => const []);

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .updateBreeding(_pair());

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('sets error when repo throws', () async {
      when(() => mockPairRepo.save(any())).thenThrow(Exception('Save failed'));

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .updateBreeding(_pair());

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNotNull);
    });
  });

  group('BreedingFormNotifier.deleteBreeding', () {
    test('sets isSuccess after removing pair', () async {
      stubDeleteCleanupDeps();
      when(() => mockPairRepo.remove(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .deleteBreeding('pair-1');

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('calls remove with the correct id', () async {
      stubDeleteCleanupDeps();
      when(() => mockPairRepo.remove(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .deleteBreeding('pair-42');

      verify(() => mockPairRepo.remove('pair-42')).called(1);
    });

    test('sets error when remove throws', () async {
      stubDeleteCleanupDeps();
      when(
        () => mockPairRepo.remove(any()),
      ).thenThrow(Exception('Delete failed'));

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .deleteBreeding('pair-1');

      final state = container.read(breedingFormStateProvider);
      expect(state.error, isNotNull);
      expect(state.isSuccess, isFalse);
    });
  });

  group('BreedingFormNotifier.reset', () {
    test('resets state to default', () async {
      stubUnderLimits();
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      when(() => mockIncubationRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .createBreeding(
            userId: 'user-1',
            maleId: 'male-1',
            femaleId: 'female-1',
            pairingDate: DateTime(2025, 1, 1),
          );

      // Verify success state
      expect(container.read(breedingFormStateProvider).isSuccess, isTrue);

      // Reset
      container.read(breedingFormStateProvider.notifier).reset();

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isBreedingLimitReached, isFalse);
      expect(state.isIncubationLimitReached, isFalse);
    });
  });
}
