import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';

/// Chick survival statistics.
final chickSurvivalProvider =
    Provider.family<AsyncValue<ChickSurvivalData>, String>(
  (ref, userId) {
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
      final survivalRate =
          total > 0 ? (total - deceased) / total : 0.0;

      return ChickSurvivalData(
        healthy: healthy,
        sick: sick,
        deceased: deceased,
        survivalRate: survivalRate,
      );
    });
  },
);

/// Health record type distribution — period-aware.
final healthRecordTypeDistributionProvider =
    Provider.family<AsyncValue<Map<HealthRecordType, int>>, String>(
  (ref, userId) {
    final healthAsync =
        ref.watch(healthRecordsStreamProvider(userId));
    final period = ref.watch(statsPeriodProvider);

    return healthAsync.whenData((records) {
      final now = DateTime.now();
      final cutoff = DateTime(
        now.year,
        now.month - period.monthCount,
        now.day,
      );

      final filtered =
          records.where((r) => r.date.isAfter(cutoff)).toList();

      final counts = <HealthRecordType, int>{};
      for (final record in filtered) {
        counts[record.type] = (counts[record.type] ?? 0) + 1;
      }

      return counts;
    });
  },
);
