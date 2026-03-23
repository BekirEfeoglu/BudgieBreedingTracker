import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/section_header.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

/// Section showing a summary of incubating eggs with days remaining.
class IncubationSummarySection extends StatelessWidget {
  final List<IncubatingEggSummary> eggs;

  const IncubationSummarySection({super.key, required this.eggs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'home.incubation_summary'.tr(),
            onViewAll: () => context.go(AppRoutes.breeding),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (eggs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'home.no_incubating'.tr(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...eggs.map((summary) => _IncubatingEggTile(summary: summary)),
        ],
      ),
    );
  }
}

class _IncubatingEggTile extends StatelessWidget {
  final IncubatingEggSummary summary;

  const _IncubatingEggTile({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = summary.daysRemaining < 0;
    final statusColor = isOverdue
        ? AppColors.stageOverdue
        : AppColors.stageOngoing;
    final daysText = isOverdue
        ? 'home.hatching_in'.tr(args: ['0'])
        : 'home.hatching_in'.tr(args: [summary.daysRemaining.toString()]);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: statusColor.withValues(alpha: 0.15),
              child: AppIcon(AppIcons.incubating, size: 18, color: statusColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'eggs.egg_label'.tr()} #${summary.egg.eggNumber ?? summary.egg.id.substring(0, 4)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    daysText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _ProgressIndicator(
              progress: summary.egg.progressPercent,
              color: statusColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final double progress;
  final Color color;

  const _ProgressIndicator({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '${(progress * 100).round()}%',
            // 9px needed to fit "100%" inside 36px circular indicator
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
