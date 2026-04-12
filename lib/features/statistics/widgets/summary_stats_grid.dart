import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/cards/stat_card.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';

/// Grid showing 6 summary statistic cards with optional trend indicators.
class SummaryStatsGrid extends StatelessWidget {
  const SummaryStatsGrid({super.key, required this.stats, this.trends});

  final SummaryStats stats;
  final TrendStats? trends;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.3,
      children: [
        StatCard(
          label: 'statistics.summary_total_birds'.tr(),
          value: stats.totalBirds.toString(),
          icon: const AppIcon(AppIcons.bird),
          color: AppColors.budgieBlue,
          trendPercent: trends?.birdsTrend,
          trendUp: trends != null ? (trends!.birdsTrend >= 0) : null,
        ),
        StatCard(
          label: 'statistics.summary_active_breedings'.tr(),
          value: stats.activeBreedings.toString(),
          icon: const AppIcon(AppIcons.breeding),
          color: AppColors.primary,
          trendPercent: trends?.breedingsTrend,
          trendUp: trends != null ? (trends!.breedingsTrend >= 0) : null,
        ),
        StatCard(
          label: 'statistics.summary_incubating_eggs'.tr(),
          value: stats.incubatingEggs.toString(),
          icon: const AppIcon(AppIcons.egg),
          color: AppColors.warning,
        ),
        StatCard(
          label: 'statistics.summary_fertility_rate'.tr(),
          value: '${(stats.fertilityRate * 100).toStringAsFixed(0)}%',
          icon: const AppIcon(AppIcons.fertile),
          color: AppColors.success,
          trendPercent: trends?.fertilityTrend,
          trendUp: trends != null ? (trends!.fertilityTrend >= 0) : null,
        ),
        StatCard(
          label: 'statistics.summary_survival_rate'.tr(),
          value: '${(stats.chickSurvivalRate * 100).toStringAsFixed(0)}%',
          icon: const AppIcon(AppIcons.chick),
          color: AppColors.budgieGreen,
          trendPercent: trends?.survivalTrend,
          trendUp: trends != null ? (trends!.survivalTrend >= 0) : null,
        ),
        StatCard(
          label: 'statistics.summary_health_records'.tr(),
          value: stats.totalHealthRecords.toString(),
          icon: const AppIcon(AppIcons.health),
          color: AppColors.error,
        ),
      ],
    );
  }
}
