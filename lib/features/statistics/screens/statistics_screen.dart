import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_health_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_summary_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_trend_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/screens/breeding_tab.dart';
import 'package:budgie_breeding_tracker/features/statistics/screens/health_tab.dart';
import 'package:budgie_breeding_tracker/features/statistics/screens/overview_tab.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/stats_period_selector.dart';

/// Main statistics screen with 3 tabs: Overview, Breeding & Eggs, Chicks & Health.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final String _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _userId = ref.read(currentUserIdProvider);
    // Invalidate on mount so stale keepAlive caches are cleared when
    // returning to this screen. Schedule after the first frame so Riverpod's
    // inherited scope is fully available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _invalidateStatisticsProviders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _invalidateStatisticsProviders() {
    // Invalidate shared providers
    ref.invalidate(summaryStatsProvider(_userId));
    ref.invalidate(trendStatsProvider(_userId));
    ref.invalidate(quickInsightsProvider(_userId));

    // Invalidate all tab providers (not just the active tab) to ensure
    // stale keepAlive caches are cleared when leaving the screen.
    // Overview
    ref.invalidate(genderDistributionProvider(_userId));
    ref.invalidate(colorMutationDistributionProvider(_userId));
    ref.invalidate(ageDistributionProvider(_userId));
    // Breeding
    ref.invalidate(monthlyEggProductionProvider(_userId));
    ref.invalidate(monthlyHatchedChicksProvider(_userId));
    ref.invalidate(monthlyBreedingOutcomesProvider(_userId));
    ref.invalidate(monthlyFertilityRateProvider(_userId));
    ref.invalidate(incubationDurationProvider(_userId));
    // Health
    ref.invalidate(chickSurvivalProvider(_userId));
    ref.invalidate(healthRecordTypeDistributionProvider(_userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppScreenTitle(
          title: 'statistics.title'.tr(),
          iconAsset: AppIcons.statistics,
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              icon: const AppIcon(AppIcons.statistics, size: 18),
              text: 'statistics.tab_overview'.tr(),
            ),
            Tab(
              icon: const AppIcon(AppIcons.breedingActive, size: 18),
              text: 'statistics.tab_breeding'.tr(),
            ),
            Tab(
              icon: const AppIcon(AppIcons.health, size: 18),
              text: 'statistics.tab_health'.tr(),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const StatsPeriodSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [OverviewTab(), BreedingTab(), HealthTab()],
            ),
          ),
        ],
      ),
    );
  }
}
