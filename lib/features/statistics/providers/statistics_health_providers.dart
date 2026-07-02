import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';

/// Chick survival statistics.
///
/// Backed by `ChicksDao.watchHealthStatusCounts` via the shared
/// `chickHealthCountsProvider` (statistics.md SQL aggregation requirement
/// — mirrors `healthRecordTypeDistributionProvider` below); previously this
/// provider pulled the full chick list via `chicksStreamProvider`
/// (including per-chick photo URL resolution) and counted
/// healthy/sick/deceased in Dart on every emission.
final chickSurvivalProvider =
    Provider.family<AsyncValue<ChickSurvivalData>, String>((ref, userId) {
      final countsAsync = ref.watch(chickHealthCountsProvider(userId));

      return countsAsync.whenData((counts) {
        final healthy = counts[ChickHealthStatus.healthy.name] ?? 0;
        final sick = counts[ChickHealthStatus.sick.name] ?? 0;
        final deceased = counts[ChickHealthStatus.deceased.name] ?? 0;
        // total is the raw map sum (every status, including `unknown`) —
        // matches the pre-SQL-migration `chicks.length` headcount and
        // `summaryStatsProvider`'s `_summaryChickCountsStreamProvider`.
        // An unknown-status chick has no slice of its own in the 3-category
        // pie chart, but it must still count toward the denominator, or the
        // summary card and this health tab show two different survival
        // rates for the same underlying data.
        final total = counts.values.fold(0, (sum, c) => sum + c);
        if (total == 0) {
          return const ChickSurvivalData();
        }

        final survivalRate = (total - deceased) / total;

        return ChickSurvivalData(
          healthy: healthy,
          sick: sick,
          deceased: deceased,
          survivalRate: survivalRate,
        );
      });
    });

/// Raw SQL-aggregated health-record counts (key = enum name).
final _healthCountsByTypeProvider =
    StreamProvider.family<
      Map<String, int>,
      ({String userId, DateTime from, DateTime to})
    >((ref, args) {
      return ref
          .watch(healthRecordsDaoProvider)
          .watchCountsByTypeInRange(
            userId: args.userId,
            from: args.from,
            to: args.to,
          );
    });

/// Health record type distribution — period-aware.
///
/// Backed by `HealthRecordsDao.watchCountsByTypeInRange` (statistics.md
/// SQL aggregation requirement); previously the provider pulled the full
/// records list and filtered/counted in Dart on every emission.
final healthRecordTypeDistributionProvider =
    Provider.family<AsyncValue<Map<HealthRecordType, int>>, String>((
      ref,
      userId,
    ) {
      final period = ref.watch(statsPeriodProvider);
      final range = buildStatsDateRange(period);
      final countsAsync = ref.watch(
        _healthCountsByTypeProvider((
          userId: userId,
          from: range.currentStart,
          to: range.currentEnd,
        )),
      );

      return countsAsync.whenData((raw) {
        final counts = <HealthRecordType, int>{};
        for (final entry in raw.entries) {
          counts[HealthRecordType.fromJson(entry.key)] = entry.value;
        }
        return counts;
      });
    });
