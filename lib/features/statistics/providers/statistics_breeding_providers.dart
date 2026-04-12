import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';

/// All incubations for a user (live stream).
final incubationsStreamProvider =
    StreamProvider.family<List<Incubation>, String>((ref, userId) {
      final repo = ref.watch(incubationRepositoryProvider);
      return repo.watchAll(userId);
    });

/// Monthly fertility rate — period-aware.
/// Calculates fertile / (fertile + infertile) per month.
final monthlyFertilityRateProvider =
    Provider.family<AsyncValue<Map<String, double>>, String>((ref, userId) {
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
        final monthKeys = buildEmptyMonthMap(
          period.monthCount,
          reference: range.currentEnd,
        );
        final fertileMap = <String, int>{};
        final totalMap = <String, int>{};
        final result = <String, double>{};

        for (final key in monthKeys.keys) {
          fertileMap[key] = 0;
          totalMap[key] = 0;
          result[key] = 0.0;
        }

        for (final egg in filteredEggs) {
          final key =
              '${egg.layDate.year}-${egg.layDate.month.toString().padLeft(2, '0')}';
          if (!totalMap.containsKey(key)) continue;

          if (egg.status == EggStatus.fertile ||
              egg.status == EggStatus.hatched) {
            fertileMap[key] = (fertileMap[key] ?? 0) + 1;
            totalMap[key] = (totalMap[key] ?? 0) + 1;
          } else if (egg.status == EggStatus.infertile) {
            totalMap[key] = (totalMap[key] ?? 0) + 1;
          }
        }

        for (final key in result.keys) {
          final total = totalMap[key] ?? 0;
          final fertile = fertileMap[key] ?? 0;
          result[key] = total > 0 ? (fertile / total) * 100 : 0.0;
        }

        return result;
      }());
    });

/// Incubation duration data for completed incubations.
/// Returns actual days vs species-aware expected days for the last 10 incubations.
final incubationDurationProvider =
    Provider.family<AsyncValue<List<IncubationDurationData>>, String>((
      ref,
      userId,
    ) {
      final incubationsAsync = ref.watch(incubationsStreamProvider(userId));
      final speciesFilter = ref.watch(statsSpeciesFilterProvider).species;

      return incubationsAsync.whenData((incubations) {
        final source = speciesFilter == null
            ? incubations
            : incubations
                  .where((incubation) => incubation.species == speciesFilter)
                  .toList();
        final completed =
            source
                .where(
                  (i) =>
                      i.status == IncubationStatus.completed &&
                      i.startDate != null &&
                      i.endDate != null,
                )
                .toList()
              ..sort(
                (a, b) => (b.endDate ?? DateTime(0)).compareTo(
                  a.endDate ?? DateTime(0),
                ),
              );

        final recent = completed.take(10).toList();

        return recent.map((i) {
          final days = i.endDate!.difference(i.startDate!).inDays;
          return IncubationDurationData(
            id: i.id,
            actualDays: days,
            expectedDays: i.totalIncubationDays(),
          );
        }).toList();
      });
    });
