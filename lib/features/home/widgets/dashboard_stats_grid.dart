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
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

/// 2x2 grid + 1 full-width card showing key dashboard statistics.
class DashboardStatsGrid extends ConsumerWidget {
  final DashboardStats stats;

  const DashboardStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    final birdValue = isPremium
        ? '${stats.totalBirds}'
        : '${stats.totalBirds}/${AppConstants.freeTierMaxBirds}';
    final breedingValue = isPremium
        ? '${stats.activeBreedings}'
        : '${stats.activeBreedings}/${AppConstants.freeTierMaxBreedingPairs}';

    final birdRatio = stats.totalBirds / AppConstants.freeTierMaxBirds;
    final breedingRatio =
        stats.activeBreedings / AppConstants.freeTierMaxBreedingPairs;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Row 1: Toplam Kuş + Aktif Üreme
          _StatsRow(
            children: [
              StatCard(
                label: 'home.total_birds'.tr(),
                value: birdValue,
                icon: const AppIcon(AppIcons.bird),
                color: isPremium
                    ? Theme.of(context).colorScheme.primary
                    : _ratioColor(birdRatio),
                onTap: () => context.go(AppRoutes.birds),
              ),
              StatCard(
                label: 'home.active_breedings'.tr(),
                value: breedingValue,
                icon: const AppIcon(AppIcons.breedingActive),
                color: isPremium
                    ? AppColors.stageOngoing
                    : _ratioColor(breedingRatio),
                onTap: () => context.go(AppRoutes.breeding),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Row 2: Toplam Yavru + Toplam Yumurta
          _StatsRow(
            children: [
              StatCard(
                label: 'home.total_chicks'.tr(),
                value: '${stats.totalChicks}',
                icon: const AppIcon(AppIcons.chick),
                color: AppColors.budgieGreen,
                onTap: () => context.go(AppRoutes.chicks),
              ),
              StatCard(
                label: 'home.total_eggs'.tr(),
                value: '${stats.totalEggs}',
                icon: const AppIcon(AppIcons.egg),
                color: AppColors.stageNearHatch,
                onTap: () => context.go(AppRoutes.breeding),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Row 3: Kuluçkadaki Yumurta — tam genişlik, yatay layout
          SizedBox(
            height: 86,
            child: StatCard(
              label: 'home.incubating_eggs'.tr(),
              value: '${stats.incubatingEggs}',
              icon: const AppIcon(AppIcons.incubating),
              color: AppColors.stageOngoing,
              onTap: () => context.go(AppRoutes.breeding),
              isHorizontal: true,
            ),
          ),
          // Free tier usage progress bar
          if (!isPremium) ...[
            const SizedBox(height: AppSpacing.md),
            AppProgressBar(
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
          ],
        ],
      ),
    );
  }

  Color _ratioColor(double ratio) {
    if (ratio >= 0.93) return AppColors.error;
    if (ratio >= 0.66) return AppColors.warning;
    return AppColors.budgieGreen;
  }
}

class _StatsRow extends StatelessWidget {
  final List<Widget> children;

  const _StatsRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: children[0]),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: children[1]),
        ],
      ),
    );
  }
}
