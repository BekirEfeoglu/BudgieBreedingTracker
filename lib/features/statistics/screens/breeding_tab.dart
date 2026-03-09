import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/breeding_success_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/egg_production_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/fertility_trend_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/incubation_duration_chart.dart';

/// Breeding & Eggs tab: breeding success, egg production, fertility, incubation.
class BreedingTab extends ConsumerWidget {
  const BreedingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(monthlyBreedingOutcomesProvider(userId));
        ref.invalidate(monthlyEggProductionProvider(userId));
        ref.invalidate(monthlyFertilityRateProvider(userId));
        ref.invalidate(incubationDurationProvider(userId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            _BreedingSuccessSection(userId: userId),
            const SizedBox(height: AppSpacing.lg),
            _EggProductionSection(userId: userId),
            const SizedBox(height: AppSpacing.lg),
            _FertilityTrendSection(userId: userId),
            const SizedBox(height: AppSpacing.lg),
            _IncubationDurationSection(userId: userId),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

class _BreedingSuccessSection extends ConsumerWidget {
  const _BreedingSuccessSection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outcomesAsync = ref.watch(monthlyBreedingOutcomesProvider(userId));

    return ChartCard(
      title: 'statistics.breeding_success'.tr(),
      subtitle: 'statistics.breeding_success_subtitle'.tr(),
      icon: const AppIcon(AppIcons.breeding),
      child: outcomesAsync.when(
        loading: () => const ChartLoading(),
        error: (e, _) => ChartError(message: e.toString()),
        data: (data) => BreedingSuccessChart(
          completed: data.completed,
          cancelled: data.cancelled,
        ),
      ),
    );
  }
}

class _EggProductionSection extends ConsumerWidget {
  const _EggProductionSection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eggDataAsync = ref.watch(monthlyEggProductionProvider(userId));

    return ChartCard(
      title: 'statistics.egg_production'.tr(),
      subtitle: 'statistics.egg_production_subtitle'.tr(),
      icon: const AppIcon(AppIcons.egg),
      child: eggDataAsync.when(
        loading: () => const ChartLoading(),
        error: (e, _) => ChartError(message: e.toString()),
        data: (data) => EggProductionChart(monthlyData: data),
      ),
    );
  }
}

class _FertilityTrendSection extends ConsumerWidget {
  const _FertilityTrendSection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fertilityAsync = ref.watch(monthlyFertilityRateProvider(userId));

    return ChartCard(
      title: 'statistics.fertility_trend'.tr(),
      subtitle: 'statistics.fertility_trend_subtitle'.tr(),
      icon: const AppIcon(AppIcons.fertile),
      child: fertilityAsync.when(
        loading: () => const ChartLoading(),
        error: (e, _) => ChartError(message: e.toString()),
        data: (data) => FertilityTrendChart(monthlyData: data),
      ),
    );
  }
}

class _IncubationDurationSection extends ConsumerWidget {
  const _IncubationDurationSection({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final durationAsync = ref.watch(incubationDurationProvider(userId));

    return ChartCard(
      title: 'statistics.incubation_duration'.tr(),
      subtitle: 'statistics.incubation_duration_subtitle'.tr(),
      icon: const AppIcon(AppIcons.incubation),
      child: durationAsync.when(
        loading: () => const ChartLoading(),
        error: (e, _) => ChartError(message: e.toString()),
        data: (data) => IncubationDurationChart(data: data),
      ),
    );
  }
}
