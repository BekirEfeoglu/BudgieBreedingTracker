import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/extensions/context_extensions.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_service.dart';
import 'package:budgie_breeding_tracker/features/premium/widgets/rewarded_ad_button.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_reward_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/widgets/feature_comparison.dart';
import 'package:budgie_breeding_tracker/features/premium/widgets/premium_paywall_sections.dart';
import 'package:budgie_breeding_tracker/features/premium/widgets/subscription_info_card.dart';

/// Paywall screen showing premium features and pricing plans.
/// When the user is already premium, shows subscription info instead.
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    // Listen for purchase action side effects
    ref.listen<PurchaseActionState>(purchaseActionProvider, (_, state) {
      if (state.isSuccess) {
        ref.read(purchaseActionProvider.notifier).reset();
        context.showSnackBar('premium.purchase_success'.tr(), isSuccess: true);
      }
      if (state.error != null) {
        final errorMsg = switch (state.error!) {
          PurchaseErrorCodes.cancelled => 'premium.purchase_cancelled'.tr(),
          PurchaseErrorCodes.restoreNoPurchases =>
            'premium.restore_no_purchases'.tr(),
          PurchaseErrorCodes.packageNotFound =>
            'premium.package_not_found'.tr(),
          PurchaseErrorCodes.noOfferings => 'premium.no_offerings'.tr(),
          PurchaseErrorCodes.pending => 'premium.purchase_pending'.tr(),
          PurchaseErrorCodes.alreadyOwned =>
            'premium.purchase_already_owned'.tr(),
          PurchaseErrorCodes.storeProblem =>
            'premium.purchase_store_problem'.tr(),
          PurchaseErrorCodes.notAllowed => 'premium.purchase_not_allowed'.tr(),
          PurchaseErrorCodes.productUnavailable =>
            'premium.purchase_product_unavailable'.tr(),
          PurchaseErrorCodes.networkError =>
            'premium.purchase_network_error'.tr(),
          PurchaseErrorCodes.inProgress => 'premium.purchase_in_progress'.tr(),
          PurchaseErrorCodes.configurationError =>
            'premium.purchase_configuration_error'.tr(),
          PurchaseErrorCodes.notActivated =>
            'premium.purchase_not_activated'.tr(),
          PurchaseErrorCodes.restoreFailed => 'premium.purchase_error'.tr(),
          _ => 'premium.purchase_error'.tr(),
        };
        context.showSnackBar(errorMsg, isError: true);
        ref.read(purchaseActionProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text('premium.title'.tr())),
      body: isPremium ? _ActivePremiumBody() : const _PaywallBody(),
    );
  }
}

/// Body displayed when user is already premium.
class _ActivePremiumBody extends ConsumerWidget {
  void _openSubscriptionManagement() {
    final url = Platform.isIOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subscriptionInfoAsync = ref.watch(subscriptionInfoProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl * 2),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxl),

          // Premium active header
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: AppColors.premiumGradientDiagonal,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.premiumGold.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: AppIcon(
              AppIcons.premium,
              size: 48,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'premium.already_premium'.tr(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'premium.already_premium_subtitle'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Subscription info card
          Padding(
            padding: AppSpacing.screenPadding,
            child: subscriptionInfoAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Card(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.checkCircle2,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'premium.active_badge'.tr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              data: (info) => SubscriptionInfoCard(subscriptionInfo: info),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Manage subscription button
          Padding(
            padding: AppSpacing.screenPadding,
            child: OutlinedButton.icon(
              onPressed: () => _openSubscriptionManagement(),
              icon: const Icon(LucideIcons.settings, size: 18),
              label: Text('premium.manage_subscription'.tr()),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  AppSpacing.touchTargetMin,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Unlocked features
          Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'premium.unlocked_features'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...premiumFeatures.map(
                  (key) => PremiumFeatureItem(featureKey: key),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Body displayed as paywall when user is not premium.
class _PaywallBody extends StatelessWidget {
  const _PaywallBody();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.only(bottom: AppSpacing.xxxl * 2),
      child: Column(
        children: [
          PremiumHeaderSection(),
          SizedBox(height: AppSpacing.xl),
          PremiumPricingSection(),
          SizedBox(height: AppSpacing.xxl),
          PremiumFeatureListSection(),
          SizedBox(height: AppSpacing.xxl),
          _RewardedAdSection(),
          SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: AppSpacing.screenPadding,
            child: FeatureComparison(),
          ),
          SizedBox(height: AppSpacing.xxl),
          PremiumRestoreSection(),
        ],
      ),
    );
  }
}

/// Section offering temporary feature access via rewarded ads.
class _RewardedAdSection extends ConsumerWidget {
  const _RewardedAdSection();

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
            _RewardStatusChip(label: 'ads.reward_statistics_active'.tr())
          else
            RewardedAdButton(
              label: 'ads.watch_for_statistics'.tr(),
              subtitle: 'ads.reward_duration_24h'.tr(),
              onRewarded: () =>
                  ref.read(isStatisticsRewardActiveProvider.notifier).unlock(),
            ),
          const SizedBox(height: AppSpacing.md),
          if (geneticsActive)
            _RewardStatusChip(label: 'ads.reward_genetics_remaining'.tr())
          else
            RewardedAdButton(
              label: 'ads.watch_for_genetics'.tr(),
              subtitle: 'ads.reward_duration_session'.tr(),
              onRewarded: () =>
                  ref.read(isGeneticsRewardActiveProvider.notifier).unlock(),
            ),
          const SizedBox(height: AppSpacing.md),
          if (exportActive)
            _RewardStatusChip(label: 'ads.reward_export_remaining'.tr())
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

class _RewardStatusChip extends StatelessWidget {
  final String label;

  const _RewardStatusChip({required this.label});

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
