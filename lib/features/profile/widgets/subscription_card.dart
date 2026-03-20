import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/models/profile_model.dart';
import '../../../router/route_names.dart';

/// Standalone subscription card — upsell for free users, status for premium.
class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({super.key, required this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final isPremium = profile?.hasPremium == true;
    return isPremium
        ? _PremiumStatusCard(profile: profile!)
        : const _UpsellCard();
  }
}

// -- Premium Status Card --

class _PremiumStatusCard extends StatelessWidget {
  const _PremiumStatusCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expires = profile.premiumExpiresAt;
    final daysRemaining = expires?.difference(DateTime.now()).inDays;

    return Semantics(
      label: 'profile.subscription_active'.tr(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          color: AppColors.success.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const AppIcon(
                  AppIcons.premium,
                  size: 24,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'profile.subscription_active'.tr(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                      if (daysRemaining != null && daysRemaining > 0)
                        Text(
                          'profile.subscription_days_remaining'.tr(
                            args: ['$daysRemaining'],
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.checkCircle2,
                  size: 20,
                  color: AppColors.success,
                ),
              ],
            ),
            if (_memberTenure != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Divider(color: AppColors.success.withValues(alpha: 0.2)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${'profile.member_tenure'.tr()}: $_memberTenure',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.premium),
                child: Text('profile.subscription_manage'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? get _memberTenure {
    final created = profile.createdAt;
    if (created == null) return null;
    final diff = DateTime.now().difference(created);
    final months = (diff.inDays / 30).floor();
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (years > 0 && remainingMonths > 0) {
      return '${'profile.tenure_years'.tr(args: ['$years'])} '
          '${'profile.tenure_months'.tr(args: ['$remainingMonths'])}';
    }
    if (years > 0) return 'profile.tenure_years'.tr(args: ['$years']);
    if (months > 0) return 'profile.tenure_months'.tr(args: ['$months']);
    return 'profile.tenure_days'.tr(args: ['${diff.inDays}']);
  }
}

// -- Upsell Card --

class _UpsellCard extends StatelessWidget {
  const _UpsellCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'profile.premium_membership'.tr(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.accent.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppIcon(
                  AppIcons.premium,
                  size: 24,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'profile.premium_membership'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Benefits list
            _BenefitRow(label: 'profile.subscription_benefit_stats'.tr()),
            _BenefitRow(label: 'profile.subscription_benefit_genealogy'.tr()),
            _BenefitRow(label: 'profile.subscription_benefit_genetics'.tr()),
            const SizedBox(height: AppSpacing.lg),

            // CTA Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.premium),
                icon: const AppIcon(AppIcons.premium, size: 18),
                label: Text('profile.subscription_upgrade'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(LucideIcons.check, size: 16, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
