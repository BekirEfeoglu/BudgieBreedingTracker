import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

/// A small colored chip displaying the egg status.
class EggStatusChip extends StatelessWidget {
  final EggStatus status;

  const EggStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, label) = _getStatusInfo(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static (Color, String) _getStatusInfo(EggStatus status) {
    return switch (status) {
      EggStatus.laid => (AppColors.stageNew, 'eggs.status_laid'.tr()),
      EggStatus.fertile => (AppColors.success, 'eggs.status_fertile'.tr()),
      EggStatus.infertile => (
        AppColors.neutral400,
        'eggs.status_infertile'.tr(),
      ),
      EggStatus.incubating => (
        AppColors.stageOngoing,
        'eggs.status_incubating'.tr(),
      ),
      EggStatus.hatched => (
        AppColors.stageCompleted,
        'eggs.status_hatched'.tr(),
      ),
      EggStatus.damaged => (AppColors.error, 'eggs.status_damaged'.tr()),
      EggStatus.discarded => (
        AppColors.neutral500,
        'eggs.status_discarded'.tr(),
      ),
      EggStatus.empty => (AppColors.neutral300, 'eggs.status_empty'.tr()),
      EggStatus.unknown => (AppColors.neutral300, 'eggs.status_unknown'.tr()),
    };
  }
}
