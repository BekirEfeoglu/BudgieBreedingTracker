import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_milestone.dart';

/// Vertical timeline displaying incubation milestones.
class MilestoneTimeline extends StatelessWidget {
  final List<IncubationMilestone> milestones;

  const MilestoneTimeline({super.key, required this.milestones});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < milestones.length; i++) ...[
          _buildMilestoneItem(context, theme, dateFormat, milestones[i],
              isLast: i == milestones.length - 1),
        ],
      ],
    );
  }

  Widget _buildMilestoneItem(
    BuildContext context,
    ThemeData theme,
    DateFormat dateFormat,
    IncubationMilestone milestone, {
    required bool isLast,
  }) {
    final dotColor = milestone.isPassed ? AppColors.success : AppColors.neutral300;
    final lineColor = milestone.isPassed
        ? AppColors.success.withValues(alpha: 0.3)
        : AppColors.neutral200;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: milestone.isPassed
                        ? null
                        : Border.all(color: AppColors.neutral300, width: 2),
                  ),
                  child: milestone.isPassed
                      ? Icon(LucideIcons.check, size: 10, color: Theme.of(context).colorScheme.onPrimary)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: lineColor),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Content column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        milestone.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: milestone.isPassed
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${'breeding.day_label'.tr(args: [milestone.day.toString()])} ${dateFormat.format(milestone.date)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    milestone.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
