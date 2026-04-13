import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_health_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chick_survival_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/health_record_type_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/monthly_trend_chart.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

/// Chicks & Health tab: monthly trend, chick survival, health records.
class HealthTab extends ConsumerStatefulWidget {
  const HealthTab({super.key});

  @override
  ConsumerState<HealthTab> createState() => _HealthTabState();
}

class _HealthTabState extends ConsumerState<HealthTab> {
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
        ref.invalidate(monthlyHatchedChicksProvider(userId));
        ref.invalidate(chickSurvivalProvider(userId));
        ref.invalidate(healthRecordTypeDistributionProvider(userId));
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            _MonthlyTrendSection(userId: userId),
            const SizedBox(height: AppSpacing.lg),
            _ChickSurvivalSection(userId: userId),
            const SizedBox(height: AppSpacing.lg),
            _HealthRecordSection(userId: userId),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

class _MonthlyTrendSection extends ConsumerWidget {
  const _MonthlyTrendSection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(monthlyHatchedChicksProvider(userId));

    final dataCount = trendAsync.value?.values.where((v) => v > 0).length;
    return ChartCard(
      title: 'statistics.monthly_trend'.tr(),
      subtitle: 'statistics.monthly_trend_subtitle'.tr(),
      icon: const AppIcon(AppIcons.growth),
      dataCount: dataCount,
      onLowDataAction: () => context.push(AppRoutes.chickForm),
      lowDataActionLabel: 'chicks.add_chick'.tr(),
      child: trendAsync.when(
        loading: () => const ChartLoading(isLineChart: true),
        error: (e, _) => ChartError(message: 'common.data_load_error'.tr()),
        data: (data) => MonthlyTrendChart(monthlyData: data),
      ),
    );
  }
}

class _ChickSurvivalSection extends ConsumerWidget {
  const _ChickSurvivalSection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final survivalAsync = ref.watch(chickSurvivalProvider(userId));

    final total = survivalAsync.value != null
        ? survivalAsync.value!.healthy +
            survivalAsync.value!.sick +
            survivalAsync.value!.deceased
        : null;
    return ChartCard(
      title: 'statistics.chick_survival'.tr(),
      subtitle: 'statistics.chick_survival_subtitle'.tr(),
      icon: const AppIcon(AppIcons.chick),
      dataCount: total,
      onLowDataAction: () => context.push(AppRoutes.chickForm),
      lowDataActionLabel: 'chicks.add_chick'.tr(),
      child: survivalAsync.when(
        loading: () => const ChartLoading(isPieChart: true),
        error: (e, _) => ChartError(message: 'common.data_load_error'.tr()),
        data: (data) => ChickSurvivalChart(data: data),
      ),
    );
  }
}

class _HealthRecordSection extends ConsumerWidget {
  const _HealthRecordSection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthRecordTypeDistributionProvider(userId));

    final dataCount = healthAsync.value?.values
        .where((v) => v > 0)
        .length;
    return ChartCard(
      title: 'statistics.health_type_distribution'.tr(),
      subtitle: 'statistics.health_type_subtitle'.tr(),
      icon: const AppIcon(AppIcons.health),
      dataCount: dataCount,
      onLowDataAction: () => context.push(AppRoutes.healthRecordForm),
      lowDataActionLabel: 'health_records.add_record'.tr(),
      child: healthAsync.when(
        loading: () => const ChartLoading(),
        error: (e, _) => ChartError(message: 'common.data_load_error'.tr()),
        data: (data) => HealthRecordTypeChart(data: data),
      ),
    );
  }
}
