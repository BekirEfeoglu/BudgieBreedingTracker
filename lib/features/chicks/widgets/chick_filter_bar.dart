import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/fade_scrollable_chip_bar.dart';
import 'package:budgie_breeding_tracker/shared/providers/chicks.dart';

/// Horizontal scrollable filter bar with choice chips for chicks.
class ChickFilterBar extends ConsumerWidget {
  const ChickFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(chickFilterProvider);

    return FadeScrollableChipBar(
      children: ChickFilter.values.map((filter) {
        final isSelected = selected == filter;
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: ChoiceChip(
            label: Text(filter.label),
            selected: isSelected,
            onSelected: (_) {
              ref.read(chickFilterProvider.notifier).state = filter;
            },
          ),
        );
      }).toList(),
    );
  }
}
