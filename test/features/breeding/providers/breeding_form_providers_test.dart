import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_form_providers.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}) {
  return Incubation(
    id: id,
    userId: 'user-1',
    status: status,
    breedingPairId: 'pair-1',
    startDate: DateTime(2025, 1, 1),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBreedingPairRepository mockPairRepo;
  late MockIncubationRepository mockIncubationRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockPairRepo = MockBreedingPairRepository();
    mockIncubationRepo = MockIncubationRepository();
    registerFallbackValue(_pair());
    registerFallbackValue(
      const Incubation(id: 'fallback', userId: 'fallback-user'),
    );
  });

  ProviderContainer createContainer({bool isPremium = false}) {
    return ProviderContainer(
      overrides: [
        breedingPairRepositoryProvider.overrideWithValue(mockPairRepo),
        incubationRepositoryProvider.overrideWithValue(mockIncubationRepo),
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
    when(
      () => mockPairRepo.getActiveCount(any()),
    ).thenAnswer((_) async => 1);
    when(
      () => mockIncubationRepo.getActiveCount(any()),
    ).thenAnswer((_) async => 1);
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
      when(
        () => mockPairRepo.getActiveCount(any()),
      ).thenAnswer((_) async => 1);
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
      when(
        () => mockPairRepo.getActiveCount(any()),
      ).thenAnswer((_) async => 4);
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
      when(
        () => mockPairRepo.getActiveCount(any()),
      ).thenAnswer((_) async => 1);
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
      when(() => mockPairRepo.remove(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .deleteBreeding('pair-42');

      verify(() => mockPairRepo.remove('pair-42')).called(1);
    });

    test('sets error when remove throws', () async {
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
