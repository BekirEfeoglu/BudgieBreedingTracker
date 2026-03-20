import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';

import 'egg_status_chip.dart';

/// A list tile displaying an egg's number, status, dates, and actions.
class EggListItem extends StatelessWidget {
  final Egg egg;
  final VoidCallback? onTap;
  final VoidCallback? onStatusUpdate;
  final VoidCallback? onDelete;

  const EggListItem({
    super.key,
    required this.egg,
    this.onTap,
    this.onStatusUpdate,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');

    final statusColor = _getStatusColor(egg.status);

    return Semantics(
      label: '${'eggs.egg_label'.tr()} ${egg.eggNumber ?? '?'}',
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                // Egg number badge with status-colored egg icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AppIcon(
                        _getStatusIcon(egg.status),
                        size: 28,
                        color: statusColor.withValues(alpha: 0.25),
                      ),
                      Text(
                        '${egg.eggNumber ?? '?'}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${'eggs.egg_label'.tr()} #${egg.eggNumber ?? '?'}',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          EggStatusChip(status: egg.status),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${'eggs.lay_label'.tr()}: ${dateFormat.format(egg.layDate)}'
                        '  •  ${'eggs.days_count'.tr(namedArgs: {'count': '${egg.incubationDays}'})}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                if (onStatusUpdate != null)
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeftRight, size: 20),
                    tooltip: 'eggs.update_status'.tr(),
                    onPressed: onStatusUpdate,
                    visualDensity: VisualDensity.compact,
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: AppIcon(
                      AppIcons.delete,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    tooltip: 'common.delete'.tr(),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _getStatusIcon(EggStatus status) {
    return switch (status) {
      EggStatus.infertile => AppIcons.infertile,
      EggStatus.damaged => AppIcons.damaged,
      _ => AppIcons.egg,
    };
  }

  static Color _getStatusColor(EggStatus status) {
    return switch (status) {
      EggStatus.laid => AppColors.stageNew,
      EggStatus.fertile => AppColors.success,
      EggStatus.infertile => AppColors.neutral400,
      EggStatus.incubating => AppColors.stageOngoing,
      EggStatus.hatched => AppColors.stageCompleted,
      EggStatus.damaged => AppColors.error,
      EggStatus.discarded => AppColors.neutral500,
      EggStatus.empty => AppColors.neutral300,
      EggStatus.unknown => AppColors.neutral300,
    };
  }
}
