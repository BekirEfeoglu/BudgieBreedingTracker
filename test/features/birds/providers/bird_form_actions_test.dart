import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_form_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockBirdRepository repo;

  setUp(() {
    repo = MockBirdRepository();
    registerFallbackValue(
      const Bird(
        id: 'fallback-id',
        name: '',
        gender: BirdGender.unknown,
        userId: 'fallback-user',
      ),
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

  void stubUnderLimit({int count = 1}) {
    when(() => repo.getAll(any())).thenAnswer(
      (_) async => List.generate(
        count,
        (i) => Bird(
          id: 'b-$i',
          name: 'Bird $i',
          gender: BirdGender.male,
          userId: 'user-1',
        ),
      ),
    );
    when(() => repo.getCount(any())).thenAnswer((_) async => count);
  }

  // ── createBird ──

  group('createBird', () {
    test('sets isLoading true during execution', () async {
      stubUnderLimit();
      final states = <BirdFormState>[];
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(birdFormStateProvider, (_, state) {
        states.add(state);
      });

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(userId: 'user-1', name: 'Alpha', gender: BirdGender.male);

      expect(states.first.isLoading, isTrue);
      expect(states.last.isLoading, isFalse);
    });

    test('normalizes whitespace-only ring number to null', () async {
      stubUnderLimit();
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer(isPremium: true);
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(
            userId: 'user-1',
            name: 'Alpha',
            gender: BirdGender.male,
            ringNumber: '   ',
          );

      final captured =
          verify(() => repo.save(captureAny())).captured.single as Bird;
      expect(captured.ringNumber, isNull);
    });

    test('normalizes whitespace-only cage number to null', () async {
      stubUnderLimit();
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer(isPremium: true);
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(
            userId: 'user-1',
            name: 'Alpha',
            gender: BirdGender.male,
            cageNumber: '   ',
          );

      final captured =
          verify(() => repo.save(captureAny())).captured.single as Bird;
      expect(captured.cageNumber, isNull);
    });

    test('trims ring number before saving', () async {
      stubUnderLimit();
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer(isPremium: true);
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(
            userId: 'user-1',
            name: 'Alpha',
            gender: BirdGender.male,
            ringNumber: '  TR-100  ',
          );

      final captured =
          verify(() => repo.save(captureAny())).captured.single as Bird;
      expect(captured.ringNumber, 'TR-100');
    });

    test('trims cage number before saving', () async {
      stubUnderLimit();
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer(isPremium: true);
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(
            userId: 'user-1',
            name: 'Alpha',
            gender: BirdGender.male,
            cageNumber: '  C-01  ',
          );

      final captured =
          verify(() => repo.save(captureAny())).captured.single as Bird;
      expect(captured.cageNumber, 'C-01');
    });

    test('sets isBirdLimitReached when free tier limit exceeded', () async {
      // Stub getCount to return the limit, triggering FreeTierLimitException
      when(() => repo.getCount(any())).thenAnswer(
        (_) async => AppConstants.freeTierMaxBirds,
      );

      final container = makeContainer(isPremium: false);
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(userId: 'user-1', name: 'Alpha', gender: BirdGender.male);

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.isBirdLimitReached, isTrue);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
      verifyNever(() => repo.save(any()));
    });

    test('skips free tier check for premium users', () async {
      // Do not stub getCount — premium users skip the guard entirely.
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer(isPremium: true);
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(userId: 'user-1', name: 'Alpha', gender: BirdGender.male);

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isBirdLimitReached, isFalse);
    });

    test('rejects father that does not exist', () async {
      stubUnderLimit();
      // getById returns null by default (from setUp)

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(
            userId: 'user-1',
            name: 'Alpha',
            gender: BirdGender.male,
            species: Species.budgie,
            fatherId: 'nonexistent',
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'birds.not_found');
      verifyNever(() => repo.save(any()));
    });

    test('rejects father with wrong gender', () async {
      stubUnderLimit();
      when(() => repo.getById('father-1')).thenAnswer(
        (_) async => const Bird(
          id: 'father-1',
          name: 'Father',
          gender: BirdGender.female,
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
            fatherId: 'father-1',
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'birds.invalid_father');
      verifyNever(() => repo.save(any()));
    });

    test('rejects mother that does not exist', () async {
      stubUnderLimit();

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(
            userId: 'user-1',
            name: 'Alpha',
            gender: BirdGender.male,
            species: Species.budgie,
            motherId: 'nonexistent',
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'birds.not_found');
      verifyNever(() => repo.save(any()));
    });

    test('rejects mother from different species', () async {
      stubUnderLimit();
      when(() => repo.getById('mother-1')).thenAnswer(
        (_) async => const Bird(
          id: 'mother-1',
          name: 'Mother',
          gender: BirdGender.female,
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
            motherId: 'mother-1',
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'birds.parent_species_mismatch');
      verifyNever(() => repo.save(any()));
    });

    test('accepts valid father and mother', () async {
      stubUnderLimit();
      when(() => repo.save(any())).thenAnswer((_) async {});
      when(() => repo.getById('father-1')).thenAnswer(
        (_) async => const Bird(
          id: 'father-1',
          name: 'Father',
          gender: BirdGender.male,
          userId: 'user-1',
          species: Species.budgie,
        ),
      );
      when(() => repo.getById('mother-1')).thenAnswer(
        (_) async => const Bird(
          id: 'mother-1',
          name: 'Mother',
          gender: BirdGender.female,
          userId: 'user-1',
          species: Species.budgie,
        ),
      );

      final container = makeContainer(isPremium: true);
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(
            userId: 'user-1',
            name: 'Alpha',
            gender: BirdGender.male,
            species: Species.budgie,
            fatherId: 'father-1',
            motherId: 'mother-1',
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isTrue);
      final captured =
          verify(() => repo.save(captureAny())).captured.single as Bird;
      expect(captured.fatherId, 'father-1');
      expect(captured.motherId, 'mother-1');
    });

    test('saves bird with all optional fields', () async {
      stubUnderLimit();
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer(isPremium: true);
      addTearDown(container.dispose);

      final birthDate = DateTime(2024, 6, 15);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(
            userId: 'user-1',
            name: 'Full Bird',
            gender: BirdGender.female,
            species: Species.budgie,
            colorMutation: BirdColor.blue,
            ringNumber: 'TR-200',
            birthDate: birthDate,
            cageNumber: 'C-05',
            notes: 'Some notes',
            mutations: const ['blue', 'opaline'],
            genotypeInfo: const {'blue': 'visual', 'opaline': 'carrier'},
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isTrue);

      final captured =
          verify(() => repo.save(captureAny())).captured.single as Bird;
      expect(captured.name, 'Full Bird');
      expect(captured.gender, BirdGender.female);
      expect(captured.species, Species.budgie);
      expect(captured.colorMutation, BirdColor.blue);
      expect(captured.ringNumber, 'TR-200');
      expect(captured.birthDate, birthDate);
      expect(captured.cageNumber, 'C-05');
      expect(captured.notes, 'Some notes');
      expect(captured.mutations, ['blue', 'opaline']);
      expect(captured.genotypeInfo, {'blue': 'visual', 'opaline': 'carrier'});
      expect(captured.status, BirdStatus.alive);
      expect(captured.userId, 'user-1');
      expect(captured.id, isNotEmpty);
    });

    test('maps bird_invalid_father_gender DB error', () async {
      stubUnderLimit();
      when(() => repo.save(any()))
          .thenThrow(const DatabaseException('bird_invalid_father_gender'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(userId: 'user-1', name: 'A', gender: BirdGender.male);

      expect(
        container.read(birdFormStateProvider).error,
        'birds.invalid_father',
      );
    });

    test('maps bird_invalid_mother_gender DB error', () async {
      stubUnderLimit();
      when(() => repo.save(any()))
          .thenThrow(const DatabaseException('bird_invalid_mother_gender'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(userId: 'user-1', name: 'A', gender: BirdGender.male);

      expect(
        container.read(birdFormStateProvider).error,
        'birds.invalid_mother',
      );
    });

    test('maps bird_parent_self_reference DB error', () async {
      stubUnderLimit();
      when(() => repo.save(any()))
          .thenThrow(const DatabaseException('bird_parent_self_reference'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(userId: 'user-1', name: 'A', gender: BirdGender.male);

      expect(container.read(birdFormStateProvider).error, 'birds.not_found');
    });

    test('maps bird_father_not_found DB error', () async {
      stubUnderLimit();
      when(() => repo.save(any()))
          .thenThrow(const DatabaseException('bird_father_not_found'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(userId: 'user-1', name: 'A', gender: BirdGender.male);

      expect(container.read(birdFormStateProvider).error, 'birds.not_found');
    });

    test('maps bird_mother_not_found DB error', () async {
      stubUnderLimit();
      when(() => repo.save(any()))
          .thenThrow(const DatabaseException('bird_mother_not_found'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(userId: 'user-1', name: 'A', gender: BirdGender.male);

      expect(container.read(birdFormStateProvider).error, 'birds.not_found');
    });

    test('falls back to errors.unknown for unmapped exceptions', () async {
      stubUnderLimit();
      when(() => repo.save(any())).thenThrow(Exception('random failure'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(userId: 'user-1', name: 'A', gender: BirdGender.male);

      expect(container.read(birdFormStateProvider).error, 'errors.unknown');
    });

    test('clears previous error before new attempt', () async {
      stubUnderLimit();
      // First call: fail
      when(() => repo.save(any())).thenThrow(Exception('fail'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(userId: 'user-1', name: 'A', gender: BirdGender.male);
      expect(container.read(birdFormStateProvider).error, isNotNull);

      // Second call: succeed
      when(() => repo.save(any())).thenAnswer((_) async {});
      when(() => repo.getCount(any())).thenAnswer((_) async => 2);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(userId: 'user-1', name: 'B', gender: BirdGender.male);

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.error, isNull);
    });

    test('ring number conflict check is case-insensitive', () async {
      stubUnderLimit();
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
            ringNumber: 'TR-100',
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'birds.ring_number_not_unique');
      verifyNever(() => repo.save(any()));
    });

    test('does not check ring number conflict when ring is null', () async {
      stubUnderLimit();
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer(isPremium: true);
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(userId: 'user-1', name: 'A', gender: BirdGender.male);

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isTrue);
      // hasRingNumber should not be called with a null/empty ring number
      verifyNever(
        () => repo.hasRingNumber(
          'user-1',
          '',
          excludeId: any(named: 'excludeId'),
        ),
      );
    });
  });

  // ── updateBird ──

  group('updateBird', () {
    test('sets isLoading true during execution', () async {
      final states = <BirdFormState>[];
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      container.listen(birdFormStateProvider, (_, state) {
        states.add(state);
      });

      await container.read(birdFormStateProvider.notifier).updateBird(
            const Bird(
              id: 'b1',
              name: 'Beta',
              gender: BirdGender.female,
              userId: 'user-1',
            ),
          );

      expect(states.first.isLoading, isTrue);
      expect(states.last.isLoading, isFalse);
    });

    test('sets isSuccess on success', () async {
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).updateBird(
            const Bird(
              id: 'b1',
              name: 'Beta',
              gender: BirdGender.female,
              userId: 'user-1',
            ),
          );

      expect(container.read(birdFormStateProvider).isSuccess, isTrue);
    });

    test('normalizes ring number whitespace', () async {
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).updateBird(
            const Bird(
              id: 'b1',
              name: 'Beta',
              gender: BirdGender.female,
              userId: 'user-1',
              ringNumber: '  TR-200  ',
            ),
          );

      final captured =
          verify(() => repo.save(captureAny())).captured.single as Bird;
      expect(captured.ringNumber, 'TR-200');
    });

    test('normalizes cage number whitespace', () async {
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).updateBird(
            const Bird(
              id: 'b1',
              name: 'Beta',
              gender: BirdGender.female,
              userId: 'user-1',
              cageNumber: '  C-01  ',
            ),
          );

      final captured =
          verify(() => repo.save(captureAny())).captured.single as Bird;
      expect(captured.cageNumber, 'C-01');
    });

    test('normalizes empty ring number to null', () async {
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).updateBird(
            const Bird(
              id: 'b1',
              name: 'Beta',
              gender: BirdGender.female,
              userId: 'user-1',
              ringNumber: '   ',
            ),
          );

      final captured =
          verify(() => repo.save(captureAny())).captured.single as Bird;
      expect(captured.ringNumber, isNull);
    });

    test('blocks duplicate ring number on another bird', () async {
      when(
        () => repo.hasRingNumber('user-1', 'tr-100', excludeId: 'b2'),
      ).thenAnswer((_) async => true);

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).updateBird(
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

    test('rejects self as father', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).updateBird(
            const Bird(
              id: 'b1',
              name: 'Bird',
              gender: BirdGender.male,
              userId: 'user-1',
              fatherId: 'b1',
              species: Species.budgie,
            ),
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'birds.not_found');
      verifyNever(() => repo.save(any()));
    });

    test('rejects self as mother', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).updateBird(
            const Bird(
              id: 'b1',
              name: 'Bird',
              gender: BirdGender.female,
              userId: 'user-1',
              motherId: 'b1',
              species: Species.budgie,
            ),
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'birds.not_found');
      verifyNever(() => repo.save(any()));
    });

    test('rejects father from different species', () async {
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

      await container.read(birdFormStateProvider.notifier).updateBird(
            const Bird(
              id: 'b1',
              name: 'Bird',
              gender: BirdGender.male,
              userId: 'user-1',
              fatherId: 'father-1',
              species: Species.budgie,
            ),
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'birds.parent_species_mismatch');
      verifyNever(() => repo.save(any()));
    });

    test('rejects mother with wrong gender', () async {
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

      await container.read(birdFormStateProvider.notifier).updateBird(
            const Bird(
              id: 'b1',
              name: 'Bird',
              gender: BirdGender.male,
              userId: 'user-1',
              motherId: 'mother-1',
              species: Species.budgie,
            ),
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'birds.invalid_mother');
      verifyNever(() => repo.save(any()));
    });

    test('maps bird_parent_species_mismatch DB error', () async {
      when(() => repo.save(any()))
          .thenThrow(const DatabaseException('bird_parent_species_mismatch'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).updateBird(
            const Bird(
              id: 'b1',
              name: 'Bird',
              gender: BirdGender.male,
              userId: 'user-1',
            ),
          );

      expect(
        container.read(birdFormStateProvider).error,
        'birds.parent_species_mismatch',
      );
    });

    test('falls back to errors.unknown for unmapped exceptions', () async {
      when(() => repo.save(any())).thenThrow(Exception('random'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).updateBird(
            const Bird(
              id: 'b1',
              name: 'Bird',
              gender: BirdGender.male,
              userId: 'user-1',
            ),
          );

      expect(container.read(birdFormStateProvider).error, 'errors.unknown');
    });

    test('sets updatedAt on saved bird', () async {
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      final before = DateTime.now();

      await container.read(birdFormStateProvider.notifier).updateBird(
            const Bird(
              id: 'b1',
              name: 'Bird',
              gender: BirdGender.male,
              userId: 'user-1',
            ),
          );

      final after = DateTime.now();
      final captured =
          verify(() => repo.save(captureAny())).captured.single as Bird;

      expect(captured.updatedAt, isNotNull);
      expect(
        captured.updatedAt!.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        captured.updatedAt!.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('clears previous error on new attempt', () async {
      // First: fail
      when(() => repo.save(any())).thenThrow(Exception('fail'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).updateBird(
            const Bird(
              id: 'b1',
              name: 'Bird',
              gender: BirdGender.male,
              userId: 'user-1',
            ),
          );
      expect(container.read(birdFormStateProvider).error, isNotNull);

      // Second: succeed
      when(() => repo.save(any())).thenAnswer((_) async {});

      await container.read(birdFormStateProvider.notifier).updateBird(
            const Bird(
              id: 'b1',
              name: 'Bird',
              gender: BirdGender.male,
              userId: 'user-1',
            ),
          );

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.error, isNull);
    });
  });

  // ── deleteBird ──

  group('deleteBird', () {
    test('sets isSuccess on success', () async {
      when(() => repo.remove(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).deleteBird('b1');

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('sets error on failure', () async {
      when(() => repo.remove(any())).thenThrow(Exception('delete error'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).deleteBird('b1');

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'errors.unknown');
      expect(state.isLoading, isFalse);
    });

    test('calls repo.remove with correct id', () async {
      when(() => repo.remove(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).deleteBird('b-42');

      verify(() => repo.remove('b-42')).called(1);
    });
  });

  // ── markAsDead ──

  group('markAsDead', () {
    test('updates bird status to dead', () async {
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

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isTrue);
      final captured =
          verify(() => repo.save(captureAny())).captured.single as Bird;
      expect(captured.status, BirdStatus.dead);
      expect(captured.deathDate, isNotNull);
    });

    test('uses provided death date', () async {
      const bird = Bird(
        id: 'b1',
        name: 'Test',
        gender: BirdGender.male,
        userId: 'user-1',
      );
      when(() => repo.getById('b1')).thenAnswer((_) async => bird);
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      final deathDate = DateTime(2024, 3, 15);
      await container
          .read(birdFormStateProvider.notifier)
          .markAsDead('b1', deathDate: deathDate);

      final captured =
          verify(() => repo.save(captureAny())).captured.single as Bird;
      expect(captured.deathDate, deathDate);
    });

    test('sets error when bird not found', () async {
      // getById returns null by default (from setUp)

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .markAsDead('nonexistent');

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'birds.not_found');
      verifyNever(() => repo.save(any()));
    });

    test('sets error on repository failure', () async {
      const bird = Bird(
        id: 'b1',
        name: 'Test',
        gender: BirdGender.male,
        userId: 'user-1',
      );
      when(() => repo.getById('b1')).thenAnswer((_) async => bird);
      when(() => repo.save(any())).thenThrow(Exception('save error'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).markAsDead('b1');

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'errors.unknown');
    });
  });

  // ── markAsSold ──

  group('markAsSold', () {
    test('updates bird status to sold', () async {
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

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isTrue);
      final captured =
          verify(() => repo.save(captureAny())).captured.single as Bird;
      expect(captured.status, BirdStatus.sold);
      expect(captured.soldDate, isNotNull);
    });

    test('uses provided sold date', () async {
      const bird = Bird(
        id: 'b1',
        name: 'Test',
        gender: BirdGender.male,
        userId: 'user-1',
      );
      when(() => repo.getById('b1')).thenAnswer((_) async => bird);
      when(() => repo.save(any())).thenAnswer((_) async {});

      final container = makeContainer();
      addTearDown(container.dispose);

      final soldDate = DateTime(2024, 5, 20);
      await container
          .read(birdFormStateProvider.notifier)
          .markAsSold('b1', soldDate: soldDate);

      final captured =
          verify(() => repo.save(captureAny())).captured.single as Bird;
      expect(captured.soldDate, soldDate);
    });

    test('sets error when bird not found', () async {
      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .markAsSold('nonexistent');

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'birds.not_found');
      verifyNever(() => repo.save(any()));
    });

    test('sets error on repository failure', () async {
      const bird = Bird(
        id: 'b1',
        name: 'Test',
        gender: BirdGender.male,
        userId: 'user-1',
      );
      when(() => repo.getById('b1')).thenAnswer((_) async => bird);
      when(() => repo.save(any())).thenThrow(Exception('save error'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container.read(birdFormStateProvider.notifier).markAsSold('b1');

      final state = container.read(birdFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, 'errors.unknown');
    });
  });

  // ── reset ──

  group('reset', () {
    test('restores initial state after createBird success', () async {
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
      expect(state.isBirdLimitReached, isFalse);
    });

    test('restores initial state after error', () async {
      stubUnderLimit();
      when(() => repo.save(any())).thenThrow(Exception('fail'));

      final container = makeContainer();
      addTearDown(container.dispose);

      await container
          .read(birdFormStateProvider.notifier)
          .createBird(userId: 'user-1', name: 'X', gender: BirdGender.male);
      expect(container.read(birdFormStateProvider).error, isNotNull);

      container.read(birdFormStateProvider.notifier).reset();

      final state = container.read(birdFormStateProvider);
      expect(state.error, isNull);
      expect(state.isLoading, isFalse);
    });
  });

  // ── BirdFormState ──

  group('BirdFormState', () {
    test('initial state has default values', () {
      const state = BirdFormState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
      expect(state.isBirdLimitReached, isFalse);
      expect(state.remainingBirds, isNull);
    });

    test('copyWith preserves unset fields', () {
      const state = BirdFormState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
      expect(updated.isSuccess, isFalse);
    });

    test('copyWith preserves isBirdLimitReached when not explicitly passed',
        () {
      final state = const BirdFormState().copyWith(isBirdLimitReached: true);
      expect(state.isBirdLimitReached, isTrue);

      final preserved = state.copyWith(isLoading: true);
      expect(preserved.isBirdLimitReached, isTrue);
    });

    test('copyWith preserves remainingBirds when not explicitly passed', () {
      final state = const BirdFormState().copyWith(remainingBirds: 5);
      expect(state.remainingBirds, 5);

      final preserved = state.copyWith(isLoading: true);
      expect(preserved.remainingBirds, 5);
    });

    test('copyWith clears error when passed null', () {
      final state = const BirdFormState().copyWith(error: 'fail');
      expect(state.error, 'fail');

      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });
  });
}
