import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';

/// Summary statistics combining COUNT providers and filtered streams.
/// Uses SQL COUNT for totalBirds, activeBreedings, totalHealthRecords
/// to avoid loading full entity lists. Keeps eggs/chicks streams for
/// ratio calculations that require per-record status filtering.
final summaryStatsProvider = Provider.family<AsyncValue<SummaryStats>, String>((
  ref,
  userId,
) {
  final birdCount = ref.watch(birdCountProvider(userId));
  final activeBreedingCount = ref.watch(activeBreedingCountProvider(userId));
  final eggsAsync = ref.watch(eggsStreamProvider(userId));
  final chicksAsync = ref.watch(chicksStreamProvider(userId));
  final healthCount = ref.watch(healthRecordCountProvider(userId));

  // Fast-fail on any error
  for (final a in [birdCount, activeBreedingCount, healthCount, eggsAsync, chicksAsync]) {
    if (a.hasError) return AsyncError(a.error!, a.stackTrace ?? StackTrace.empty);
  }

  // Loading if any provider hasn't resolved
  if (birdCount.isLoading ||
      activeBreedingCount.isLoading ||
      healthCount.isLoading ||
      eggsAsync.isLoading ||
      chicksAsync.isLoading) {
    return const AsyncLoading();
  }

  final eggs = eggsAsync.requireValue;
  final chicks = chicksAsync.requireValue;

  final incubatingEggs =
      eggs.where((e) => e.status == EggStatus.incubating).length;

  final fertile = eggs
      .where(
        (e) => e.status == EggStatus.fertile || e.status == EggStatus.hatched,
      )
      .length;
  final infertile =
      eggs.where((e) => e.status == EggStatus.infertile).length;
  final checked = fertile + infertile;
  // fertilityRate is a 0.0-1.0 ratio (not a percentage).
  // UI widgets multiply by 100 for display where needed.
  final fertilityRate = checked > 0 ? fertile / checked : 0.0;

  final totalChicks = chicks.length;
  final deceased = chicks
      .where((c) => c.healthStatus == ChickHealthStatus.deceased)
      .length;
  // chickSurvivalRate is a 0.0-1.0 ratio (not a percentage).
  // UI widgets multiply by 100 for display where needed.
  final survivalRate =
      totalChicks > 0 ? (totalChicks - deceased) / totalChicks : 0.0;

  return AsyncData(
    SummaryStats(
      totalBirds: birdCount.value ?? 0,
      activeBreedings: activeBreedingCount.value ?? 0,
      incubatingEggs: incubatingEggs,
      fertilityRate: fertilityRate,
      chickSurvivalRate: survivalRate,
      totalHealthRecords: healthCount.value ?? 0,
    ),
  );
});

/// Color mutation distribution from bird data.
final colorMutationDistributionProvider =
    Provider.family<AsyncValue<Map<BirdColor, int>>, String>((ref, userId) {
      final birdsAsync = ref.watch(birdsStreamProvider(userId));

      return birdsAsync.whenData((birds) {
        final counts = <BirdColor, int>{};
        for (final bird in birds) {
          final color = bird.colorMutation;
          if (color == null) continue;
          counts[color] = (counts[color] ?? 0) + 1;
        }
        return counts;
      });
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
        final groups = <String, int>{
          for (final key in ageBracketKeys) key: 0,
        };

        for (final bird in birds) {
          final birth = bird.birthDate;
          if (birth == null) continue;

          final months =
              (now.year - birth.year) * 12 + (now.month - birth.month);

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
