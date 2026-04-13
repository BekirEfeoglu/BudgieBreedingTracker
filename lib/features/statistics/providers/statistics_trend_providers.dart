import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/data/providers/bird_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/chick_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/egg_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';

part 'statistics_trend_insights.dart';

/// Computes trend percentages by comparing current period vs previous period.
final trendStatsProvider = Provider.family<AsyncValue<TrendStats>, String>((
  ref,
  userId,
) {
  final period = ref.watch(statsPeriodProvider);
  final birdsAsync = ref.watch(birdsStreamProvider(userId));
  final pairsAsync = ref.watch(breedingPairsStreamProvider(userId));
  final eggsAsync = ref.watch(eggsStreamProvider(userId));
  final chicksAsync = ref.watch(chicksStreamProvider(userId));

  // Fast-fail on any error
  for (final a in [birdsAsync, pairsAsync, eggsAsync, chicksAsync]) {
    if (a.hasError) return AsyncError(a.error!, a.stackTrace ?? StackTrace.empty);
  }
  // Loading if any stream hasn't resolved
  if (birdsAsync.isLoading ||
      pairsAsync.isLoading ||
      eggsAsync.isLoading ||
      chicksAsync.isLoading) {
    return const AsyncLoading();
  }

  final birds = birdsAsync.requireValue;
  final pairs = pairsAsync.requireValue;
  final eggs = eggsAsync.requireValue;
  final chicks = chicksAsync.requireValue;
  final range = buildStatsDateRange(period);

  // Birds created in current vs previous period
  final currentBirds = birds
      .where((b) => b.createdAt != null && range.isInCurrent(b.createdAt!))
      .length;
  final previousBirds = birds
      .where((b) => b.createdAt != null && range.isInPrevious(b.createdAt!))
      .length;

  // Active breedings in current vs previous
  final currentBreedings = pairs
      .where(
        (p) =>
            (p.status == BreedingStatus.active ||
                p.status == BreedingStatus.ongoing) &&
            p.pairingDate != null &&
            range.isInCurrent(p.pairingDate!),
      )
      .length;
  final previousBreedings = pairs
      .where(
        (p) =>
            (p.status == BreedingStatus.active ||
                p.status == BreedingStatus.ongoing) &&
            p.pairingDate != null &&
            range.isInPrevious(p.pairingDate!),
      )
      .length;

  // Eggs in current vs previous period
  final currentEggs =
      eggs.where((e) => range.isInCurrent(e.layDate)).length;
  final previousEggs =
      eggs.where((e) => range.isInPrevious(e.layDate)).length;

  // Fertility rate in current vs previous
  final currentFertile = eggs
      .where(
        (e) =>
            range.isInCurrent(e.layDate) &&
            (e.status == EggStatus.fertile || e.status == EggStatus.hatched),
      )
      .length;
  final currentInfertile = eggs
      .where(
        (e) =>
            range.isInCurrent(e.layDate) && e.status == EggStatus.infertile,
      )
      .length;
  final currentChecked = currentFertile + currentInfertile;
  final currentFertilityRate =
      currentChecked > 0 ? currentFertile / currentChecked : 0.0;

  final prevFertile = eggs
      .where(
        (e) =>
            range.isInPrevious(e.layDate) &&
            (e.status == EggStatus.fertile || e.status == EggStatus.hatched),
      )
      .length;
  final prevInfertile = eggs
      .where(
        (e) =>
            range.isInPrevious(e.layDate) && e.status == EggStatus.infertile,
      )
      .length;
  final prevChecked = prevFertile + prevInfertile;
  final prevFertilityRate =
      prevChecked > 0 ? prevFertile / prevChecked : 0.0;

  // Survival rate in current vs previous
  final currentChicks = chicks
      .where((c) => c.hatchDate != null && range.isInCurrent(c.hatchDate!))
      .toList();
  final currentDeceased = currentChicks
      .where((c) => c.healthStatus == ChickHealthStatus.deceased)
      .length;
  final currentSurvival = currentChicks.isNotEmpty
      ? (currentChicks.length - currentDeceased) / currentChicks.length
      : 0.0;

  final prevChicks = chicks
      .where((c) => c.hatchDate != null && range.isInPrevious(c.hatchDate!))
      .toList();
  final prevDeceased = prevChicks
      .where((c) => c.healthStatus == ChickHealthStatus.deceased)
      .length;
  final prevSurvival = prevChicks.isNotEmpty
      ? (prevChicks.length - prevDeceased) / prevChicks.length
      : 0.0;

  return AsyncData(
    TrendStats(
      birdsTrend: _calcTrend(currentBirds, previousBirds),
      breedingsTrend: _calcTrend(currentBreedings, previousBreedings),
      eggsTrend: _calcTrend(currentEggs, previousEggs),
      fertilityTrend: (currentFertilityRate - prevFertilityRate) * 100,
      survivalTrend: (currentSurvival - prevSurvival) * 100,
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

