import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/cards/stat_card.dart';
import 'package:budgie_breeding_tracker/core/widgets/progress_bar.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/animations/slide_fade_animation.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

/// 2x2 grid + 1 full-width card showing key dashboard statistics.
class DashboardStatsGrid extends ConsumerWidget {
  final DashboardStats stats;

  const DashboardStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // effectivePremiumProvider includes grace-period subscribers so they
    // see unlimited counts (consistent with /more's premium tile gating).
    final isPremium = ref.watch(effectivePremiumProvider);

    final birdValue = isPremium
        ? '${stats.totalBirds}'
        : '${stats.totalBirds}/${AppConstants.freeTierMaxBirds}';
    final breedingValue = isPremium
        ? '${stats.activeBreedings}'
        : '${stats.activeBreedings}/${AppConstants.freeTierMaxBreedingPairs}';

    // Defensive division: if a constants typo set the max to 0 we'd get
    // NaN/Infinity, propagating into _ratioColor and the progress bar.
    final birdRatio = AppConstants.freeTierMaxBirds > 0
        ? stats.totalBirds / AppConstants.freeTierMaxBirds
        : 0.0;
    final breedingRatio = AppConstants.freeTierMaxBreedingPairs > 0
        ? stats.activeBreedings / AppConstants.freeTierMaxBreedingPairs
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Row 1: Toplam Kuş + Aktif Üreme
          SlideFadeAnimation(
            delay: const Duration(milliseconds: 100),
            child: _StatsRow(
              left: StatCard(
                label: 'home.total_birds'.tr(),
                value: birdValue,
                icon: const AppIcon(AppIcons.bird),
                color: isPremium
                    ? Theme.of(context).colorScheme.primary
                    : _ratioColor(birdRatio),
                onTap: () => context.push(AppRoutes.birds),
              ),
              right: StatCard(
                label: 'home.active_breedings'.tr(),
                value: breedingValue,
                icon: const AppIcon(AppIcons.breedingActive),
                color: isPremium
                    ? AppColors.stageOngoing
                    : _ratioColor(breedingRatio),
                onTap: () => context.push(AppRoutes.breeding),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Row 2: Toplam Yavru + Toplam Yumurta
          SlideFadeAnimation(
            delay: const Duration(milliseconds: 200),
            child: _StatsRow(
              left: StatCard(
                label: 'home.total_chicks'.tr(),
                value: '${stats.totalChicks}',
                icon: const AppIcon(AppIcons.chick),
                color: AppColors.budgieGreen,
                onTap: () => context.push(AppRoutes.chicks),
              ),
              right: StatCard(
                label: 'home.total_eggs'.tr(),
                value: '${stats.totalEggs}',
                icon: const AppIcon(AppIcons.egg),
                color: AppColors.stageNearHatch,
                onTap: () => context.push(AppRoutes.breeding),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Row 3: Kuluçkadaki Yumurta — tam genişlik, yatay layout
          SlideFadeAnimation(
            delay: const Duration(milliseconds: 300),
            child: SizedBox(
              height: 86,
              child: StatCard(
                label: 'home.incubating_eggs'.tr(),
                value: '${stats.incubatingEggs}',
                icon: const AppIcon(AppIcons.incubating),
                color: AppColors.stageOngoing,
                onTap: () => context.push(AppRoutes.breeding),
                isHorizontal: true,
              ),
            ),
          ),
          // Free tier usage progress bar
          if (!isPremium) ...[
            const SizedBox(height: AppSpacing.md),
            SlideFadeAnimation(
              delay: const Duration(milliseconds: 400),
              child: AppProgressBar(
                value: birdRatio.clamp(0.0, 1.0),
                color: _ratioColor(birdRatio),
                label: 'premium.usage_birds'.tr(
                  args: [
                    '${stats.totalBirds}',
                    '${AppConstants.freeTierMaxBirds}',
                  ],
                ),
                showPercentage: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _ratioColor(double ratio) {
    if (ratio >= AppConstants.freeTierCriticalRatio) return AppColors.error;
    if (ratio >= AppConstants.freeTierWarningRatio) return AppColors.warning;
    return AppColors.budgieGreen;
  }
}

class _StatsRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _StatsRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: right),
        ],
      ),
    );
  }
}
