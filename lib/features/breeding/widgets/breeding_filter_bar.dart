import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';

/// Wrapping filter bar with choice chips.
class BreedingFilterBar extends ConsumerWidget {
  const BreedingFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(breedingFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: BreedingFilter.values.map((filter) {
          final isSelected = selected == filter;
          return ChoiceChip(
            label: Text(filter.label),
            selected: isSelected,
            onSelected: (_) {
              ref.read(breedingFilterProvider.notifier).state = filter;
            },
          );
        }).toList(),
      ),
    );
  }
}
