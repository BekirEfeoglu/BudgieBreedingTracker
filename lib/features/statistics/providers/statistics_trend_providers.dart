import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/data/providers/bird_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/entity_count_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';

part 'statistics_trend_insights.dart';

/// Raw SQL-aggregated egg/chick period stats (statistics.md SQL aggregation
/// requirement) — reused by trendStatsProvider (current+previous) and
/// quickInsightsProvider (current only). Birds/pairs stay Dart-side: those
/// lists are naturally bounded per user (unlike eggs/chicks, which grow
/// unbounded over years).
final _periodEggStatsStreamProvider =
    StreamProvider.family<
      ({int total, int fertile, int infertile}),
      ({String userId, DateTime from, DateTime to})
    >((ref, args) {
      return ref
          .watch(eggsDaoProvider)
          .watchPeriodEggStats(args.userId, args.from, args.to);
    });

final _periodChickStatsStreamProvider =
    StreamProvider.family<
      ({int total, int deceased}),
      ({String userId, DateTime from, DateTime to})
    >((ref, args) {
      return ref
          .watch(chicksDaoProvider)
          .watchPeriodChickStats(args.userId, args.from, args.to);
    });

/// Computes trend percentages by comparing current period vs previous period.
final trendStatsProvider = Provider.family<AsyncValue<TrendStats>, String>((
  ref,
  userId,
) {
  final period = ref.watch(statsPeriodProvider);
  final range = buildStatsDateRange(period);

  final birdsAsync = ref.watch(birdsStreamProvider(userId));
  final pairsAsync = ref.watch(breedingPairsStreamProvider(userId));
  final currentEggAsync = ref.watch(
    _periodEggStatsStreamProvider((
      userId: userId,
      from: range.currentStart,
      to: range.currentEnd,
    )),
  );
  final previousEggAsync = ref.watch(
    _periodEggStatsStreamProvider((
      userId: userId,
      from: range.previousStart,
      to: range.previousEnd,
    )),
  );
  final currentChickAsync = ref.watch(
    _periodChickStatsStreamProvider((
      userId: userId,
      from: range.currentStart,
      to: range.currentEnd,
    )),
  );
  final previousChickAsync = ref.watch(
    _periodChickStatsStreamProvider((
      userId: userId,
      from: range.previousStart,
      to: range.previousEnd,
    )),
  );

  // Fast-fail on any error
  for (final a in [
    birdsAsync,
    pairsAsync,
    currentEggAsync,
    previousEggAsync,
    currentChickAsync,
    previousChickAsync,
  ]) {
    if (a.hasError) {
      return AsyncError(a.error!, a.stackTrace ?? StackTrace.empty);
    }
  }
  // Loading if any stream hasn't resolved
  if (birdsAsync.isLoading ||
      pairsAsync.isLoading ||
      currentEggAsync.isLoading ||
      previousEggAsync.isLoading ||
      currentChickAsync.isLoading ||
      previousChickAsync.isLoading) {
    return const AsyncLoading();
  }

  final birds = birdsAsync.requireValue;
  final pairs = pairsAsync.requireValue;

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

  final currentEgg = currentEggAsync.requireValue;
  final previousEgg = previousEggAsync.requireValue;
  final currentChecked = currentEgg.fertile + currentEgg.infertile;
  final currentFertilityRate = currentChecked > 0
      ? currentEgg.fertile / currentChecked
      : 0.0;
  final prevChecked = previousEgg.fertile + previousEgg.infertile;
  final prevFertilityRate = prevChecked > 0
      ? previousEgg.fertile / prevChecked
      : 0.0;

  final currentChick = currentChickAsync.requireValue;
  final previousChick = previousChickAsync.requireValue;
  final currentSurvival = currentChick.total > 0
      ? (currentChick.total - currentChick.deceased) / currentChick.total
      : 0.0;
  final prevSurvival = previousChick.total > 0
      ? (previousChick.total - previousChick.deceased) / previousChick.total
      : 0.0;

  return AsyncData(
    TrendStats(
      birdsTrend: _calcTrend(currentBirds, previousBirds),
      breedingsTrend: _calcTrend(currentBreedings, previousBreedings),
      eggsTrend: _calcTrend(currentEgg.total, previousEgg.total),
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
