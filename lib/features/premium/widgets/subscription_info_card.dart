import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_service.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';

/// Displays active subscription details for premium users.
/// Shows plan type, expiration date, renewal status, and a
/// gradient premium badge header.
class SubscriptionInfoCard extends StatelessWidget {
  final SubscriptionInfo subscriptionInfo;

  const SubscriptionInfoCard({super.key, required this.subscriptionInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.premiumGradientDiagonal,
            ),
            child: Builder(
              builder: (context) {
                final onGold = AppColors.premiumOnGold(context);
                return Row(
                  children: [
                    AppIcon(AppIcons.premium, size: 32, color: onGold),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscriptionInfo.isTrial
                                ? 'premium.trial_active_badge'.tr()
                                : 'premium.active_badge'.tr(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: onGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subscriptionInfo.isTrial
                                ? 'premium.trial_subtitle'.tr()
                                : 'premium.subscription_active_subtitle'.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: onGold.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.checkCircle2,
                      color: onGold.withValues(alpha: 0.9),
                      size: 28,
                    ),
                  ],
                );
              },
            ),
          ),

          // Info rows
          Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              children: [
                if (subscriptionInfo.productId != null)
                  _InfoRow(
                    icon: const Icon(LucideIcons.creditCard),
                    label: 'premium.current_plan'.tr(),
                    value: _resolvePlanName(subscriptionInfo.productId!),
                  ),
                if (subscriptionInfo.expirationDate != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _InfoRow(
                    icon: const Icon(LucideIcons.calendar),
                    label: 'premium.expires_at'.tr(),
                    value: _formatDate(subscriptionInfo.expirationDate!),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _InfoRow(
                  icon: const AppIcon(AppIcons.sync),
                  label: 'premium.will_renew'.tr(),
                  value: subscriptionInfo.willRenew
                      ? 'common.yes'.tr()
                      : 'common.no'.tr(),
                  valueColor: subscriptionInfo.willRenew
                      ? AppColors.success
                      : AppColors.neutral500,
                ),
                if (subscriptionInfo.expirationDate != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _InfoRow(
                    icon: const Icon(LucideIcons.clock),
                    label: 'premium.remaining_days'.tr(),
                    value: _remainingDays(subscriptionInfo.expirationDate!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resolvePlanName(String productId) {
    return switch (PremiumPlan.fromProductId(productId)) {
      PremiumPlan.semiAnnual => 'premium.plan_semi_annual'.tr(),
      PremiumPlan.yearly => 'premium.plan_yearly'.tr(),
      null => productId,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _remainingDays(DateTime expirationDate) {
    final remaining = expirationDate.difference(DateTime.now()).inDays;
    if (remaining <= 0) return 'premium.expired'.tr();
    return 'premium.days_remaining'.tr(args: [remaining.toString()]);
  }
}

class _InfoRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconTheme(
          data: IconThemeData(
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          child: icon,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
