import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';

import '../../../helpers/mocks.dart';

/// Builds a `month → (fertile, total)` map matching what
/// `EggsDao.watchMonthlyFertility` returns for [eggs], applying an optional
/// species filter via [incubations]. Keeps the unit test independent from
/// the SQL aggregation while mirroring its semantics (fertile/hatched →
/// fertile, fertile+infertile+hatched → total, laid excluded).
Map<String, ({int fertile, int total})> _eggsToFertility(
  List<Egg> eggs, {
  List<Incubation> incubations = const [],
  Species? species,
}) {
  final result = <String, ({int fertile, int total})>{};
  final allowedIncubations = species == null
      ? null
      : incubations
          .where((i) => i.species == species)
          .map((i) => i.id)
          .toSet();
  for (final egg in eggs) {
    if (allowedIncubations != null) {
      if (egg.incubationId == null ||
          !allowedIncubations.contains(egg.incubationId)) {
        continue;
      }
    }
    final isFertile = egg.status == EggStatus.fertile ||
        egg.status == EggStatus.hatched;
    final isInfertile = egg.status == EggStatus.infertile;
    if (!isFertile && !isInfertile) continue;
    final key =
        '${egg.layDate.year}-${egg.layDate.month.toString().padLeft(2, '0')}';
    final current = result[key] ?? (fertile: 0, total: 0);
    result[key] = (
      fertile: current.fertile + (isFertile ? 1 : 0),
      total: current.total + 1,
    );
  }
  return result;
}

MockEggsDao _fertilityDao({
  Map<String, ({int fertile, int total})> unfiltered = const {},
  Map<String, ({int fertile, int total})> filtered = const {},
}) {
  final dao = MockEggsDao();
  when(
    () => dao.watchMonthlyFertility(any(), species: any(named: 'species')),
  ).thenAnswer((invocation) {
    final hasSpecies = invocation.namedArguments[const Symbol('species')] != null;
    return Stream.value(hasSpecies ? filtered : unfiltered);
  });
  return dao;
}

class _FixedSpeciesNotifier extends StatsSpeciesFilterNotifier {
  final Species? _species;
  _FixedSpeciesNotifier(this._species);

  @override
  ({Species? species, bool loaded}) build() =>
      (species: _species, loaded: true);
}

void main() {
  late MockIncubationRepository repo;

  setUp(() {
    repo = MockIncubationRepository();
  });

  group('incubationsStreamProvider', () {
    test('delegates to repository.watchAll', () async {
      final incubations = [
        Incubation(
          id: 'i1',
          breedingPairId: 'bp1',
          userId: 'u1',
          status: IncubationStatus.active,
          startDate: DateTime(2024, 1, 1),
        ),
      ];
      when(
        () => repo.watchAll('u1'),
      ).thenAnswer((_) => Stream.value(incubations));

      final container = ProviderContainer(
        overrides: [incubationRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      container.listen(incubationsStreamProvider('u1'), (_, __) {});
      final result = await container.read(
        incubationsStreamProvider('u1').future,
      );

      expect(result, hasLength(1));
      expect(result.first.status, IncubationStatus.active);
    });
  });

  group('incubationDurationProvider', () {
    test(
      'uses species-aware expected days for completed incubations',
      () async {
        final incubations = [
          Incubation(
            id: 'i1',
            userId: 'u1',
            species: Species.canary,
            status: IncubationStatus.completed,
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 14),
          ),
          Incubation(
            id: 'i2',
            userId: 'u1',
            species: Species.cockatiel,
            status: IncubationStatus.completed,
            startDate: DateTime(2024, 2, 1),
            endDate: DateTime(2024, 2, 19),
          ),
        ];
        when(
          () => repo.watchAll('u1'),
        ).thenAnswer((_) => Stream.value(incubations));

        final container = ProviderContainer(
          overrides: [incubationRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        container.listen(incubationDurationProvider('u1'), (_, __) {});
        await container.read(incubationsStreamProvider('u1').future);
        final asyncValue = container.read(incubationDurationProvider('u1'));
        expect(asyncValue.hasValue, isTrue);
        final result = asyncValue.requireValue;

        expect(result, hasLength(2));
        expect(result[0].id, 'i2');
        expect(result[0].actualDays, 18);
        expect(result[0].expectedDays, 19);
        expect(result[1].id, 'i1');
        expect(result[1].actualDays, 13);
        expect(result[1].expectedDays, 13);
      },
    );
  });

  group('monthlyFertilityRateProvider', () {
    test('filters fertility data by selected species', () async {
      final now = DateTime.now();
      final currentKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final incubations = [
        const Incubation(id: 'i1', userId: 'u1', species: Species.canary),
        const Incubation(id: 'i2', userId: 'u1', species: Species.budgie),
      ];
      final eggs = [
        Egg(
          id: 'e1',
          userId: 'u1',
          layDate: now,
          incubationId: 'i1',
          status: EggStatus.fertile,
        ),
        Egg(
          id: 'e2',
          userId: 'u1',
          layDate: now,
          incubationId: 'i1',
          status: EggStatus.infertile,
        ),
        Egg(
          id: 'e3',
          userId: 'u1',
          layDate: now,
          incubationId: 'i2',
          status: EggStatus.fertile,
        ),
      ];
      when(
        () => repo.watchAll('u1'),
      ).thenAnswer((_) => Stream.value(incubations));

      // The provider now delegates aggregation to
      // EggsDao.watchMonthlyFertility instead of looping eggs in Dart, so
      // tests mock the DAO directly. The species-filter path is verified
      // by passing the post-filter map under `filtered`.
      final container = ProviderContainer(
        overrides: [
          incubationRepositoryProvider.overrideWithValue(repo),
          eggsDaoProvider.overrideWithValue(
            _fertilityDao(
              unfiltered: _eggsToFertility(eggs),
              filtered: _eggsToFertility(
                eggs,
                incubations: incubations,
                species: Species.canary,
              ),
            ),
          ),
          statsSpeciesFilterProvider.overrideWith(
            () => _FixedSpeciesNotifier(Species.canary),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(statsPeriodProvider.notifier).state =
          StatsPeriod.threeMonths;
      container.listen(incubationsStreamProvider('u1'), (_, __) {});
      await container.read(incubationsStreamProvider('u1').future);
      // Trigger the species-filter aware aggregate to subscribe to the mock
      // DAO stream, then yield so Stream.value emissions can propagate.
      container.listen(monthlyFertilityRateProvider('u1'), (_, __) {});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final asyncValue = container.read(monthlyFertilityRateProvider('u1'));
      expect(asyncValue.hasValue, isTrue);
      expect(asyncValue.requireValue[currentKey], 50.0);
    });
  });
}
