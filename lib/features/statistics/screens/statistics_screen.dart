import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/app_icon_button.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/export/pdf_export_service.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_health_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_highlights_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_summary_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_trend_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/screens/breeding_tab.dart';
import 'package:budgie_breeding_tracker/features/statistics/screens/health_tab.dart';
import 'package:budgie_breeding_tracker/features/statistics/screens/overview_tab.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/stats_period_selector.dart';
import 'package:share_plus/share_plus.dart';

/// Main statistics screen with 3 tabs: Overview, Breeding & Eggs, Chicks & Health.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  // Read userId fresh inside build / callbacks via ref.read so a logout /
  // re-login while this screen is alive doesn't leave us invalidating the
  // wrong provider family key. Previous initState-cached value would go
  // stale across auth changes (audit Wave 3).
  String get _userId => ref.read(currentUserIdProvider);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    ref.invalidate(personalRecordsProvider(_userId));
    ref.invalidate(seasonComparisonProvider(_userId));
    ref.invalidate(healthTrendSummaryProvider(_userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              title: AppScreenTitle(
                title: 'statistics.title'.tr(),
                iconAsset: AppIcons.statistics,
              ),
              actions: [
                AppIconButton(
                  tooltip: 'statistics.share_report'.tr(),
                  semanticLabel: 'statistics.share_report'.tr(),
                  onPressed: _shareStatisticsReport,
                  icon: const AppIcon(AppIcons.pdf),
                ),
              ],
            ),
            const SliverToBoxAdapter(
              child: StatsPeriodSelector(),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  dividerColor: Colors.transparent,
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
                Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: const [OverviewTab(), BreedingTab(), HealthTab()],
        ),
      ),
    );
  }

  Future<void> _shareStatisticsReport() async {
    try {
      final personalRecords =
          ref.read(personalRecordsProvider(_userId)).value ??
          const PersonalRecords();
      final seasonComparison = ref
          .read(seasonComparisonProvider(_userId))
          .value;
      final healthTrend =
          ref.read(healthTrendSummaryProvider(_userId)).value ??
          const HealthTrendSummary();
      final bytes = await PdfExportService().generateStatisticsReport(
        personalRecords: personalRecords,
        seasonComparison: seasonComparison,
        healthTrend: healthTrend,
      );
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          subject: 'statistics.title'.tr(),
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'application/pdf',
              name: 'statistics-report.pdf',
            ),
          ],
        ),
      );
    } catch (e, st) {
      AppLogger.error('StatisticsScreen.shareReport', e, st);
      await Sentry.captureException(
        e,
        stackTrace: st,
        withScope: (scope) => scope.setTag('feature', 'statistics'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('statistics.share_report_failed'.tr())),
      );
    }
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar, this.backgroundColor);

  final TabBar tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
