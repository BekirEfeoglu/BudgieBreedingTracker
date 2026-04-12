part of 'statistics_providers.dart';

final monthlyEggProductionProvider =
    Provider.family<AsyncValue<Map<String, int>>, String>((ref, userId) {
      final eggsAsync = ref.watch(eggsStreamProvider(userId));
      final incubationsAsync = ref.watch(incubationsStreamProvider(userId));
      final period = ref.watch(statsPeriodProvider);
      final speciesFilter = ref.watch(statsSpeciesFilterProvider).species;

      for (final async in [eggsAsync, incubationsAsync]) {
        if (async.hasError) {
          return AsyncError(async.error!, async.stackTrace ?? StackTrace.empty);
        }
      }
      if (eggsAsync.isLoading || incubationsAsync.isLoading) {
        return const AsyncLoading();
      }

      final eggs = eggsAsync.requireValue;
      final incubations = incubationsAsync.requireValue;
      final allowedIncubationIds = speciesFilter == null
          ? null
          : incubations
                .where((incubation) => incubation.species == speciesFilter)
                .map((incubation) => incubation.id)
                .toSet();
      final filteredEggs = allowedIncubationIds == null
          ? eggs
          : eggs
                .where(
                  (egg) =>
                      egg.incubationId != null &&
                      allowedIncubationIds.contains(egg.incubationId),
                )
                .toList();

      return AsyncData(() {
        final range = buildStatsDateRange(period);
        final months = buildEmptyMonthMap(
          period.monthCount,
          reference: range.currentEnd,
        );

        for (final egg in filteredEggs) {
          final key =
              '${egg.layDate.year}-${egg.layDate.month.toString().padLeft(2, '0')}';
          if (months.containsKey(key)) {
            months[key] = (months[key] ?? 0) + 1;
          }
        }

        return months;
      }());
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
