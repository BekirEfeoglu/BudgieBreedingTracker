import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

/// Widget showing free vs pro feature comparison table
/// with check and X icons, alternating row backgrounds.
class FeatureComparison extends StatelessWidget {
  const FeatureComparison({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'premium.comparison_title'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildHeader(theme),
              for (int i = 0; i < _features.length; i++)
                _buildRow(theme, _features[i], isEven: i.isEven),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'premium.feature'.tr(),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'premium.free'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                'premium.pro'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    ThemeData theme,
    _FeatureRow feature, {
    required bool isEven,
  }) {
    return Container(
      color: isEven
          ? theme.colorScheme.surface
          : theme.colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(feature.name.tr(), style: theme.textTheme.bodyMedium),
          ),
          Expanded(child: _buildIcon(feature.inFree)),
          Expanded(child: _buildIcon(feature.inPro)),
        ],
      ),
    );
  }

  Widget _buildIcon(bool available) {
    if (available) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          LucideIcons.check,
          size: 14,
          color: AppColors.success,
        ),
      );
    }

    return const Icon(LucideIcons.minus, size: 18, color: AppColors.neutral400);
  }

  static const _features = [
    _FeatureRow('premium.feature_bird_tracking', true, true),
    _FeatureRow('premium.feature_breeding', true, true),
    _FeatureRow('premium.feature_basic_stats', true, true),
    _FeatureRow('premium.feature_genealogy', false, true),
    _FeatureRow('premium.feature_genetics', false, true),
    _FeatureRow('premium.feature_export', false, true),
    _FeatureRow('premium.feature_cloud_backup', false, true),
    _FeatureRow('premium.feature_unlimited_birds', false, true),
    _FeatureRow('premium.feature_advanced_stats', false, true),
    _FeatureRow('premium.feature_no_ads', false, true),
  ];
}

class _FeatureRow {
  final String name;
  final bool inFree;
  final bool inPro;

  const _FeatureRow(this.name, this.inFree, this.inPro);
}
