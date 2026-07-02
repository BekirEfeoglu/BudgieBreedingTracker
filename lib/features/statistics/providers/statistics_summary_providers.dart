import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/utils/date_utils.dart'
    as date_utils;
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/data/providers/bird_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/entity_count_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/health_record_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';

/// Raw SQL-aggregated all-time fertile/infertile egg counts (statistics.md
/// SQL aggregation requirement).
final _fertilityCountStreamProvider =
    StreamProvider.family<({int fertile, int infertile}), String>((
      ref,
      userId,
    ) {
      return ref.watch(eggsDaoProvider).watchFertilityCount(userId);
    });

/// Summary statistics combining SQL COUNT/aggregate providers.
/// Uses SQL COUNT/GROUP BY for totalBirds, activeBreedings,
/// totalHealthRecords, incubatingEggs, fertility, and chick survival —
/// avoids loading full entity lists into Dart.
final summaryStatsProvider = Provider.family<AsyncValue<SummaryStats>, String>((
  ref,
  userId,
) {
  final birdCount = ref.watch(birdCountProvider(userId));
  final activeBreedingCount = ref.watch(activeBreedingCountProvider(userId));
  final incubatingEggCount = ref.watch(incubatingEggCountProvider(userId));
  final fertilityCountAsync = ref.watch(_fertilityCountStreamProvider(userId));
  final chickCountsAsync = ref.watch(chickHealthCountsProvider(userId));
  final healthCount = ref.watch(healthRecordCountProvider(userId));

  // Fast-fail on any error
  for (final a in [
    birdCount,
    activeBreedingCount,
    incubatingEggCount,
    healthCount,
    fertilityCountAsync,
    chickCountsAsync,
  ]) {
    if (a.hasError) {
      return AsyncError(a.error!, a.stackTrace ?? StackTrace.empty);
    }
  }

  // Loading if any provider hasn't resolved
  if (birdCount.isLoading ||
      activeBreedingCount.isLoading ||
      incubatingEggCount.isLoading ||
      healthCount.isLoading ||
      fertilityCountAsync.isLoading ||
      chickCountsAsync.isLoading) {
    return const AsyncLoading();
  }

  final fertilityCount = fertilityCountAsync.requireValue;
  final chickCounts = chickCountsAsync.requireValue;

  final checked = fertilityCount.fertile + fertilityCount.infertile;
  // fertilityRate is a 0.0-1.0 ratio (not a percentage).
  // UI widgets multiply by 100 for display where needed.
  final fertilityRate = checked > 0 ? fertilityCount.fertile / checked : 0.0;

  final totalChicks = chickCounts.values.fold(0, (sum, c) => sum + c);
  final deceased = chickCounts[ChickHealthStatus.deceased.name] ?? 0;
  // chickSurvivalRate is a 0.0-1.0 ratio (not a percentage).
  // UI widgets multiply by 100 for display where needed.
  final survivalRate = totalChicks > 0
      ? (totalChicks - deceased) / totalChicks
      : 0.0;

  return AsyncData(
    SummaryStats(
      totalBirds: birdCount.value ?? 0,
      activeBreedings: activeBreedingCount.value ?? 0,
      incubatingEggs: incubatingEggCount.value ?? 0,
      fertilityRate: fertilityRate,
      chickSurvivalRate: survivalRate,
      totalHealthRecords: healthCount.value ?? 0,
    ),
  );
});

/// Raw SQL-aggregated color-mutation counts (statistics.md SQL aggregation
/// requirement).
final _colorMutationDistStreamProvider =
    StreamProvider.family<Map<BirdColor, int>, String>((ref, userId) {
      return ref
          .watch(birdsDaoProvider)
          .watchColorMutationDistribution(userId);
    });

/// Color mutation distribution from bird data.
final colorMutationDistributionProvider =
    Provider.family<AsyncValue<Map<BirdColor, int>>, String>((ref, userId) {
      return ref.watch(_colorMutationDistStreamProvider(userId));
    });

/// Canonical age bracket keys shared with [AgeDistributionChart].
const ageBracketKeys = ['0-6m', '6-12m', '1-2y', '2-3y', '3+y'];

/// Age distribution from bird data.
/// Groups birds into 5 age brackets based on birthDate.
final ageDistributionProvider =
    Provider.family<AsyncValue<Map<String, int>>, String>((ref, userId) {
      final birdsAsync = ref.watch(birdsStreamProvider(userId));

      return birdsAsync.whenData((birds) {
        final now = DateTime.now();
        final groups = <String, int>{for (final key in ageBracketKeys) key: 0};

        for (final bird in birds) {
          final birth = bird.birthDate;
          if (birth == null) continue;
          // Skip future-dated births (data-entry typo or expected hatch
          // date entered prematurely). Without this, negative months
          // would satisfy `months < 6` and inflate the 0-6m bracket.
          if (birth.isAfter(now)) continue;

          // Use day-precise difference rather than year/month subtraction
          // alone — a bird born 2026-01-31 viewed on 2026-02-01 should
          // count as 0 months old, not 1.
          final days = date_utils.DateUtils.dayDiff(birth, now);
          final months = days ~/ 30;

          if (months < 6) {
            groups[ageBracketKeys[0]] = (groups[ageBracketKeys[0]] ?? 0) + 1;
          } else if (months < 12) {
            groups[ageBracketKeys[1]] = (groups[ageBracketKeys[1]] ?? 0) + 1;
          } else if (months < 24) {
            groups[ageBracketKeys[2]] = (groups[ageBracketKeys[2]] ?? 0) + 1;
          } else if (months < 36) {
            groups[ageBracketKeys[3]] = (groups[ageBracketKeys[3]] ?? 0) + 1;
          } else {
            groups[ageBracketKeys[4]] = (groups[ageBracketKeys[4]] ?? 0) + 1;
          }
        }

        return groups;
      });
    });
