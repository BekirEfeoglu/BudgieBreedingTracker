import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

class LimitApproachingBanner extends ConsumerWidget {
  final String userId;

  const LimitApproachingBanner({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium) return const SizedBox.shrink();

    final birdCountAsync = ref.watch(birdCountProvider(userId));
    final birdCount = birdCountAsync.value ?? 0;
    final ratio = birdCount / AppConstants.freeTierMaxBirds;

    if (ratio < 0.66) return const SizedBox.shrink();

    final remaining = AppConstants.freeTierMaxBirds - birdCount;
    final bannerColor = ratio >= 0.93 ? AppColors.error : AppColors.warning;

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
          Icon(LucideIcons.info, color: bannerColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'premium.limit_approaching'.tr(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: bannerColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'premium.limit_approaching_birds'.tr(args: ['$remaining']),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.premium),
            child: Text(
              'premium.try_free_trial'.tr(),
              style: TextStyle(color: bannerColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
