import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/fade_scrollable_chip_bar.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';

/// Horizontal scrollable filter bar with choice chips for health records.
class HealthRecordFilterBar extends ConsumerWidget {
  const HealthRecordFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(healthRecordFilterProvider);
    final chips = HealthRecordFilter.values.map((filter) {
      final isSelected = selected == filter;
      return ChoiceChip(
        label: Text(filter.label),
        selected: isSelected,
        visualDensity: VisualDensity.compact,
        onSelected: (_) {
          ref.read(healthRecordFilterProvider.notifier).state = filter;
        },
      );
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppSpacing.tabletBreakpoint) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: chips,
            ),
          );
        }

        return FadeScrollableChipBar(
          height: AppSpacing.touchTargetMin,
          children: chips
              .map(
                (chip) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: chip,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
