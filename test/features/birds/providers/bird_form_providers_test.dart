import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_form_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockBirdRepository repo;

  setUp(() {
    repo = MockBirdRepository();
    registerFallbackValue(
      const Bird(id: '', name: '', gender: BirdGender.unknown, userId: ''),
    );
    when(
      () =>
          repo.hasRingNumber(any(), any(), excludeId: any(named: 'excludeId')),
    ).thenAnswer((_) async => false);
    when(() => repo.getById(any())).thenAnswer((_) async => null);
  });

  ProviderContainer makeContainer({bool isPremium = false}) {
    return ProviderContainer(
      overrides: [
        birdRepositoryProvider.overrideWithValue(repo),
        isPremiumProvider.overrideWithValue(isPremium),
        effectivePremiumProvider.overrideWithValue(isPremium),
      ],
    );
  }

  /// Stubs repository methods to return counts under the free tier limit.
  void stubUnderLimit({int count = 1}) {
    final birds = List.generate(
      count,
      (i) => Bird(
        id: 'b-$i',
        name: 'Bird $i',
        gender: BirdGender.male,
        userId: 'user-1',
      ),
    );
    when(() => repo.getAll(any())).thenAnswer((_) async => birds);
    when(() => repo.getCount(any())).thenAnswer((_) async => count);
  }

  group('BirdFormState', () {
    test('initial state has default values', () {
      const state = BirdFormState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
      expect(state.remainingBirds, isNull);
    });

    test('copyWith updates isLoading', () {
      const state = BirdFormState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
      expect(updated.error, isNull);
    });

    test('copyWith clears error when passed null', () {
      final state = const BirdFormState().copyWith(error: 'fail');
      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });

    test('copyWith updates isSuccess', () {
      const state = BirdFormState();
      final updated = state.copyWith(isSuccess: true);
      expect(updated.isSuccess, isTrue);
    });
  });

  group('BirdFormNotifier', () {
    test('initial state is default BirdFormState', () {
      final container = makeContainer();
      addTearDown(container.dispose);

      final state = container.read(birdFormStateProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
    });

    test('createBird sets isSuccess on success', () async {
      stubUnderLimit();
      when(() => repo.save(any())).thenAnswer((_) async {});
      when(() => repo.getCount(any())).thenAnswer((_) async => 2);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(userId: 'user-1', name: 'Alpha', gender: BirdGender.male);

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
      verify(() => repo.save(any())).called(1);
    });

    test('createBird blocks duplicate ring number', () async {
      when(() => repo.getCount(any())).thenAnswer((_) async => 1);
      when(
        () => repo.hasRingNumber(
          'user-1',
          'tr-100',
          excludeId: any(named: 'excludeId'),
        ),
      ).thenAnswer((_) async => true);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(
            userId: 'user-1',
            name: 'Alpha',
            gender: BirdGender.male,
            ringNumber: ' tr-100 ',
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'birds.ring_number_not_unique');
      verifyNever(() => repo.save(any()));
    });

    test(
      'createBird persists explicit mutation payload when provided',
      () async {
        stubUnderLimit();
        when(() => repo.save(any())).thenAnswer((_) async {});

        final container = makeContainer();
        addTearDown(container.dispose);

        await container
            .read(birdFormStateProvider.notifier)
            .createBird(
              userId: 'user-1',
              name: 'Gamma',
              gender: BirdGender.male,
              mutations: const ['ino'],
              genotypeInfo: const {'ino': 'carrier'},
            );

        final captured =
            verify(() => repo.save(captureAny())).captured.single as Bird;
        expect(captured.mutations, ['ino']);
        expect(captured.genotypeInfo, {'ino': 'carrier'});
      },
    );

    test('createBird rejects father from different species', () async {
      stubUnderLimit();
      when(() => repo.getById('father-1')).thenAnswer(
        (_) async => const Bird(
          id: 'father-1',
          name: 'Father',
          gender: BirdGender.male,
          userId: 'user-1',
          species: Species.canary,
        ),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(
            userId: 'user-1',
            name: 'Alpha',
            gender: BirdGender.male,
            species: Species.budgie,
            fatherId: 'father-1',
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'birds.parent_species_mismatch');
      verifyNever(() => repo.save(any()));
    });

    test('createBird rejects mother with wrong gender', () async {
      stubUnderLimit();
      when(() => repo.getById('mother-1')).thenAnswer(
        (_) async => const Bird(
          id: 'mother-1',
          name: 'Mother',
          gender: BirdGender.male,
          userId: 'user-1',
          species: Species.budgie,
        ),
      );

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(
            userId: 'user-1',
            name: 'Alpha',
            gender: BirdGender.male,
            species: Species.budgie,
            motherId: 'mother-1',
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'birds.invalid_mother');
      verifyNever(() => repo.save(any()));
    });

    test('createBird sets error on failure', () async {
      stubUnderLimit();
      when(() => repo.save(any())).thenThrow(Exception('DB error'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(userId: 'user-1', name: 'Alpha', gender: BirdGender.male);

      final state = container.read(birdFormStateProvider);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test(
      'createBird maps DB parent species mismatch to localized error',
      () async {
        stubUnderLimit();
        when(
          () => repo.save(any()),
        ).thenThrow(const DatabaseException('bird_parent_species_mismatch'));

        final container = makeContainer();
        addTearDown(container.dispose);

        await container
            .read(birdFormStateProvider.notifier)
            .createBird(
              userId: 'user-1',
              name: 'Alpha',
              gender: BirdGender.male,
            );

        final state = container.read(birdFormStateProvider);
        expect(state.error, 'birds.parent_species_mismatch');
      },
    );

    test('createBird returns remainingBirds for free tier', () async {
      stubUnderLimit(count: 10);
      when(() => repo.save(any())).thenAnswer((_) async {});
      // After save, getCount returns 11 (10 existing + 1 newly saved)
      when(() => repo.getCount(any())).thenAnswer((_) async => 11);

      final container = makeContainer(isPremium: false);
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(
            userId: 'user-1',
            name: 'NewBird',
            gender: BirdGender.male,
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.remainingBirds, AppConstants.freeTierMaxBirds - 11);
    });

    test('createBird does not set remainingBirds for premium', () async {
      stubUnderLimit();
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer(isPremium: true);
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(userId: 'user-1', name: 'Alpha', gender: BirdGender.male);

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.remainingBirds, isNull);
    });

    test('updateBird sets isSuccess on success', () async {
      stubUnderLimit();
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      const bird = Bird(
        id: 'b1',
        name: 'Beta',
        gender: BirdGender.female,
        userId: 'user-1',
      );

      await container.read(birdFormStateProvider.notifier).updateBird(bird);

      expect(container.read(birdFormStateProvider).isSuccess, isTrue);
    });

    test('updateBird blocks duplicate ring number on another bird', () async {
      when(
        () => repo.hasRingNumber('user-1', 'tr-100', excludeId: 'b2'),
      ).thenAnswer((_) async => true);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .updateBird(
            const Bird(
              id: 'b2',
              name: 'Bird Two',
              gender: BirdGender.female,
              userId: 'user-1',
              ringNumber: 'tr-100',
            ),
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'birds.ring_number_not_unique');
      verifyNever(() => repo.save(any()));
    });

    test('updateBird rejects self as parent', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .updateBird(
            const Bird(
              id: 'b2',
              name: 'Bird Two',
              gender: BirdGender.female,
              userId: 'user-1',
              fatherId: 'b2',
              species: Species.budgie,
            ),
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'birds.not_found');
      verifyNever(() => repo.save(any()));
    });

    test('deleteBird sets isSuccess on success', () async {
      when(() => repo.remove(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).deleteBird('b1');

      expect(container.read(birdFormStateProvider).isSuccess, isTrue);
    });

    test('markAsDead updates bird status', () async {
      const bird = Bird(
        id: 'b1',
        name: 'Test',
        gender: BirdGender.male,
        userId: 'user-1',
        status: BirdStatus.alive,
      );
      when(() => repo.getById('b1')).thenAnswer((_) async => bird);
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).markAsDead('b1');

      expect(container.read(birdFormStateProvider).isSuccess, isTrue);
      final captured =
          verify(() => repo.save(captureAny())).captured.single as Bird;
      expect(captured.status, BirdStatus.dead);
    });

    test('markAsSold updates bird status', () async {
      const bird = Bird(
        id: 'b1',
        name: 'Test',
        gender: BirdGender.male,
        userId: 'user-1',
        status: BirdStatus.alive,
      );
      when(() => repo.getById('b1')).thenAnswer((_) async => bird);
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).markAsSold('b1');

      final captured =
          verify(() => repo.save(captureAny())).captured.single as Bird;
      expect(captured.status, BirdStatus.sold);
    });

    test('reset clears state', () async {
      stubUnderLimit();
      when(() => repo.save(any())).thenAnswer((_) async {});
      when(() => repo.getCount(any())).thenAnswer((_) async => 2);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(userId: 'user-1', name: 'X', gender: BirdGender.male);
      expect(container.read(birdFormStateProvider).isSuccess, isTrue);

      container.read(birdFormStateProvider.notifier).reset();
      final state = container.read(birdFormStateProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
      expect(state.remainingBirds, isNull);
    });
  });
}
