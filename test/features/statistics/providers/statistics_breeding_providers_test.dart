import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';

import '../../../helpers/mocks.dart';

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
        expect(result[1].expectedDays, 14);
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

      final container = ProviderContainer(
        overrides: [
          incubationRepositoryProvider.overrideWithValue(repo),
          eggsStreamProvider('u1').overrideWith((_) => Stream.value(eggs)),
        ],
      );
      addTearDown(container.dispose);

      container.read(statsPeriodProvider.notifier).state =
          StatsPeriod.threeMonths;
      container
          .read(statsSpeciesFilterProvider.notifier)
          .setSpecies(Species.canary);
      container.listen(incubationsStreamProvider('u1'), (_, __) {});
      await container.read(incubationsStreamProvider('u1').future);
      container.listen(eggsStreamProvider('u1'), (_, __) {});
      await container.read(eggsStreamProvider('u1').future);

      final asyncValue = container.read(monthlyFertilityRateProvider('u1'));
      expect(asyncValue.hasValue, isTrue);
      expect(asyncValue.requireValue[currentKey], 50.0);
    });
  });
}
