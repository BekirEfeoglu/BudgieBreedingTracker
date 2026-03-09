import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';

/// Computes trend percentages by comparing current period vs previous period.
final trendStatsProvider =
    Provider.family<AsyncValue<TrendStats>, String>((ref, userId) {
  final period = ref.watch(statsPeriodProvider);
  final birdsAsync = ref.watch(birdsStreamProvider(userId));
  final pairsAsync = ref.watch(breedingPairsStreamProvider(userId));
  final eggsAsync = ref.watch(eggsStreamProvider(userId));
  final chicksAsync = ref.watch(chicksStreamProvider(userId));

  return birdsAsync.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (birds) => pairsAsync.when(
      loading: () => const AsyncLoading(),
      error: (e, st) => AsyncError(e, st),
      data: (pairs) => eggsAsync.when(
        loading: () => const AsyncLoading(),
        error: (e, st) => AsyncError(e, st),
        data: (eggs) => chicksAsync.when(
          loading: () => const AsyncLoading(),
          error: (e, st) => AsyncError(e, st),
          data: (chicks) {
            final now = DateTime.now();
            final monthCount = period.monthCount;
            final currentStart = DateTime(
              now.year,
              now.month - monthCount,
              now.day,
            );
            final previousStart = DateTime(
              now.year,
              now.month - monthCount * 2,
              now.day,
            );

            // Birds created in current vs previous period
            final currentBirds = birds
                .where((b) =>
                    b.createdAt != null &&
                    b.createdAt!.isAfter(currentStart))
                .length;
            final previousBirds = birds
                .where((b) =>
                    b.createdAt != null &&
                    b.createdAt!.isAfter(previousStart) &&
                    b.createdAt!.isBefore(currentStart))
                .length;

            // Active breedings in current vs previous
            final currentBreedings = pairs
                .where((p) =>
                    (p.status == BreedingStatus.active ||
                        p.status == BreedingStatus.ongoing) &&
                    p.pairingDate != null &&
                    p.pairingDate!.isAfter(currentStart))
                .length;
            final previousBreedings = pairs
                .where((p) =>
                    (p.status == BreedingStatus.active ||
                        p.status == BreedingStatus.ongoing ||
                        p.status == BreedingStatus.completed) &&
                    p.pairingDate != null &&
                    p.pairingDate!.isAfter(previousStart) &&
                    p.pairingDate!.isBefore(currentStart))
                .length;

            // Eggs in current vs previous period
            final currentEggs = eggs
                .where((e) => e.layDate.isAfter(currentStart))
                .length;
            final previousEggs = eggs
                .where((e) =>
                    e.layDate.isAfter(previousStart) &&
                    e.layDate.isBefore(currentStart))
                .length;

            // Fertility rate in current vs previous
            final currentFertile = eggs
                .where((e) =>
                    e.layDate.isAfter(currentStart) &&
                    (e.status == EggStatus.fertile ||
                        e.status == EggStatus.hatched))
                .length;
            final currentInfertile = eggs
                .where((e) =>
                    e.layDate.isAfter(currentStart) &&
                    e.status == EggStatus.infertile)
                .length;
            final currentChecked = currentFertile + currentInfertile;
            final currentFertilityRate =
                currentChecked > 0 ? currentFertile / currentChecked : 0.0;

            final prevFertile = eggs
                .where((e) =>
                    e.layDate.isAfter(previousStart) &&
                    e.layDate.isBefore(currentStart) &&
                    (e.status == EggStatus.fertile ||
                        e.status == EggStatus.hatched))
                .length;
            final prevInfertile = eggs
                .where((e) =>
                    e.layDate.isAfter(previousStart) &&
                    e.layDate.isBefore(currentStart) &&
                    e.status == EggStatus.infertile)
                .length;
            final prevChecked = prevFertile + prevInfertile;
            final prevFertilityRate =
                prevChecked > 0 ? prevFertile / prevChecked : 0.0;

            // Survival rate in current vs previous
            final currentChicks = chicks
                .where((c) =>
                    c.hatchDate != null &&
                    c.hatchDate!.isAfter(currentStart))
                .toList();
            final currentDeceased = currentChicks
                .where(
                    (c) => c.healthStatus == ChickHealthStatus.deceased)
                .length;
            final currentSurvival = currentChicks.isNotEmpty
                ? (currentChicks.length - currentDeceased) /
                    currentChicks.length
                : 0.0;

            final prevChicks = chicks
                .where((c) =>
                    c.hatchDate != null &&
                    c.hatchDate!.isAfter(previousStart) &&
                    c.hatchDate!.isBefore(currentStart))
                .toList();
            final prevDeceased = prevChicks
                .where(
                    (c) => c.healthStatus == ChickHealthStatus.deceased)
                .length;
            final prevSurvival = prevChicks.isNotEmpty
                ? (prevChicks.length - prevDeceased) / prevChicks.length
                : 0.0;

            return AsyncData(TrendStats(
              birdsTrend: _calcTrend(currentBirds, previousBirds),
              breedingsTrend:
                  _calcTrend(currentBreedings, previousBreedings),
              eggsTrend: _calcTrend(currentEggs, previousEggs),
              fertilityTrend:
                  (currentFertilityRate - prevFertilityRate) * 100,
              survivalTrend: (currentSurvival - prevSurvival) * 100,
            ));
          },
        ),
      ),
    ),
  );
});

