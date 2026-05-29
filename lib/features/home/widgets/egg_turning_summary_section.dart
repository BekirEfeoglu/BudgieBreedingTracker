import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/section_header.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

class EggTurningSummarySection extends StatelessWidget {
  final TodaysEggTurningSummary summary;

  const EggTurningSummarySection({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'home.egg_turning_today'.tr(),
            icon: const AppIcon(AppIcons.egg),
            onViewAll: () => context.push(AppRoutes.breeding),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: summary.hasEggs
                  ? Row(
                      children: [
                        _IconBubble(
                          color: AppColors.warning,
                          semanticLabel: 'home.egg_turning_today'.tr(),
                          icon: const Icon(LucideIcons.rotateCw, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          summary.count.toString(),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'home.egg_turning_count'.tr(
                                  args: [summary.count.toString()],
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                summary.nextTurningAt == null
                                    ? 'home.egg_turning_done_today'.tr()
                                    : 'home.next_egg_turning'.tr(
                                        args: [
                                          _formatTime(summary.nextTurningAt!),
                                        ],
                                      ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (summary.nextTurningAt != null)
                          Text(
                            _formatTime(summary.nextTurningAt!),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                      ],
                    )
                  : Row(
                      children: [
                        _IconBubble(
                          color: AppColors.success,
                          semanticLabel: 'home.no_egg_turning_today'.tr(),
                          icon: const Icon(LucideIcons.checkCircle2, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'home.no_egg_turning_today'.tr(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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

class _IconBubble extends StatelessWidget {
  final Color color;
  final Widget icon;
  final String semanticLabel;

  const _IconBubble({
    required this.color,
    required this.icon,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    // The status glyph conveys meaning ("eggs to turn" vs "all done"); expose
    // it to screen readers since color/icon alone is not accessible.
    return Semantics(
      label: semanticLabel,
      child: CircleAvatar(
        radius: 18,
        backgroundColor: color.withValues(alpha: 0.15),
        child: IconTheme(
          data: IconThemeData(color: color),
          child: icon,
        ),
      ),
    );
  }
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
