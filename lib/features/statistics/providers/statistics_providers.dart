import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_breeding_providers.dart';

/// Period options for statistics date range filtering.
enum StatsPeriod {
  threeMonths,
  sixMonths,
  twelveMonths;

  String get labelKey => switch (this) {
    StatsPeriod.threeMonths => 'statistics.period_3_months',
    StatsPeriod.sixMonths => 'statistics.period_6_months',
    StatsPeriod.twelveMonths => 'statistics.period_12_months',
  };

  int get monthCount => switch (this) {
    StatsPeriod.threeMonths => 3,
    StatsPeriod.sixMonths => 6,
    StatsPeriod.twelveMonths => 12,
  };
}

/// Notifier for selected time period for statistics charts.
/// Persists the selection to SharedPreferences.
class StatsPeriodNotifier extends Notifier<StatsPeriod> {
  @override
  StatsPeriod build() {
    // Returns default immediately; async _loadFromPrefs() may update state
    // later, causing a brief double-computation in downstream providers
    // between the initial default and the persisted value.
    _loadFromPrefs();
    return StatsPeriod.sixMonths;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppPreferences.keyStatsPeriod);
    if (saved != null) {
      final period = StatsPeriod.values.where((p) => p.name == saved);
      // Guard against setting state after the Notifier has been disposed
      // (e.g. user navigated away from statistics before prefs loaded).
      if (period.isNotEmpty && ref.mounted) state = period.first;
    }
  }

  Future<void> setPeriod(StatsPeriod period) async {
    state = period;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppPreferences.keyStatsPeriod, period.name);
  }
}

/// Selected time period for statistics charts.
final statsPeriodProvider = NotifierProvider<StatsPeriodNotifier, StatsPeriod>(
  StatsPeriodNotifier.new,
);

/// Optional species filter for statistics views. `null` means all species.
/// Persists the selection to SharedPreferences.
class StatsSpeciesFilterNotifier extends Notifier<Species?> {
  bool _loaded = false;

  bool get isLoaded => _loaded;

  @override
  Species? build() {
    _loaded = false;
    _loadFromPrefs();
    return null;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppPreferences.keyStatsSpeciesFilter);
    if (!ref.mounted) return;
    _loaded = true;
    if (saved != null) {
      final match = Species.values.where((s) => s.name == saved);
      if (match.isNotEmpty) {
        state = match.first;
        return;
      }
    }
    // Trigger rebuild so isLoaded becomes true even when value stays null.
    ref.notifyListeners();
  }

  Future<void> setSpecies(Species? species) async {
    state = species;
    final prefs = await SharedPreferences.getInstance();
    if (species != null) {
      await prefs.setString(
        AppPreferences.keyStatsSpeciesFilter,
        species.name,
      );
    } else {
      await prefs.remove(AppPreferences.keyStatsSpeciesFilter);
    }
  }
}

final statsSpeciesFilterProvider =
    NotifierProvider<StatsSpeciesFilterNotifier, Species?>(
      StatsSpeciesFilterNotifier.new,
    );

/// Month-aligned date windows used by statistics providers.
///
/// Example for 3 months in March:
/// - current: [Jan 1, Apr 1)
/// - previous: [Oct 1, Jan 1)
class StatsDateRange {
  const StatsDateRange({
    required this.currentStart,
    required this.currentEnd,
    required this.previousStart,
    required this.previousEnd,
  });

  final DateTime currentStart;
  final DateTime currentEnd;
  final DateTime previousStart;
  final DateTime previousEnd;

  bool isInCurrent(DateTime value) =>
      !value.isBefore(currentStart) && value.isBefore(currentEnd);

  bool isInPrevious(DateTime value) =>
      !value.isBefore(previousStart) && value.isBefore(previousEnd);
}

/// Builds month-aligned current and previous period date ranges.
StatsDateRange buildStatsDateRange(StatsPeriod period, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final currentMonthStart = DateTime(reference.year, reference.month);
  final currentStart = DateTime(
    currentMonthStart.year,
    currentMonthStart.month - (period.monthCount - 1),
  );
  final currentEnd = DateTime(
    currentMonthStart.year,
    currentMonthStart.month + 1,
  );
  final previousEnd = currentStart;
  final previousStart = DateTime(
    previousEnd.year,
    previousEnd.month - period.monthCount,
  );

  return StatsDateRange(
    currentStart: currentStart,
    currentEnd: currentEnd,
    previousStart: previousStart,
    previousEnd: previousEnd,
  );
}