/// Calculates trend percentage: (current - previous) / previous * 100.
/// Returns 0 if no data in previous period.
double _calcTrend(int current, int previous) {
  if (previous == 0) {
    return current > 0 ? 100.0 : 0.0;
  }
  return ((current - previous) / previous) * 100;
}

/// Produces 3-4 human-readable insights about the current period.
final quickInsightsProvider =
    Provider.family<AsyncValue<List<QuickInsight>>, String>((ref, userId) {
  final period = ref.watch(statsPeriodProvider);
  final eggsAsync = ref.watch(eggsStreamProvider(userId));
  final chicksAsync = ref.watch(chicksStreamProvider(userId));
  final pairsAsync = ref.watch(breedingPairsStreamProvider(userId));
  final trendAsync = ref.watch(trendStatsProvider(userId));

  return eggsAsync.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (eggs) => chicksAsync.when(
      loading: () => const AsyncLoading(),
      error: (e, st) => AsyncError(e, st),
      data: (chicks) => pairsAsync.when(
        loading: () => const AsyncLoading(),
        error: (e, st) => AsyncError(e, st),
        data: (pairs) {
          final now = DateTime.now();
          final cutoff = DateTime(
            now.year,
            now.month - period.monthCount,
            now.day,
          );

          final insights = <QuickInsight>[];
          final trends = trendAsync.value;

          // Egg production insight
          final periodEggs =
              eggs.where((e) => e.layDate.isAfter(cutoff)).length;
          if (periodEggs > 0) {
            final trendText = trends != null && trends.eggsTrend.abs() > 0
                ? ' (${trends.eggsTrend > 0 ? "+" : ""}${trends.eggsTrend.toStringAsFixed(0)}%)'
                : '';
            insights.add(QuickInsight(
              text: 'statistics.insight_egg_production'
                  .tr(args: ['$periodEggs$trendText']),
              sentiment: trends != null && trends.eggsTrend >= 0
                  ? InsightSentiment.positive
                  : InsightSentiment.negative,
            ));
          }

          // Fertility rate insight
          final fertile = eggs
              .where((e) =>
                  e.layDate.isAfter(cutoff) &&
                  (e.status == EggStatus.fertile ||
                      e.status == EggStatus.hatched))
              .length;
          final infertile = eggs
              .where((e) =>
                  e.layDate.isAfter(cutoff) &&
                  e.status == EggStatus.infertile)
              .length;
          final checked = fertile + infertile;
          if (checked > 0) {
            final rate = (fertile / checked * 100).toStringAsFixed(0);
            insights.add(QuickInsight(
              text: 'statistics.insight_fertility'.tr(args: [rate]),
              sentiment: (fertile / checked) >= 0.5
                  ? InsightSentiment.positive
                  : InsightSentiment.negative,
            ));
          }

          // Chick survival insight
          final periodChicks = chicks
              .where((c) =>
                  c.hatchDate != null && c.hatchDate!.isAfter(cutoff))
              .toList();
          final survivedChicks = periodChicks
              .where(
                  (c) => c.healthStatus != ChickHealthStatus.deceased)
              .length;
          if (periodChicks.isNotEmpty) {
            insights.add(QuickInsight(
              text: 'statistics.insight_chick_survival'
                  .tr(args: ['$survivedChicks']),
              sentiment: survivedChicks >= periodChicks.length * 0.7
                  ? InsightSentiment.positive
                  : InsightSentiment.negative,
            ));
          }

          // Active breeding insight
          final activeBreedings = pairs
              .where((p) =>
                  p.status == BreedingStatus.active ||
                  p.status == BreedingStatus.ongoing)
              .length;
          if (activeBreedings > 0) {
            insights.add(QuickInsight(
              text: 'statistics.insight_breeding_active'
                  .tr(args: ['$activeBreedings']),
              sentiment: InsightSentiment.neutral,
            ));
          }

          // No data fallback
          if (insights.isEmpty) {
            insights.add(QuickInsight(
              text: 'statistics.insight_no_data'.tr(),
              sentiment: InsightSentiment.neutral,
            ));
          }

          return AsyncData(insights);
        },
      ),
    ),
  );
});
