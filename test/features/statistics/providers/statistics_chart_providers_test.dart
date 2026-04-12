import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';

// ── Test Factories ──

Egg _egg({
  required String id,
  required DateTime layDate,
  EggStatus status = EggStatus.laid,
  String? incubationId,
}) {
  return Egg(
    id: id,
    userId: 'user-1',
    layDate: layDate,
    incubationId: incubationId,
    status: status,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

Chick _chick({
  required String id,
  ChickHealthStatus health = ChickHealthStatus.healthy,
  DateTime? hatchDate,
}) {
  return Chick(
    id: id,
    userId: 'user-1',
    healthStatus: health,
    hatchDate: hatchDate,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

BreedingPair _pair({
  required String id,
  required BreedingStatus status,
  DateTime? separationDate,
  DateTime? updatedAt,
}) {
  return BreedingPair(
    id: id,
    userId: 'user-1',
    status: status,
    separationDate: separationDate,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: updatedAt ?? DateTime(2024, 1, 1),
  );
}

Incubation _incubation({
  required String id,
  Species species = Species.budgie,
  String? breedingPairId,
}) {
  return Incubation(
    id: id,
    userId: 'user-1',
    species: species,
    breedingPairId: breedingPairId,
  );
}

// ── Container Builder ──

ProviderContainer _container({
  List<Egg> eggs = const [],
  List<Chick> chicks = const [],
  List<BreedingPair> pairs = const [],
  List<Incubation> incubations = const [],
  StatsPeriod period = StatsPeriod.sixMonths,
  Species? speciesFilter,
}) {
  final container = ProviderContainer(
    overrides: [
      eggsStreamProvider('user-1').overrideWith((_) => Stream.value(eggs)),
      chicksStreamProvider('user-1').overrideWith((_) => Stream.value(chicks)),
      breedingPairsStreamProvider(
        'user-1',
      ).overrideWith((_) => Stream.value(pairs)),
      incubationsStreamProvider(
        'user-1',
      ).overrideWith((_) => Stream.value(incubations)),
    ],
  );
  container.read(statsPeriodProvider.notifier).state = period;
  if (speciesFilter != null) {
    container.read(statsSpeciesFilterProvider.notifier).state = (
      species: speciesFilter,
      loaded: true,
    );
  }
  return container;
}

/// Listens to and awaits all stream providers used by chart providers.
Future<void> _awaitStreams(ProviderContainer container) async {
  const userId = 'user-1';
  container.listen(eggsStreamProvider(userId), (_, __) {});
  await container.read(eggsStreamProvider(userId).future);
  container.listen(chicksStreamProvider(userId), (_, __) {});
  await container.read(chicksStreamProvider(userId).future);
  container.listen(breedingPairsStreamProvider(userId), (_, __) {});
  await container.read(breedingPairsStreamProvider(userId).future);
  container.listen(incubationsStreamProvider(userId), (_, __) {});
  await container.read(incubationsStreamProvider(userId).future);
}

void main() {
  const userId = 'user-1';

  // ── monthlyEggProductionProvider ──

  group('monthlyEggProductionProvider', () {
    test('returns empty month map when no eggs', () async {
      final container = _container();
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyEggProductionProvider(userId));
      expect(value.hasValue, isTrue);
      final map = value.requireValue;
      expect(map.values.every((v) => v == 0), isTrue);
    });

    test('counts eggs in correct month buckets', () async {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 15);
      final lastMonth = DateTime(now.year, now.month - 1, 10);
      final currentKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final lastKey =
          '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}';

      final container = _container(
        eggs: [
          _egg(id: 'e1', layDate: currentMonth),
          _egg(id: 'e2', layDate: currentMonth),
          _egg(id: 'e3', layDate: lastMonth),
        ],
        period: StatsPeriod.threeMonths,
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyEggProductionProvider(userId));
      expect(value.hasValue, isTrue);
      final map = value.requireValue;
      expect(map[currentKey], 2);
      expect(map[lastKey], 1);
    });

    test('excludes eggs outside the period range', () async {
      final now = DateTime.now();
      final oldDate = DateTime(now.year, now.month - 10, 1);

      final container = _container(
        eggs: [_egg(id: 'old', layDate: oldDate)],
        period: StatsPeriod.threeMonths,
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyEggProductionProvider(userId));
      expect(value.hasValue, isTrue);
      final map = value.requireValue;
      expect(map.values.every((v) => v == 0), isTrue);
    });

    test('returns correct month count for each period', () async {
      for (final period in StatsPeriod.values) {
        final container = _container(period: period);
        addTearDown(container.dispose);
        await _awaitStreams(container);

        final value = container.read(monthlyEggProductionProvider(userId));
        expect(value.hasValue, isTrue);
        expect(value.requireValue.length, period.monthCount);
      }
    });

    test('filters eggs by species via incubation', () async {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, 5);

      final container = _container(
        eggs: [
          _egg(id: 'e1', layDate: date, incubationId: 'inc-budgie'),
          _egg(id: 'e2', layDate: date, incubationId: 'inc-cockatiel'),
          _egg(id: 'e3', layDate: date), // no incubation
        ],
        incubations: [
          _incubation(id: 'inc-budgie', species: Species.budgie),
          _incubation(id: 'inc-cockatiel', species: Species.cockatiel),
        ],
        period: StatsPeriod.threeMonths,
        speciesFilter: Species.budgie,
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyEggProductionProvider(userId));
      expect(value.hasValue, isTrue);
      final total = value.requireValue.values.fold<int>(0, (a, b) => a + b);
      expect(total, 1, reason: 'Only the budgie egg should be counted');
    });

    test('no species filter includes all eggs', () async {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, 5);

      final container = _container(
        eggs: [
          _egg(id: 'e1', layDate: date, incubationId: 'inc-1'),
          _egg(id: 'e2', layDate: date),
        ],
        incubations: [
          _incubation(id: 'inc-1', species: Species.budgie),
        ],
        period: StatsPeriod.threeMonths,
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyEggProductionProvider(userId));
      expect(value.hasValue, isTrue);
      final total = value.requireValue.values.fold<int>(0, (a, b) => a + b);
      expect(total, 2);
    });

    test('returns loading when eggs stream is loading', () {
      final container = ProviderContainer(
        overrides: [
          eggsStreamProvider(
            userId,
          ).overrideWith((_) => const Stream<List<Egg>>.empty()),
          incubationsStreamProvider(
            userId,
          ).overrideWith((_) => Stream.value(<Incubation>[])),
        ],
      );
      addTearDown(container.dispose);
      container.listen(eggsStreamProvider(userId), (_, __) {});
      container.listen(incubationsStreamProvider(userId), (_, __) {});

      final value = container.read(monthlyEggProductionProvider(userId));
      expect(value.isLoading, isTrue);
    });

    test('returns error when eggs stream has error', () async {
      final container = ProviderContainer(
        overrides: [
          eggsStreamProvider(
            userId,
          ).overrideWith((_) => Stream<List<Egg>>.error('test error')),
          incubationsStreamProvider(
            userId,
          ).overrideWith((_) => Stream.value(<Incubation>[])),
        ],
      );
      addTearDown(container.dispose);
      container.listen(eggsStreamProvider(userId), (_, __) {});
      container.listen(incubationsStreamProvider(userId), (_, __) {});
      // Wait for error to propagate
      await Future<void>.delayed(Duration.zero);

      final value = container.read(monthlyEggProductionProvider(userId));
      expect(value.hasError, isTrue);
    });

    test('returns error when incubations stream has error', () async {
      final container = ProviderContainer(
        overrides: [
          eggsStreamProvider(
            userId,
          ).overrideWith((_) => Stream.value(<Egg>[])),
          incubationsStreamProvider(
            userId,
          ).overrideWith(
            (_) => Stream<List<Incubation>>.error('incubation error'),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.listen(eggsStreamProvider(userId), (_, __) {});
      container.listen(incubationsStreamProvider(userId), (_, __) {});
      await Future<void>.delayed(Duration.zero);

      final value = container.read(monthlyEggProductionProvider(userId));
      expect(value.hasError, isTrue);
    });
  });

  // ── monthlyHatchedChicksProvider ──

  group('monthlyHatchedChicksProvider', () {
    test('returns empty month map when no chicks', () async {
      final container = _container();
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyHatchedChicksProvider(userId));
      expect(value.hasValue, isTrue);
      final map = value.requireValue;
      expect(map.values.every((v) => v == 0), isTrue);
    });

    test('counts hatched chicks per month', () async {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 10);
      final lastMonth = DateTime(now.year, now.month - 1, 20);
      final currentKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final lastKey =
          '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}';

      final container = _container(
        chicks: [
          _chick(id: 'c1', hatchDate: currentMonth),
          _chick(id: 'c2', hatchDate: currentMonth),
          _chick(id: 'c3', hatchDate: lastMonth),
        ],
        period: StatsPeriod.threeMonths,
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyHatchedChicksProvider(userId));
      expect(value.hasValue, isTrue);
      final map = value.requireValue;
      expect(map[currentKey], 2);
      expect(map[lastKey], 1);
    });

    test('skips chicks without hatch date', () async {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 10);

      final container = _container(
        chicks: [
          _chick(id: 'c1', hatchDate: currentMonth),
          _chick(id: 'c2'), // no hatch date
        ],
        period: StatsPeriod.threeMonths,
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyHatchedChicksProvider(userId));
      expect(value.hasValue, isTrue);
      final total = value.requireValue.values.fold<int>(0, (a, b) => a + b);
      expect(total, 1);
    });

    test('excludes chicks hatched outside period range', () async {
      final now = DateTime.now();
      final oldDate = DateTime(now.year, now.month - 10, 1);

      final container = _container(
        chicks: [_chick(id: 'old', hatchDate: oldDate)],
        period: StatsPeriod.threeMonths,
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyHatchedChicksProvider(userId));
      expect(value.hasValue, isTrue);
      final map = value.requireValue;
      expect(map.values.every((v) => v == 0), isTrue);
    });

    test('returns loading when chicks stream is loading', () {
      final container = ProviderContainer(
        overrides: [
          chicksStreamProvider(
            userId,
          ).overrideWith((_) => const Stream<List<Chick>>.empty()),
        ],
      );
      addTearDown(container.dispose);
      container.listen(chicksStreamProvider(userId), (_, __) {});

      final value = container.read(monthlyHatchedChicksProvider(userId));
      expect(value.isLoading, isTrue);
    });

    test('returns correct month count for period', () async {
      final container = _container(period: StatsPeriod.twelveMonths);
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyHatchedChicksProvider(userId));
      expect(value.hasValue, isTrue);
      expect(value.requireValue.length, 12);
    });
  });

  // ── monthlyBreedingOutcomesProvider ──

  group('monthlyBreedingOutcomesProvider', () {
    test('returns empty maps when no pairs', () async {
      final container = _container();
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyBreedingOutcomesProvider(userId));
      expect(value.hasValue, isTrue);
      final data = value.requireValue;
      expect(data.completed.values.every((v) => v == 0), isTrue);
      expect(data.cancelled.values.every((v) => v == 0), isTrue);
    });

    test('counts completed and cancelled pairs per month', () async {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 15);
      final currentKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final container = _container(
        pairs: [
          _pair(
            id: 'p1',
            status: BreedingStatus.completed,
            separationDate: thisMonth,
          ),
          _pair(
            id: 'p2',
            status: BreedingStatus.completed,
            separationDate: thisMonth,
          ),
          _pair(
            id: 'p3',
            status: BreedingStatus.cancelled,
            separationDate: thisMonth,
          ),
        ],
        period: StatsPeriod.threeMonths,
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyBreedingOutcomesProvider(userId));
      expect(value.hasValue, isTrue);
      final data = value.requireValue;
      expect(data.completed[currentKey], 2);
      expect(data.cancelled[currentKey], 1);
    });

    test('uses updatedAt as fallback when separationDate is null', () async {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 15);
      final currentKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final container = _container(
        pairs: [
          _pair(
            id: 'p1',
            status: BreedingStatus.completed,
            updatedAt: thisMonth,
          ),
        ],
        period: StatsPeriod.threeMonths,
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyBreedingOutcomesProvider(userId));
      expect(value.hasValue, isTrue);
      expect(value.requireValue.completed[currentKey], 1);
    });

    test('ignores active and ongoing pairs', () async {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 15);

      final container = _container(
        pairs: [
          _pair(
            id: 'p1',
            status: BreedingStatus.active,
            separationDate: thisMonth,
          ),
          _pair(
            id: 'p2',
            status: BreedingStatus.ongoing,
            separationDate: thisMonth,
          ),
        ],
        period: StatsPeriod.threeMonths,
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyBreedingOutcomesProvider(userId));
      expect(value.hasValue, isTrue);
      final data = value.requireValue;
      expect(data.completed.values.every((v) => v == 0), isTrue);
      expect(data.cancelled.values.every((v) => v == 0), isTrue);
    });

    test('excludes pairs outside period range', () async {
      final now = DateTime.now();
      final oldDate = DateTime(now.year, now.month - 10, 1);

      final container = _container(
        pairs: [
          _pair(
            id: 'p1',
            status: BreedingStatus.completed,
            separationDate: oldDate,
          ),
        ],
        period: StatsPeriod.threeMonths,
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyBreedingOutcomesProvider(userId));
      expect(value.hasValue, isTrue);
      expect(value.requireValue.completed.values.every((v) => v == 0), isTrue);
    });

    test('filters pairs by species via incubation breeding pair ID', () async {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 15);

      final container = _container(
        pairs: [
          _pair(
            id: 'pair-budgie',
            status: BreedingStatus.completed,
            separationDate: thisMonth,
          ),
          _pair(
            id: 'pair-cockatiel',
            status: BreedingStatus.completed,
            separationDate: thisMonth,
          ),
        ],
        incubations: [
          _incubation(
            id: 'inc-1',
            species: Species.budgie,
            breedingPairId: 'pair-budgie',
          ),
          _incubation(
            id: 'inc-2',
            species: Species.cockatiel,
            breedingPairId: 'pair-cockatiel',
          ),
        ],
        period: StatsPeriod.threeMonths,
        speciesFilter: Species.budgie,
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyBreedingOutcomesProvider(userId));
      expect(value.hasValue, isTrue);
      final totalCompleted = value.requireValue.completed.values
          .fold<int>(0, (a, b) => a + b);
      expect(totalCompleted, 1);
    });

    test('skips pairs where both separationDate and updatedAt are null',
        () async {
      final container = _container(
        pairs: [
          _pair(id: 'p1', status: BreedingStatus.completed, updatedAt: null),
        ],
        period: StatsPeriod.threeMonths,
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyBreedingOutcomesProvider(userId));
      expect(value.hasValue, isTrue);
      expect(value.requireValue.completed.values.every((v) => v == 0), isTrue);
    });

    test('returns loading when pairs stream is loading', () {
      final container = ProviderContainer(
        overrides: [
          breedingPairsStreamProvider(
            userId,
          ).overrideWith(
            (_) => const Stream<List<BreedingPair>>.empty(),
          ),
          incubationsStreamProvider(
            userId,
          ).overrideWith((_) => Stream.value(<Incubation>[])),
        ],
      );
      addTearDown(container.dispose);
      container.listen(breedingPairsStreamProvider(userId), (_, __) {});
      container.listen(incubationsStreamProvider(userId), (_, __) {});

      final value = container.read(monthlyBreedingOutcomesProvider(userId));
      expect(value.isLoading, isTrue);
    });

    test('returns error when pairs stream has error', () async {
      final container = ProviderContainer(
        overrides: [
          breedingPairsStreamProvider(userId).overrideWith(
            (_) => Stream<List<BreedingPair>>.error('pairs error'),
          ),
          incubationsStreamProvider(
            userId,
          ).overrideWith((_) => Stream.value(<Incubation>[])),
        ],
      );
      addTearDown(container.dispose);
      container.listen(breedingPairsStreamProvider(userId), (_, __) {});
      container.listen(incubationsStreamProvider(userId), (_, __) {});
      await Future<void>.delayed(Duration.zero);

      final value = container.read(monthlyBreedingOutcomesProvider(userId));
      expect(value.hasError, isTrue);
    });

    test('completed and cancelled maps have same month count', () async {
      final container = _container(period: StatsPeriod.sixMonths);
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value = container.read(monthlyBreedingOutcomesProvider(userId));
      expect(value.hasValue, isTrue);
      final data = value.requireValue;
      expect(data.completed.length, 6);
      expect(data.cancelled.length, 6);
      expect(data.completed.keys.toList(), data.cancelled.keys.toList());
    });
  });

  // ── MonthlyBreedingData ──

  group('MonthlyBreedingData', () {
    test('stores completed and cancelled maps', () {
      const data = MonthlyBreedingData(
        completed: {'2024-01': 3, '2024-02': 1},
        cancelled: {'2024-01': 0, '2024-02': 2},
      );
      expect(data.completed['2024-01'], 3);
      expect(data.cancelled['2024-02'], 2);
    });
  });

  // ── Period switching ──

  group('period switching', () {
    test('changing period updates month map length', () async {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, 5);

      final container = _container(
        eggs: [_egg(id: 'e1', layDate: date)],
        period: StatsPeriod.threeMonths,
      );
      addTearDown(container.dispose);
      await _awaitStreams(container);

      final value3m = container.read(monthlyEggProductionProvider(userId));
      expect(value3m.requireValue.length, 3);

      container.read(statsPeriodProvider.notifier).state =
          StatsPeriod.twelveMonths;
      final value12m = container.read(monthlyEggProductionProvider(userId));
      expect(value12m.requireValue.length, 12);
    });
  });
}
