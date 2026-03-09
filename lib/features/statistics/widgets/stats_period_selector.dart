import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';

/// Period options for statistics date range filtering.
enum StatsPeriod {
  threeMonths,
  sixMonths,
  twelveMonths;

  String get label => switch (this) {
        StatsPeriod.threeMonths => 'statistics.period_3_months'.tr(),
        StatsPeriod.sixMonths => 'statistics.period_6_months'.tr(),
        StatsPeriod.twelveMonths => 'statistics.period_12_months'.tr(),
      };

  int get monthCount => switch (this) {
        StatsPeriod.threeMonths => 3,
        StatsPeriod.sixMonths => 6,
        StatsPeriod.twelveMonths => 12,
      };
}

/// Segmented button for selecting the statistics time period.
class StatsPeriodSelector extends ConsumerWidget {
  const StatsPeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(statsPeriodProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: SegmentedButton<StatsPeriod>(
        segments: StatsPeriod.values
            .map((p) => ButtonSegment(
                  value: p,
                  label: Text(p.label),
                ))
            .toList(),
        selected: {period},
        onSelectionChanged: (selected) {
          ref.read(statsPeriodProvider.notifier).state = selected.first;
        },
      ),
    );
  }
}
