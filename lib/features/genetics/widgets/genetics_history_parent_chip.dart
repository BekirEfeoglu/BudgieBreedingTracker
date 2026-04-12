import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

/// Compact chip showing parent mutations in genetics history cards.
class GeneticsHistoryParentChip extends StatelessWidget {
  final String label;
  final List<String> mutations;
  final Color color;
  final Widget icon;

  const GeneticsHistoryParentChip({
    super.key,
    required this.label,
    required this.mutations,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  mutations.isEmpty
                      ? 'genetics.mutation_normal'.tr()
                      : mutations.join(', '),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
