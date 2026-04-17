import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/data/providers/bird_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/chick_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_breeding_providers.dart';

part 'statistics_chart_providers.dart';

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
/// Uses a record to track loading state alongside the selected species.
class StatsSpeciesFilterNotifier extends Notifier<({Species? species, bool loaded})> {
  @override
  ({Species? species, bool loaded}) build() {
    _loadFromPrefs();
    return (species: null, loaded: false);
  }

  bool get isLoaded => state.loaded;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppPreferences.keyStatsSpeciesFilter);
    if (!ref.mounted) return;
    // If user already made a selection while prefs were loading, don't override.
    if (state.loaded) return;
    if (saved != null) {
      final match = Species.values.where((s) => s.name == saved);
      if (match.isNotEmpty) {
        state = (species: match.first, loaded: true);
        return;
      }
    }
    state = (species: null, loaded: true);
  }

  Future<void> setSpecies(Species? species) async {
    state = (species: species, loaded: true);
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
    NotifierProvider<StatsSpeciesFilterNotifier, ({Species? species, bool loaded})>(
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
/// [reference] is treated as an exclusive upper bound (first day of next month),
/// so the last included month is `reference.month - 1`.
Map<String, int> buildEmptyMonthMap(int monthCount, {DateTime? reference}) {
  final ref = reference ?? DateTime.now();
  // When reference is an exclusive end boundary (first day of next month),
  // subtract 1 month to get the last included month.
  final lastIncludedMonth = DateTime(ref.year, ref.month - 1);
  final months = <String, int>{};
  for (var i = monthCount - 1; i >= 0; i--) {
    final month = DateTime(lastIncludedMonth.year, lastIncludedMonth.month - i);
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    months[key] = 0;
  }
  return months;
}

/// Gender distribution via SQL aggregate (no full-list materialisation).
final _genderDistStreamProvider =
    StreamProvider.family<Map<BirdGender, int>, String>((ref, userId) {
      return ref.watch(birdsDaoProvider).watchGenderDistribution(userId);
    });

/// Status distribution via SQL aggregate (no full-list materialisation).
final _statusDistStreamProvider =
    StreamProvider.family<Map<BirdStatus, int>, String>((ref, userId) {
      return ref.watch(birdsDaoProvider).watchStatusDistribution(userId);
    });

/// Gender + status distribution statistics from SQL aggregates.
final genderDistributionProvider =
    Provider.family<AsyncValue<BirdStatistics>, String>((ref, userId) {
      final genderAsync = ref.watch(_genderDistStreamProvider(userId));
      final statusAsync = ref.watch(_statusDistStreamProvider(userId));

      if (genderAsync.hasError) {
        return AsyncError(
          genderAsync.error!,
          genderAsync.stackTrace ?? StackTrace.empty,
        );
      }
      if (statusAsync.hasError) {
        return AsyncError(
          statusAsync.error!,
          statusAsync.stackTrace ?? StackTrace.empty,
        );
      }
      if (genderAsync.isLoading || statusAsync.isLoading) {
        return const AsyncLoading();
      }

      final genderMap = genderAsync.requireValue;
      final statusMap = statusAsync.requireValue;

      final male = genderMap[BirdGender.male] ?? 0;
      final female = genderMap[BirdGender.female] ?? 0;
      final unknown = genderMap[BirdGender.unknown] ?? 0;
      final total = genderMap.values.fold<int>(0, (a, b) => a + b);

      return AsyncData(BirdStatistics(
        total: total,
        male: male,
        female: female,
        unknown: unknown,
        alive: statusMap[BirdStatus.alive] ?? 0,
        dead: statusMap[BirdStatus.dead] ?? 0,
        sold: statusMap[BirdStatus.sold] ?? 0,
      ));
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

