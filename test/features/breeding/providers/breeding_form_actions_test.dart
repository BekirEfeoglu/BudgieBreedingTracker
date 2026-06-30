import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_form_providers.dart';
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
  String breedingPairId = 'pair-1',
  Species species = Species.unknown,
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

Clutch _clutch({String id = 'clutch-1', String breedingId = 'pair-1'}) {
  return Clutch(id: id, userId: 'user-1', breedingId: breedingId);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBreedingPairRepository mockPairRepo;
  late MockIncubationRepository mockIncubationRepo;
  late MockEggRepository mockEggRepo;
  late MockBirdRepository mockBirdRepo;
  late MockChickRepository mockChickRepo;
  late MockClutchRepository mockClutchRepo;
  late MockNotificationScheduler mockScheduler;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockPairRepo = MockBreedingPairRepository();
    mockIncubationRepo = MockIncubationRepository();
    mockEggRepo = MockEggRepository();
    mockBirdRepo = MockBirdRepository();
    mockChickRepo = MockChickRepository();
    mockClutchRepo = MockClutchRepository();
    mockScheduler = MockNotificationScheduler();

    registerFallbackValue(_pair());
    registerFallbackValue(
      const Incubation(id: 'fallback', userId: 'fallback-user'),
    );
    registerFallbackValue(_egg());
    registerFallbackValue(const Chick(id: 'fallback', userId: 'fallback-user'));
    registerFallbackValue(Species.unknown);
    when(
      () => mockScheduler.cancelIncubationMilestones(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockScheduler.cancelEggTurningReminders(
        any(),
        species: any(named: 'species'),
      ),
    ).thenAnswer((_) async {});
    // Default: no chicks linked to any egg
    when(() => mockChickRepo.getByEggIds(any())).thenAnswer((_) async => []);
    // Default: no legacy clutch rows for the pair being deleted
    when(() => mockClutchRepo.getByBreeding(any())).thenAnswer((_) async => []);
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        breedingPairRepositoryProvider.overrideWithValue(mockPairRepo),
        incubationRepositoryProvider.overrideWithValue(mockIncubationRepo),
        eggRepositoryProvider.overrideWithValue(mockEggRepo),
        birdRepositoryProvider.overrideWithValue(mockBirdRepo),
        chickRepositoryProvider.overrideWithValue(mockChickRepo),
        clutchRepositoryProvider.overrideWithValue(mockClutchRepo),
        notificationSchedulerProvider.overrideWithValue(mockScheduler),
        isPremiumProvider.overrideWithValue(false),
        effectivePremiumProvider.overrideWithValue(false),
      ],
    );
  }

  /// Stubs the incubation + egg fetches needed by the helper methods.
  void stubHelperDeps({
    List<Incubation> incubations = const [],
    List<Egg> eggs = const [],
  }) {
    when(
      () => mockIncubationRepo.getByBreedingPairIds(any()),
    ).thenAnswer((_) async => incubations);
    when(() => mockIncubationRepo.saveAll(any())).thenAnswer((_) async {});
    when(
      () => mockEggRepo.getByIncubationIds(any()),
    ).thenAnswer((_) async => eggs);
  }

  // ─── cancelBreeding ─────────────────────────────────────────────

  group('BreedingFormActions.cancelBreeding', () {
    test('sets isSuccess when pair found and cancelled', () async {
      when(
        () => mockPairRepo.getById('pair-1'),
      ).thenAnswer((_) async => _pair());
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      stubHelperDeps();

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .cancelBreeding('pair-1');

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('saves pair with cancelled status and separationDate', () async {
      when(
        () => mockPairRepo.getById('pair-1'),
      ).thenAnswer((_) async => _pair());
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      stubHelperDeps();

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .cancelBreeding('pair-1');

      final captured =
          verify(() => mockPairRepo.save(captureAny())).captured.single
              as BreedingPair;
      expect(captured.status, BreedingStatus.cancelled);
      expect(captured.separationDate, isNotNull);
    });

    test('closes active incubations with cancelled status', () async {
      final activeInc = _incubation(status: IncubationStatus.active);
      when(
        () => mockPairRepo.getById('pair-1'),
      ).thenAnswer((_) async => _pair());
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      stubHelperDeps(incubations: [activeInc]);

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .cancelBreeding('pair-1');

      final captured =
          verify(() => mockIncubationRepo.saveAll(captureAny())).captured.single
              as List<Incubation>;
      expect(captured.length, 1);
      expect(captured.first.status, IncubationStatus.cancelled);
    });

    test('sets error when pair not found', () async {
      when(() => mockPairRepo.getById('pair-1')).thenAnswer((_) async => null);

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .cancelBreeding('pair-1');

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('sets error state when repo throws', () async {
      when(
        () => mockPairRepo.getById('pair-1'),
      ).thenThrow(Exception('DB error'));

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .cancelBreeding('pair-1');

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('sets loading true during operation', () async {
      when(
        () => mockPairRepo.getById('pair-1'),
      ).thenAnswer((_) async => _pair());
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      stubHelperDeps();

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(breedingFormStateProvider.notifier);

      // Track loading states
      final states = <bool>[];
      container.listen(
        breedingFormStateProvider,
        (_, next) => states.add(next.isLoading),
      );

      await notifier.cancelBreeding('pair-1');

      // Should have been true at start, then false at end
      expect(states, contains(true));
      expect(states.last, isFalse);
    });

    test('does not save incubations when none are active', () async {
      final completedInc = _incubation(status: IncubationStatus.completed);
      when(
        () => mockPairRepo.getById('pair-1'),
      ).thenAnswer((_) async => _pair());
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      stubHelperDeps(incubations: [completedInc]);

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .cancelBreeding('pair-1');

      // saveAll should not be called when no active incubations are filtered
      verifyNever(() => mockIncubationRepo.saveAll(any()));
    });

    test(
      'sets warning (not error) when reminder cancellation fails',
      () async {
        final activeInc = _incubation(status: IncubationStatus.active);
        when(
          () => mockPairRepo.getById('pair-1'),
        ).thenAnswer((_) async => _pair());
        when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
        stubHelperDeps(incubations: [activeInc]);
        when(
          () => mockScheduler.cancelIncubationMilestones(any()),
        ).thenThrow(Exception('scheduler unavailable'));

        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(breedingFormStateProvider.notifier)
            .cancelBreeding('pair-1');

        final state = container.read(breedingFormStateProvider);
        // The primary mutation (pair cancelled) still succeeds — a
        // best-effort reminder-cleanup failure must surface as a warning,
        // not block success or read back as a hard error.
        expect(state.isSuccess, isTrue);
        expect(state.error, isNull);
        expect(state.warning, isNotNull);
      },
    );
  });

  // ─── completeBreeding ───────────────────────────────────────────

  group('BreedingFormActions.completeBreeding', () {
    test('sets isSuccess when pair found and completed', () async {
      when(
        () => mockPairRepo.getById('pair-1'),
      ).thenAnswer((_) async => _pair());
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      stubHelperDeps();

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .completeBreeding('pair-1');

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('saves pair with completed status and separationDate', () async {
      when(
        () => mockPairRepo.getById('pair-1'),
      ).thenAnswer((_) async => _pair());
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      stubHelperDeps();

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .completeBreeding('pair-1');

      final captured =
          verify(() => mockPairRepo.save(captureAny())).captured.single
              as BreedingPair;
      expect(captured.status, BreedingStatus.completed);
      expect(captured.separationDate, isNotNull);
    });

    test('closes active incubations with completed status', () async {
      final activeInc = _incubation(status: IncubationStatus.active);
      when(
        () => mockPairRepo.getById('pair-1'),
      ).thenAnswer((_) async => _pair());
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      stubHelperDeps(incubations: [activeInc]);

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .completeBreeding('pair-1');

      final captured =
          verify(() => mockIncubationRepo.saveAll(captureAny())).captured.single
              as List<Incubation>;
      expect(captured.length, 1);
      expect(captured.first.status, IncubationStatus.completed);
    });

    test('sets error when pair not found', () async {
      when(() => mockPairRepo.getById('pair-1')).thenAnswer((_) async => null);

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .completeBreeding('pair-1');

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('sets error state when repo throws', () async {
      when(
        () => mockPairRepo.getById('pair-1'),
      ).thenThrow(Exception('DB error'));

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .completeBreeding('pair-1');

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('sets loading true during operation', () async {
      when(
        () => mockPairRepo.getById('pair-1'),
      ).thenAnswer((_) async => _pair());
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
      stubHelperDeps();

      final container = createContainer();
      addTearDown(container.dispose);

      final states = <bool>[];
      container.listen(
        breedingFormStateProvider,
        (_, next) => states.add(next.isLoading),
      );

      await container
          .read(breedingFormStateProvider.notifier)
          .completeBreeding('pair-1');

      expect(states, contains(true));
      expect(states.last, isFalse);
    });

    test(
      'sets warning (not error) when reminder cancellation fails',
      () async {
        final activeInc = _incubation(status: IncubationStatus.active);
        when(
          () => mockPairRepo.getById('pair-1'),
        ).thenAnswer((_) async => _pair());
        when(() => mockPairRepo.save(any())).thenAnswer((_) async {});
        stubHelperDeps(incubations: [activeInc]);
        when(
          () => mockScheduler.cancelIncubationMilestones(any()),
        ).thenThrow(Exception('scheduler unavailable'));

        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(breedingFormStateProvider.notifier)
            .completeBreeding('pair-1');

        final state = container.read(breedingFormStateProvider);
        expect(state.isSuccess, isTrue);
        expect(state.error, isNull);
        expect(state.warning, isNotNull);
      },
    );
  });

  // ─── deleteBreeding ─────────────────────────────────────────────

  group('BreedingFormActions.deleteBreeding', () {
    test('sets isSuccess after removing pair', () async {
      stubHelperDeps();
      when(() => mockPairRepo.remove(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .deleteBreeding('pair-1');

      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('calls remove with the correct id', () async {
      stubHelperDeps();
      when(() => mockPairRepo.remove(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .deleteBreeding('pair-42');

      verify(() => mockPairRepo.remove('pair-42')).called(1);
    });

    test('removes related eggs before removing pair', () async {
      final incubations = [_incubation()];
      final eggs = [_egg(), _egg(id: 'egg-2')];
      stubHelperDeps(incubations: incubations, eggs: eggs);
      when(() => mockEggRepo.remove(any())).thenAnswer((_) async {});
      when(() => mockIncubationRepo.remove(any())).thenAnswer((_) async {});
      when(() => mockPairRepo.remove(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .deleteBreeding('pair-1');

      verify(() => mockEggRepo.remove('egg-1')).called(1);
      verify(() => mockEggRepo.remove('egg-2')).called(1);
    });

    test(
      'removes legacy clutch rows tied to the pair before removing it',
      () async {
        stubHelperDeps();
        when(
          () => mockClutchRepo.getByBreeding('pair-1'),
        ).thenAnswer((_) async => [_clutch(), _clutch(id: 'clutch-2')]);
        when(() => mockClutchRepo.remove(any())).thenAnswer((_) async {});
        when(() => mockPairRepo.remove(any())).thenAnswer((_) async {});

        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(breedingFormStateProvider.notifier)
            .deleteBreeding('pair-1');

        verify(() => mockClutchRepo.remove('clutch-1')).called(1);
        verify(() => mockClutchRepo.remove('clutch-2')).called(1);
        final state = container.read(breedingFormStateProvider);
        expect(state.isSuccess, isTrue);
      },
    );

    test(
      'a failed clutch removal surfaces a warning but does not block the delete',
      () async {
        stubHelperDeps();
        when(
          () => mockClutchRepo.getByBreeding('pair-1'),
        ).thenAnswer((_) async => [_clutch()]);
        // Use an async-throwing stub (not `thenThrow`) so the failure
        // surfaces as a rejected Future, matching how the real `async`
        // repository method would actually fail.
        when(
          () => mockClutchRepo.remove('clutch-1'),
        ).thenAnswer((_) async => throw Exception('local DB error'));
        when(() => mockPairRepo.remove(any())).thenAnswer((_) async {});

        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(breedingFormStateProvider.notifier)
            .deleteBreeding('pair-1');

        final state = container.read(breedingFormStateProvider);
        expect(state.isSuccess, isTrue);
        verify(() => mockPairRepo.remove('pair-1')).called(1);
        expect(state.warning, isNotNull);
      },
    );

    test('removes related incubations before removing pair', () async {
      final incubations = [_incubation()];
      stubHelperDeps(incubations: incubations);
      when(() => mockEggRepo.remove(any())).thenAnswer((_) async {});
      when(() => mockIncubationRepo.remove(any())).thenAnswer((_) async {});
      when(() => mockPairRepo.remove(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .deleteBreeding('pair-1');

      verify(() => mockIncubationRepo.remove('inc-1')).called(1);
    });

    test(
      'cancels incubation and egg notifications for related records',
      () async {
        final incubations = [_incubation(species: Species.budgie)];
        final eggs = [_egg(), _egg(id: 'egg-2')];
        stubHelperDeps(incubations: incubations, eggs: eggs);
        when(() => mockEggRepo.remove(any())).thenAnswer((_) async {});
        when(() => mockIncubationRepo.remove(any())).thenAnswer((_) async {});
        when(() => mockPairRepo.remove(any())).thenAnswer((_) async {});

        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(breedingFormStateProvider.notifier)
            .deleteBreeding('pair-1');

        verify(
          () => mockScheduler.cancelIncubationMilestones('inc-1'),
        ).called(1);
        verifyNever(
          () => mockScheduler.cancelEggTurningReminders(
            'inc-1',
            species: any(named: 'species'),
          ),
        );
        verify(
          () => mockScheduler.cancelEggTurningReminders(
            'egg-1',
            species: Species.budgie,
          ),
        ).called(1);
        verify(
          () => mockScheduler.cancelEggTurningReminders(
            'egg-2',
            species: Species.budgie,
          ),
        ).called(1);
      },
    );

    test('clears eggId and clutchId on chicks before removing eggs', () async {
      final incubations = [_incubation()];
      final eggs = [_egg()];
      const chick = Chick(
        id: 'chick-1',
        userId: 'user-1',
        eggId: 'egg-1',
        clutchId: 'clutch-1',
      );
      stubHelperDeps(incubations: incubations, eggs: eggs);
      when(
        () => mockChickRepo.getByEggIds(['egg-1']),
      ).thenAnswer((_) async => [chick]);
      when(() => mockChickRepo.save(any())).thenAnswer((_) async {});
      when(() => mockEggRepo.remove(any())).thenAnswer((_) async {});
      when(() => mockIncubationRepo.remove(any())).thenAnswer((_) async {});
      when(() => mockPairRepo.remove(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .deleteBreeding('pair-1');

      final captured =
          verify(() => mockChickRepo.save(captureAny())).captured.single
              as Chick;
      expect(captured.id, 'chick-1');
      expect(captured.eggId, isNull);
      expect(captured.clutchId, isNull);
    });

    test('does not remove pair when related cleanup fails', () async {
      when(
        () => mockIncubationRepo.getByBreedingPairIds(any()),
      ).thenThrow(Exception('Cleanup error'));
      when(() => mockPairRepo.remove(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(breedingFormStateProvider.notifier)
          .deleteBreeding('pair-1');

      verifyNever(() => mockPairRepo.remove('pair-1'));
      final state = container.read(breedingFormStateProvider);
      expect(state.isSuccess, isFalse);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('sets error when pair remove throws', () async {
      stubHelperDeps();
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
      expect(state.isLoading, isFalse);
    });

    test('sets loading true during operation', () async {
      stubHelperDeps();
      when(() => mockPairRepo.remove(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      final states = <bool>[];
      container.listen(
        breedingFormStateProvider,
        (_, next) => states.add(next.isLoading),
      );

      await container
          .read(breedingFormStateProvider.notifier)
          .deleteBreeding('pair-1');

      expect(states, contains(true));
      expect(states.last, isFalse);
    });

    test('sets isSuccess to false before starting', () async {
      stubHelperDeps();
      when(() => mockPairRepo.remove(any())).thenAnswer((_) async {});
      when(() => mockPairRepo.save(any())).thenAnswer((_) async {});

      final container = createContainer();
      addTearDown(container.dispose);

      // First, put notifier in a success state via another action
      when(
        () => mockPairRepo.getById('pair-1'),
      ).thenAnswer((_) async => _pair());
      await container
          .read(breedingFormStateProvider.notifier)
          .cancelBreeding('pair-1');
      expect(container.read(breedingFormStateProvider).isSuccess, isTrue);

      // Now delete should reset isSuccess at start
      final states = <bool>[];
      container.listen(
        breedingFormStateProvider,
        (_, next) => states.add(next.isSuccess),
      );

      await container
          .read(breedingFormStateProvider.notifier)
          .deleteBreeding('pair-1');

      // First state change sets isSuccess=false, last sets it to true
      expect(states.first, isFalse);
      expect(states.last, isTrue);
    });
  });
}
