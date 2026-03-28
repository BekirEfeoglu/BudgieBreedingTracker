import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';

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
            .map((p) => ButtonSegment(value: p, label: Text(p.label)))
            .toList(),
        selected: {period},
        onSelectionChanged: (selected) {
          ref.read(statsPeriodProvider.notifier).setPeriod(selected.first);
        },
      ),
    );
  }
}
