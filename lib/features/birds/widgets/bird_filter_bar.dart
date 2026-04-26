import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/fade_scrollable_chip_bar.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';

/// Responsive filter bar with choice chips for birds.
class BirdFilterBar extends ConsumerWidget {
  const BirdFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(birdFilterProvider);
    final chips = BirdFilter.values.map((filter) {
      final isSelected = selected == filter;
      return ChoiceChip(
        label: Text(filter.label),
        selected: isSelected,
        visualDensity: VisualDensity.compact,
        onSelected: (_) {
          ref.read(birdFilterProvider.notifier).state = filter;
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
