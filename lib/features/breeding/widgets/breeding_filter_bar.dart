import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/fade_scrollable_chip_bar.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';

/// Horizontal scrollable filter bar with choice chips.
class BreedingFilterBar extends ConsumerWidget {
  const BreedingFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(breedingFilterProvider);

    return FadeScrollableChipBar(
      children: BreedingFilter.values.map((filter) {
        final isSelected = selected == filter;
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: ChoiceChip(
            label: Text(filter.label),
            selected: isSelected,
            onSelected: (_) {
              ref.read(breedingFilterProvider.notifier).state = filter;
            },
          ),
        );
      }).toList(),
    );
  }
}
