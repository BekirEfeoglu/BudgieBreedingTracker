part of 'statistics_providers.dart';

/// Raw monthly egg counts via SQL aggregate (no row mapping).
final _monthlyEggAggregateProvider =
    StreamProvider.family<Map<String, int>, String>((ref, userId) {
      return ref.watch(eggsDaoProvider).watchMonthlyProduction(userId);
    });

/// Species-filtered monthly egg counts via SQL aggregate + JOIN.
///
/// Uses a composite family key `(userId, species)` so independent species
/// filters don't clobber each other's stream.
final _monthlyEggAggregateBySpeciesProvider =
    StreamProvider.family<Map<String, int>, ({String userId, Species species})>(
      (ref, args) {
        return ref
            .watch(eggsDaoProvider)
            .watchMonthlyProductionBySpecies(
              args.userId,
              args.species.toJson(),
            );
      },
    );

final monthlyEggProductionProvider =
    Provider.family<AsyncValue<Map<String, int>>, String>((ref, userId) {
      final period = ref.watch(statsPeriodProvider);
      final speciesFilter = ref.watch(statsSpeciesFilterProvider).species;

      final aggregateAsync = speciesFilter == null
          ? ref.watch(_monthlyEggAggregateProvider(userId))
          : ref.watch(
              _monthlyEggAggregateBySpeciesProvider((
                userId: userId,
                species: speciesFilter,
              )),
            );

      return aggregateAsync.whenData((rawCounts) {
        final range = buildStatsDateRange(period);
        final months = buildEmptyMonthMap(
          period.monthCount,
          reference: range.currentEnd,
        );
        for (final entry in rawCounts.entries) {
          if (months.containsKey(entry.key)) {
            months[entry.key] = entry.value;
          }
        }
        return months;
      });
    });

/// Raw SQL-aggregated monthly hatched chicks (no period window applied).
/// Period-window logic stays in the public provider so it can be reused.
final _monthlyHatchedAggregateProvider =
    StreamProvider.family<Map<String, int>, String>((ref, userId) {
      return ref.watch(chicksDaoProvider).watchMonthlyHatched(userId);
    });

final monthlyHatchedChicksProvider =
    Provider.family<AsyncValue<Map<String, int>>, String>((ref, userId) {
      final period = ref.watch(statsPeriodProvider);
      final aggregate = ref.watch(_monthlyHatchedAggregateProvider(userId));

      return aggregate.whenData((counts) {
        final range = buildStatsDateRange(period);
        final months = buildEmptyMonthMap(
          period.monthCount,
          reference: range.currentEnd,
        );
        for (final entry in counts.entries) {
          if (months.containsKey(entry.key)) {
            months[entry.key] = entry.value;
          }
        }
        return months;
      });
    });

/// Raw SQL-aggregated outcomes (no species filter).
final _monthlyOutcomesAggregateProvider =
    StreamProvider.family<
      Map<String, ({int completed, int cancelled})>,
      String
    >((ref, userId) {
      return ref.watch(breedingPairsDaoProvider).watchMonthlyOutcomes(userId);
    });

/// Species-filtered SQL-aggregated outcomes. Composite key keeps
/// independent filter streams cached separately.
final _monthlyOutcomesAggregateBySpeciesProvider =
    StreamProvider.family<
      Map<String, ({int completed, int cancelled})>,
      ({String userId, Species species})
    >((ref, args) {
      return ref
          .watch(breedingPairsDaoProvider)
          .watchMonthlyOutcomes(args.userId, species: args.species.toJson());
    });

final monthlyBreedingOutcomesProvider =
    Provider.family<AsyncValue<MonthlyBreedingData>, String>((ref, userId) {
      final period = ref.watch(statsPeriodProvider);
      final speciesFilter = ref.watch(statsSpeciesFilterProvider).species;

      final aggregate = speciesFilter == null
          ? ref.watch(_monthlyOutcomesAggregateProvider(userId))
          : ref.watch(
              _monthlyOutcomesAggregateBySpeciesProvider((
                userId: userId,
                species: speciesFilter,
              )),
            );

      return aggregate.whenData((rawCounts) {
        final range = buildStatsDateRange(period);
        final completedMap = buildEmptyMonthMap(
          period.monthCount,
          reference: range.currentEnd,
        );
        final cancelledMap = buildEmptyMonthMap(
          period.monthCount,
          reference: range.currentEnd,
        );
        for (final entry in rawCounts.entries) {
          if (completedMap.containsKey(entry.key)) {
            completedMap[entry.key] = entry.value.completed;
            cancelledMap[entry.key] = entry.value.cancelled;
          }
        }
        return MonthlyBreedingData(
          completed: completedMap,
          cancelled: cancelledMap,
        );
      });
    });

class MonthlyBreedingData {
  const MonthlyBreedingData({required this.completed, required this.cancelled});

  final Map<String, int> completed;
  final Map<String, int> cancelled;
}
