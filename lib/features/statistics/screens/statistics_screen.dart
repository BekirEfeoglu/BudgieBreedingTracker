import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
