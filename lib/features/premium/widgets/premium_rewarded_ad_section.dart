import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_reward_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/widgets/rewarded_ad_button.dart';

/// Section offering temporary feature access via rewarded ads.
class PremiumRewardedAdSection extends ConsumerWidget {
  const PremiumRewardedAdSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsActive = ref.watch(isStatisticsRewardActiveProvider);
    final geneticsActive = ref.watch(isGeneticsRewardActiveProvider);
    final exportActive = ref.watch(isExportRewardActiveProvider);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.gift,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'ads.free_access_title'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'ads.free_access_subtitle'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (statsActive)
            RewardStatusChip(label: 'ads.reward_statistics_active'.tr())
          else
            RewardedAdButton(
              label: 'ads.watch_for_statistics'.tr(),
              subtitle: 'ads.reward_duration_24h'.tr(),
              onRewarded: () =>
                  ref.read(isStatisticsRewardActiveProvider.notifier).unlock(),
            ),
          const SizedBox(height: AppSpacing.md),
          if (geneticsActive)
            RewardStatusChip(label: 'ads.reward_genetics_remaining'.tr())
          else
            RewardedAdButton(
              label: 'ads.watch_for_genetics'.tr(),
              subtitle: 'ads.reward_duration_session'.tr(),
              onRewarded: () =>
                  ref.read(isGeneticsRewardActiveProvider.notifier).unlock(),
            ),
          const SizedBox(height: AppSpacing.md),
          if (exportActive)
            RewardStatusChip(label: 'ads.reward_export_remaining'.tr())
          else
            RewardedAdButton(
              label: 'ads.watch_for_export'.tr(),
              subtitle: 'ads.reward_duration_session'.tr(),
              onRewarded: () =>
                  ref.read(isExportRewardActiveProvider.notifier).unlock(),
            ),
        ],
      ),
    );
  }
}

/// Chip showing an active reward status.
class RewardStatusChip extends StatelessWidget {
  final String label;

  const RewardStatusChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.checkCircle2,
            size: 18,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
