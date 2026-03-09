import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_health_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chick_survival_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/health_record_type_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/monthly_trend_chart.dart';

/// Chicks & Health tab: monthly trend, chick survival, health records.
class HealthTab extends ConsumerWidget {
  const HealthTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(monthlyHatchedChicksProvider(userId));
        ref.invalidate(chickSurvivalProvider(userId));
        ref.invalidate(healthRecordTypeDistributionProvider(userId));
      },
      child: SingleChildScrollView(
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

    return ChartCard(
      title: 'statistics.monthly_trend'.tr(),
      subtitle: 'statistics.monthly_trend_subtitle'.tr(),
      icon: const AppIcon(AppIcons.growth),
      child: trendAsync.when(
        loading: () => const ChartLoading(),
        error: (e, _) => ChartError(message: e.toString()),
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

    return ChartCard(
      title: 'statistics.chick_survival'.tr(),
      subtitle: 'statistics.chick_survival_subtitle'.tr(),
      icon: const AppIcon(AppIcons.chick),
      child: survivalAsync.when(
        loading: () => const ChartLoading(),
        error: (e, _) => ChartError(message: e.toString()),
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
    final healthAsync =
        ref.watch(healthRecordTypeDistributionProvider(userId));

    return ChartCard(
      title: 'statistics.health_type_distribution'.tr(),
      subtitle: 'statistics.health_type_subtitle'.tr(),
      icon: const AppIcon(AppIcons.health),
      child: healthAsync.when(
        loading: () => const ChartLoading(),
        error: (e, _) => ChartError(message: e.toString()),
        data: (data) => HealthRecordTypeChart(data: data),
      ),
    );
  }
}
