import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

/// Compact chip in AppBar showing current pedigree depth with a popup menu.
class DepthChip extends StatelessWidget {
  final int depth;
  final ValueChanged<int> onChanged;

  const DepthChip({super.key, required this.depth, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<int>(
      tooltip: 'genealogy.pedigree_depth'.tr(),
      offset: const Offset(0, 40),
      itemBuilder: (_) => List.generate(6, (i) {
        final value = i + 3; // 3-8
        return PopupMenuItem<int>(
          value: value,
          child: Row(
            children: [
              if (value == depth)
                Icon(
                  LucideIcons.check,
                  size: 16,
                  color: theme.colorScheme.primary,
                )
              else
                const SizedBox(width: AppSpacing.lg),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'genealogy.generations'.tr(args: [value.toString()]),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        );
      }),
      onSelected: onChanged,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Chip(
          avatar: const Icon(LucideIcons.layers, size: 16),
          label: Text('$depth', style: theme.textTheme.labelMedium),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
