import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';

/// Period options for statistics date range filtering.
enum StatsPeriod {
  threeMonths,
  sixMonths,
  twelveMonths;

  String get label => switch (this) {
    StatsPeriod.threeMonths => 'statistics.period_3_months'.tr(),
    StatsPeriod.sixMonths => 'statistics.period_6_months'.tr(),
    StatsPeriod.twelveMonths => 'statistics.period_12_months'.tr(),
  };

  int get monthCount => switch (this) {
    StatsPeriod.threeMonths => 3,
    StatsPeriod.sixMonths => 6,
    StatsPeriod.twelveMonths => 12,
  };
}

/// Notifier for selected time period for statistics charts.
class StatsPeriodNotifier extends Notifier<StatsPeriod> {
  @override
  StatsPeriod build() => StatsPeriod.sixMonths;
}

/// Selected time period for statistics charts.
final statsPeriodProvider = NotifierProvider<StatsPeriodNotifier, StatsPeriod>(
  StatsPeriodNotifier.new,
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
Map<String, int> _buildEmptyMonthMap(int monthCount) {
  final now = DateTime.now();
  final months = <String, int>{};
  for (var i = monthCount - 1; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i);
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    months[key] = 0;
  }
  return months;
}

/// Breeding success statistics computed from breeding pair data.
final breedingStatsProvider =
    Provider.family<AsyncValue<BreedingStatistics>, String>((ref, userId) {
      final pairsAsync = ref.watch(breedingPairsStreamProvider(userId));

      return pairsAsync.whenData((pairs) {
        final active = pairs
            .where(
              (p) =>
                  p.status == BreedingStatus.active ||
                  p.status == BreedingStatus.ongoing,
            )
            .length;
        final completed = pairs
            .where((p) => p.status == BreedingStatus.completed)
            .length;
        final cancelled = pairs
            .where((p) => p.status == BreedingStatus.cancelled)
            .length;
        final total = completed + cancelled;
        final successRate = total > 0 ? completed / total : 0.0;

        return BreedingStatistics(
          active: active,
          completed: completed,
          successRate: successRate,
        );
      });
    });

/// Egg production statistics from egg data.
final eggStatsProvider = Provider.family<AsyncValue<EggStatistics>, String>((
  ref,
  userId,
) {
  final eggsAsync = ref.watch(eggsStreamProvider(userId));

  return eggsAsync.whenData((eggs) {
    final total = eggs.length;
    final incubating = eggs
        .where((e) => e.status == EggStatus.incubating)
        .length;
    final hatched = eggs.where((e) => e.status == EggStatus.hatched).length;
    final fertile = eggs
        .where(
          (e) => e.status == EggStatus.fertile || e.status == EggStatus.hatched,
        )
        .length;
    final infertile = eggs.where((e) => e.status == EggStatus.infertile).length;
    final checked = fertile + infertile;
    final fertilityRate = checked > 0 ? fertile / checked : 0.0;
    final hatchRate = fertile > 0 ? hatched / fertile : 0.0;

    return EggStatistics(
      total: total,
      incubating: incubating,
      hatched: hatched,
      fertile: fertile,
      infertile: infertile,
      hatchRate: hatchRate,
      fertilityRate: fertilityRate,
    );
  });
});

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

/// Monthly egg production data — period-aware.
final monthlyEggProductionProvider =
    Provider.family<AsyncValue<Map<String, int>>, String>((ref, userId) {
      final eggsAsync = ref.watch(eggsStreamProvider(userId));
      final period = ref.watch(statsPeriodProvider);

      return eggsAsync.whenData((eggs) {
        final months = _buildEmptyMonthMap(period.monthCount);

        for (final egg in eggs) {
          final key =
              '${egg.layDate.year}-${egg.layDate.month.toString().padLeft(2, '0')}';
          if (months.containsKey(key)) {
            months[key] = (months[key] ?? 0) + 1;
          }
        }

        return months;
      });
    });

/// Monthly hatched chicks data — period-aware.
final monthlyHatchedChicksProvider =
    Provider.family<AsyncValue<Map<String, int>>, String>((ref, userId) {
      final chicksAsync = ref.watch(chicksStreamProvider(userId));
      final period = ref.watch(statsPeriodProvider);

      return chicksAsync.whenData((chicks) {
        final months = _buildEmptyMonthMap(period.monthCount);

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
      final period = ref.watch(statsPeriodProvider);

      return pairsAsync.whenData((pairs) {
        final completedMap = _buildEmptyMonthMap(period.monthCount);
        final cancelledMap = _buildEmptyMonthMap(period.monthCount);

        for (final pair in pairs) {
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
      });
    });

/// Data class holding monthly breeding outcome maps.
class MonthlyBreedingData {
  const MonthlyBreedingData({required this.completed, required this.cancelled});

  final Map<String, int> completed;
  final Map<String, int> cancelled;
}
