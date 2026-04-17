import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/providers/premium_shared_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/profile_stream_providers.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

class GracePeriodBanner extends ConsumerWidget {
  const GracePeriodBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(premiumGracePeriodProvider);
    if (status != GracePeriodStatus.gracePeriod) {
      return const SizedBox.shrink();
    }

    // IMPROVED: use .select() to only rebuild when grace period dates change
    final gracePeriodEnd = ref.watch(
      userProfileProvider.select((async) {
        final p = async.value;
        return p?.gracePeriodUntil ??
            p?.premiumExpiresAt?.add(
              const Duration(days: AppConstants.gracePeriodDays),
            );
      }),
    );
    final daysRemaining = gracePeriodEnd != null
        ? gracePeriodEnd.difference(DateTime.now()).inDays
        : 0;
    final theme = Theme.of(context);
    const bannerColor = AppColors.warning;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle, color: bannerColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'premium.grace_period_title'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: bannerColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'premium.grace_period_message'.tr(args: ['$daysRemaining']),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.premium),
            child: Text(
              'premium.grace_period_renew'.tr(),
              style: const TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
