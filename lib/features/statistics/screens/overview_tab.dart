import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_summary_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_trend_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/age_distribution_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/color_mutation_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/gender_pie_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/quick_insights_card.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/summary_stats_grid.dart';

/// Overview tab: quick insights, summary grid, gender pie, color mutation, age distribution.
class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(summaryStatsProvider(userId));
        ref.invalidate(trendStatsProvider(userId));
        ref.invalidate(genderDistributionProvider(userId));
        ref.invalidate(colorMutationDistributionProvider(userId));
        ref.invalidate(ageDistributionProvider(userId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            const QuickInsightsCard(),
            const SizedBox(height: AppSpacing.lg),
            _SummarySection(userId: userId),
            const SizedBox(height: AppSpacing.lg),
            _GenderDistributionSection(userId: userId),
            const SizedBox(height: AppSpacing.lg),
            _ColorMutationSection(userId: userId),
            const SizedBox(height: AppSpacing.lg),
            _AgeDistributionSection(userId: userId),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

class _SummarySection extends ConsumerWidget {
  const _SummarySection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(summaryStatsProvider(userId));
    final trendAsync = ref.watch(trendStatsProvider(userId));

    return statsAsync.when(
      loading: () => const ChartLoading(),
      error: (e, _) => ChartError(message: e.toString()),
      data: (stats) {
        final trends = trendAsync.value;
        return SummaryStatsGrid(stats: stats, trends: trends);
      },
    );
  }
}

class _GenderDistributionSection extends ConsumerWidget {
  const _GenderDistributionSection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genderAsync = ref.watch(genderDistributionProvider(userId));

    return ChartCard(
      title: 'statistics.gender_distribution'.tr(),
      icon: const AppIcon(AppIcons.statistics),
      child: genderAsync.when(
        loading: () => const ChartLoading(),
        error: (e, _) => ChartError(message: e.toString()),
        data: (stats) => GenderPieChart(
          maleCount: stats.male,
          femaleCount: stats.female,
          unknownCount: stats.unknown,
        ),
      ),
    );
  }
}

class _ColorMutationSection extends ConsumerWidget {
  const _ColorMutationSection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorAsync = ref.watch(colorMutationDistributionProvider(userId));

    return ChartCard(
      title: 'statistics.color_mutation'.tr(),
      icon: const AppIcon(AppIcons.colorPalette),
      child: colorAsync.when(
        loading: () => const ChartLoading(),
        error: (e, _) => ChartError(message: e.toString()),
        data: (data) => ColorMutationChart(data: data),
      ),
    );
  }
}

class _AgeDistributionSection extends ConsumerWidget {
  const _AgeDistributionSection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ageAsync = ref.watch(ageDistributionProvider(userId));

    return ChartCard(
      title: 'statistics.age_distribution'.tr(),
      icon: const AppIcon(AppIcons.bird),
      child: ageAsync.when(
        loading: () => const ChartLoading(),
        error: (e, _) => ChartError(message: e.toString()),
        data: (data) => AgeDistributionChart(data: data),
      ),
    );
  }
}
