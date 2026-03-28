import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'package:budgie_breeding_tracker/router/route_names.dart';

/// Overview tab: quick insights, summary grid, gender pie, color mutation, age distribution.
class OverviewTab extends ConsumerStatefulWidget {
  const OverviewTab({super.key});

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);

    ref.listen<StatsPeriod>(statsPeriodProvider, (_, __) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(summaryStatsProvider(userId));
        ref.invalidate(trendStatsProvider(userId));
        ref.invalidate(genderDistributionProvider(userId));
        ref.invalidate(colorMutationDistributionProvider(userId));
        ref.invalidate(ageDistributionProvider(userId));
        ref.invalidate(quickInsightsProvider(userId));
      },
      child: SingleChildScrollView(
        controller: _scrollController,
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
      error: (e, _) => ChartError(message: 'common.data_load_error'.tr()),
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

    final total = genderAsync.value != null
        ? genderAsync.value!.male +
            genderAsync.value!.female +
            genderAsync.value!.unknown
        : null;
    return ChartCard(
      title: 'statistics.gender_distribution'.tr(),
      icon: const AppIcon(AppIcons.statistics),
      dataCount: total,
      onLowDataAction: () => context.push(AppRoutes.birdForm),
      lowDataActionLabel: 'birds.add_bird'.tr(),
      child: genderAsync.when(
        loading: () => const ChartLoading(isPieChart: true),
        error: (e, _) => ChartError(message: 'common.data_load_error'.tr()),
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

    final dataCount = colorAsync.value?.values
        .where((v) => v > 0)
        .length;
    return ChartCard(
      title: 'statistics.color_mutation'.tr(),
      icon: const AppIcon(AppIcons.colorPalette),
      dataCount: dataCount,
      onLowDataAction: () => context.push(AppRoutes.birdForm),
      lowDataActionLabel: 'birds.add_bird'.tr(),
      child: colorAsync.when(
        loading: () => const ChartLoading(),
        error: (e, _) => ChartError(message: 'common.data_load_error'.tr()),
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

    final dataCount = ageAsync.value?.values
        .where((v) => v > 0)
        .length;
    return ChartCard(
      title: 'statistics.age_distribution'.tr(),
      icon: const AppIcon(AppIcons.bird),
      dataCount: dataCount,
      onLowDataAction: () => context.push(AppRoutes.birdForm),
      lowDataActionLabel: 'birds.add_bird'.tr(),
      child: ageAsync.when(
        loading: () => const ChartLoading(),
        error: (e, _) => ChartError(message: 'common.data_load_error'.tr()),
        data: (data) => AgeDistributionChart(data: data),
      ),
    );
  }
}
