import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/data/providers/chick_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';

/// Chick survival statistics.
final chickSurvivalProvider =
    Provider.family<AsyncValue<ChickSurvivalData>, String>((ref, userId) {
      final chicksAsync = ref.watch(chicksStreamProvider(userId));

      return chicksAsync.whenData((chicks) {
        final total = chicks.length;
        if (total == 0) {
          return const ChickSurvivalData();
        }

        final healthy = chicks
            .where((c) => c.healthStatus == ChickHealthStatus.healthy)
            .length;
        final sick = chicks
            .where((c) => c.healthStatus == ChickHealthStatus.sick)
            .length;
        final deceased = chicks
            .where((c) => c.healthStatus == ChickHealthStatus.deceased)
            .length;
        final survivalRate = total > 0 ? (total - deceased) / total : 0.0;

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
