import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/breeding_success_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/egg_production_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/fertility_trend_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/incubation_duration_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/stats_species_filter_selector.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

/// Breeding & Eggs tab: breeding success, egg production, fertility, incubation.
class BreedingTab extends ConsumerStatefulWidget {
  const BreedingTab({super.key});

  @override
  ConsumerState<BreedingTab> createState() => _BreedingTabState();
}

class _BreedingTabState extends ConsumerState<BreedingTab> {
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
        ref.invalidate(monthlyBreedingOutcomesProvider(userId));
        ref.invalidate(monthlyEggProductionProvider(userId));
        ref.invalidate(monthlyFertilityRateProvider(userId));
        ref.invalidate(incubationDurationProvider(userId));
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            const StatsSpeciesFilterSelector(),
            const SizedBox(height: AppSpacing.lg),
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

    final dataCount = outcomesAsync.value?.completed.values
        .where((v) => v > 0)
        .length;
    return ChartCard(
      title: 'statistics.breeding_success'.tr(),
      subtitle: 'statistics.breeding_success_subtitle'.tr(),
      icon: const AppIcon(AppIcons.breeding),
      dataCount: dataCount,
      onLowDataAction: () => context.push(AppRoutes.breedingForm),
      lowDataActionLabel: 'breeding.add_breeding_label'.tr(),
      child: outcomesAsync.when(
        loading: () => const ChartLoading(),
        error: (e, _) => ChartError(message: 'common.data_load_error'.tr()),
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

    final dataCount = eggDataAsync.value?.values.where((v) => v > 0).length;
    return ChartCard(
      title: 'statistics.egg_production'.tr(),
      subtitle: 'statistics.egg_production_subtitle'.tr(),
      icon: const AppIcon(AppIcons.egg),
      dataCount: dataCount,
      onLowDataAction: () => context.push(AppRoutes.breeding),
      lowDataActionLabel: 'eggs.add_egg'.tr(),
      child: eggDataAsync.when(
        loading: () => const ChartLoading(isLineChart: true),
        error: (e, _) => ChartError(message: 'common.data_load_error'.tr()),
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

    final dataCount = fertilityAsync.value?.values.where((v) => v > 0.0).length;
    return ChartCard(
      title: 'statistics.fertility_trend'.tr(),
      subtitle: 'statistics.fertility_trend_subtitle'.tr(),
      icon: const AppIcon(AppIcons.fertile),
      dataCount: dataCount,
      onLowDataAction: () => context.push(AppRoutes.breeding),
      lowDataActionLabel: 'eggs.add_egg'.tr(),
      child: fertilityAsync.when(
        loading: () => const ChartLoading(isLineChart: true),
        error: (e, _) => ChartError(message: 'common.data_load_error'.tr()),
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

    final dataCount = durationAsync.value?.length;
    return ChartCard(
      title: 'statistics.incubation_duration'.tr(),
      subtitle: 'statistics.incubation_duration_subtitle'.tr(),
      icon: const AppIcon(AppIcons.incubation),
      dataCount: dataCount,
      onLowDataAction: () => context.push(AppRoutes.breeding),
      lowDataActionLabel: 'breeding.add_breeding_label'.tr(),
      child: durationAsync.when(
        loading: () => const ChartLoading(),
        error: (e, _) => ChartError(message: 'common.data_load_error'.tr()),
        data: (data) => IncubationDurationChart(data: data),
      ),
    );
  }
}