/// Builds an empty month map for the selected period.
/// Accepts a [reference] date to stay consistent with [buildStatsDateRange].
Map<String, int> _buildEmptyMonthMap(int monthCount, {DateTime? reference}) {
  final now = reference ?? DateTime.now();
  final months = <String, int>{};
  for (var i = monthCount - 1; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i);
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    months[key] = 0;
  }
  return months;
}

/// Gender distribution statistics from bird data.
final genderDistributionProvider =
    Provider.family<AsyncValue<BirdStatistics>, String>((ref, userId) {
      final birdsAsync = ref.watch(birdsStreamProvider(userId));

      return birdsAsync.whenData((birds) {
        final male = birds.where((b) => b.gender == BirdGender.male).length;
        final female = birds.where((b) => b.gender == BirdGender.female).length;
        final unknown = birds
            .where((b) => b.gender == BirdGender.unknown)
            .length;
        final alive = birds.where((b) => b.status == BirdStatus.alive).length;
        final dead = birds.where((b) => b.status == BirdStatus.dead).length;
        final sold = birds.where((b) => b.status == BirdStatus.sold).length;

        return BirdStatistics(
          total: birds.length,
          male: male,
          female: female,
          unknown: unknown,
          alive: alive,
          dead: dead,
          sold: sold,
        );
      });
    });

/// Species distribution statistics from bird data.
final speciesDistributionProvider =
    Provider.family<AsyncValue<Map<Species, int>>, String>((ref, userId) {
      final birdsAsync = ref.watch(birdsStreamProvider(userId));

      return birdsAsync.whenData((birds) {
        final counts = <Species, int>{};
        for (final bird in birds) {
          counts[bird.species] = (counts[bird.species] ?? 0) + 1;
        }

        final entries = counts.entries.toList()
          ..sort((a, b) {
            final countCompare = b.value.compareTo(a.value);
            if (countCompare != 0) return countCompare;
            return a.key.name.compareTo(b.key.name);
          });

        return Map<Species, int>.fromEntries(entries);
      });
    });

/// Monthly egg production data — period-aware.
final monthlyEggProductionProvider =
    Provider.family<AsyncValue<Map<String, int>>, String>((ref, userId) {
      final eggsAsync = ref.watch(eggsStreamProvider(userId));
      final incubationsAsync = ref.watch(incubationsStreamProvider(userId));
      final period = ref.watch(statsPeriodProvider);
      final speciesFilter = ref.watch(statsSpeciesFilterProvider);

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
        final months = _buildEmptyMonthMap(
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

/// Monthly hatched chicks data — period-aware.
final monthlyHatchedChicksProvider =
    Provider.family<AsyncValue<Map<String, int>>, String>((ref, userId) {
      final chicksAsync = ref.watch(chicksStreamProvider(userId));
      final period = ref.watch(statsPeriodProvider);

      return chicksAsync.whenData((chicks) {
        final range = buildStatsDateRange(period);
        final months = _buildEmptyMonthMap(
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

/// Monthly breeding outcomes — period-aware.
final monthlyBreedingOutcomesProvider =
    Provider.family<AsyncValue<MonthlyBreedingData>, String>((ref, userId) {
      final pairsAsync = ref.watch(breedingPairsStreamProvider(userId));
      final incubationsAsync = ref.watch(incubationsStreamProvider(userId));
      final period = ref.watch(statsPeriodProvider);
      final speciesFilter = ref.watch(statsSpeciesFilterProvider);

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
        final completedMap = _buildEmptyMonthMap(
          period.monthCount,
          reference: range.currentEnd,
        );
        final cancelledMap = _buildEmptyMonthMap(
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

/// Data class holding monthly breeding outcome maps.
class MonthlyBreedingData {
  const MonthlyBreedingData({required this.completed, required this.cancelled});

  final Map<String, int> completed;
  final Map<String, int> cancelled;
}
