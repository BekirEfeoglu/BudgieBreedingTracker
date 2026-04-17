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
            .watchMonthlyProductionBySpecies(args.userId, args.species.toJson());
      },
    );

final monthlyEggProductionProvider =
    Provider.family<AsyncValue<Map<String, int>>, String>((ref, userId) {
      final period = ref.watch(statsPeriodProvider);
      final speciesFilter = ref.watch(statsSpeciesFilterProvider).species;

      final aggregateAsync = speciesFilter == null
          ? ref.watch(_monthlyEggAggregateProvider(userId))
          : ref.watch(_monthlyEggAggregateBySpeciesProvider(
              (userId: userId, species: speciesFilter),
            ));

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

final monthlyHatchedChicksProvider =
    Provider.family<AsyncValue<Map<String, int>>, String>((ref, userId) {
      final chicksAsync = ref.watch(chicksStreamProvider(userId));
      final period = ref.watch(statsPeriodProvider);

      return chicksAsync.whenData((chicks) {
        final range = buildStatsDateRange(period);
        final months = buildEmptyMonthMap(
          period.monthCount,
          reference: range.currentEnd,
        );

        for (final chick in chicks) {
          final hatch = chick.hatchDate;
          if (hatch == null) continue;
          final key = '${hatch.year}-${hatch.month.toString().padLeft(2, '0')}';
          if (months.containsKey(key)) {
            months[key] = (months[key] ?? 0) + 1;
          }
        }

        return months;
      });
    });

final monthlyBreedingOutcomesProvider =
    Provider.family<AsyncValue<MonthlyBreedingData>, String>((ref, userId) {
      final pairsAsync = ref.watch(breedingPairsStreamProvider(userId));
      final incubationsAsync = ref.watch(incubationsStreamProvider(userId));
      final period = ref.watch(statsPeriodProvider);
      final speciesFilter = ref.watch(statsSpeciesFilterProvider).species;

      for (final async in [pairsAsync, incubationsAsync]) {
        if (async.hasError) {
          return AsyncError(async.error!, async.stackTrace ?? StackTrace.empty);
        }
      }
      if (pairsAsync.isLoading || incubationsAsync.isLoading) {
        return const AsyncLoading();
      }

      final pairs = pairsAsync.requireValue;
      final incubations = incubationsAsync.requireValue;
      final allowedPairIds = speciesFilter == null
          ? null
          : incubations
                .where((incubation) => incubation.species == speciesFilter)
                .map((incubation) => incubation.breedingPairId)
                .whereType<String>()
                .toSet();
      final filteredPairs = allowedPairIds == null
          ? pairs
          : pairs.where((pair) => allowedPairIds.contains(pair.id)).toList();

      return AsyncData(() {
        final range = buildStatsDateRange(period);
        final completedMap = buildEmptyMonthMap(
          period.monthCount,
          reference: range.currentEnd,
        );
        final cancelledMap = buildEmptyMonthMap(
          period.monthCount,
          reference: range.currentEnd,
        );

        for (final pair in filteredPairs) {
          final date = pair.separationDate ?? pair.updatedAt;
          if (date == null) continue;
          final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';

          if (pair.status == BreedingStatus.completed &&
              completedMap.containsKey(key)) {
            completedMap[key] = (completedMap[key] ?? 0) + 1;
          } else if (pair.status == BreedingStatus.cancelled &&
              cancelledMap.containsKey(key)) {
            cancelledMap[key] = (cancelledMap[key] ?? 0) + 1;
          }
        }

        return MonthlyBreedingData(
          completed: completedMap,
          cancelled: cancelledMap,
        );
      }());
    });

class MonthlyBreedingData {
  const MonthlyBreedingData({required this.completed, required this.cancelled});

  final Map<String, int> completed;
  final Map<String, int> cancelled;
}
