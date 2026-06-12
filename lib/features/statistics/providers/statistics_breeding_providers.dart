import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart'
    show Species;
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/date_utils.dart'
    as date_utils;
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';

/// All incubations for a user (live stream).
final incubationsStreamProvider =
    StreamProvider.family<List<Incubation>, String>((ref, userId) {
      final repo = ref.watch(incubationRepositoryProvider);
      return repo.watchAll(userId);
    });

/// Raw SQL-aggregated monthly fertility (fertile/total per month) — no
/// species filter. Statistics.md mandates SQL-side aggregation; this
/// replaces the Dart `for (final egg in ...)` walk in
/// `monthlyFertilityRateProvider` so memory stays O(monthCount).
final _monthlyFertilityAggregateProvider =
    StreamProvider.family<Map<String, ({int fertile, int total})>, String>((
      ref,
      userId,
    ) {
      return ref.watch(eggsDaoProvider).watchMonthlyFertility(userId);
    });

/// Species-filtered SQL-aggregated monthly fertility. Composite family key
/// `(userId, species)` so different species filters don't clobber each
/// other's stream subscription.
final _monthlyFertilityAggregateBySpeciesProvider =
    StreamProvider.family<
      Map<String, ({int fertile, int total})>,
      ({String userId, Species species})
    >((ref, args) {
      return ref
          .watch(eggsDaoProvider)
          .watchMonthlyFertility(args.userId, species: args.species.toJson());
    });

/// Monthly fertility rate — period-aware.
/// Calculates fertile / (fertile + infertile) per month.
///
/// Backed by SQL aggregation (`eggsDaoProvider.watchMonthlyFertility`)
/// instead of the previous Dart-side loop over the full eggs list.
/// statistics.md anti-pattern #1: aggregation must run in Drift.
final monthlyFertilityRateProvider =
    Provider.family<AsyncValue<Map<String, double>>, String>((ref, userId) {
      final period = ref.watch(statsPeriodProvider);
      final speciesFilter = ref.watch(statsSpeciesFilterProvider).species;

      final aggregateAsync = speciesFilter == null
          ? ref.watch(_monthlyFertilityAggregateProvider(userId))
          : ref.watch(
              _monthlyFertilityAggregateBySpeciesProvider((
                userId: userId,
                species: speciesFilter,
              )),
            );

      return aggregateAsync.whenData((rawCounts) {
        final range = buildStatsDateRange(period);
        final monthKeys = buildEmptyMonthMap(
          period.monthCount,
          reference: range.currentEnd,
        );
        final result = <String, double>{};
        for (final key in monthKeys.keys) {
          result[key] = 0.0;
        }
        for (final entry in rawCounts.entries) {
          if (!result.containsKey(entry.key)) continue;
          final total = entry.value.total;
          final fertile = entry.value.fertile;
          result[entry.key] = total > 0 ? (fertile / total) * 100 : 0.0;
        }
        return result;
      });
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
          final days = date_utils.DateUtils.dayDiff(i.startDate!, i.endDate!);
          return IncubationDurationData(
            id: i.id,
            actualDays: days,
            expectedDays: i.totalIncubationDays(),
          );
        }).toList();
      });
    });
