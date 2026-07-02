part of 'statistics_trend_providers.dart';

/// Produces 3-4 human-readable insights about the current period.
/// Egg/chick stats are SQL-aggregated (reuses trendStatsProvider's period
/// stats providers); active-breeding count reuses `activeBreedingCountProvider`
/// (all-time, not period-scoped — matches the original `pairs.where(...)`
/// semantics, which never filtered by period either).
final quickInsightsProvider =
    Provider.family<AsyncValue<List<QuickInsight>>, String>((ref, userId) {
      final period = ref.watch(statsPeriodProvider);
      final range = buildStatsDateRange(period);

      final eggStatsAsync = ref.watch(
        _periodEggStatsStreamProvider((
          userId: userId,
          from: range.currentStart,
          to: range.currentEnd,
        )),
      );
      final chickStatsAsync = ref.watch(
        _periodChickStatsStreamProvider((
          userId: userId,
          from: range.currentStart,
          to: range.currentEnd,
        )),
      );
      final activeBreedingsAsync = ref.watch(
        activeBreedingCountProvider(userId),
      );
      final trendAsync = ref.watch(trendStatsProvider(userId));

      // Fast-fail on any error
      for (final a in [eggStatsAsync, chickStatsAsync, activeBreedingsAsync]) {
        if (a.hasError) {
          return AsyncError(a.error!, a.stackTrace ?? StackTrace.empty);
        }
      }
      // Loading if any data stream hasn't resolved (trend loading is handled
      // below via trendAsync.value returning null → neutral sentiment)
      if (eggStatsAsync.isLoading ||
          chickStatsAsync.isLoading ||
          activeBreedingsAsync.isLoading) {
        return const AsyncLoading();
      }

      final eggStats = eggStatsAsync.requireValue;
      final chickStats = chickStatsAsync.requireValue;
      final activeBreedings = activeBreedingsAsync.requireValue;

      final insights = <QuickInsight>[];
      final trends = trendAsync.value;

      // Egg production insight
      if (eggStats.total > 0) {
        final trendText = trends != null && trends.eggsTrend.abs() > 0
            ? ' (${trends.eggsTrend > 0 ? "+" : ""}${trends.eggsTrend.toStringAsFixed(0)}%)'
            : '';
        insights.add(
          QuickInsight(
            text: 'statistics.insight_egg_production'.tr(
              args: ['${eggStats.total}$trendText'],
            ),
            sentiment: trends == null
                ? InsightSentiment.neutral
                : (trends.eggsTrend >= 0
                      ? InsightSentiment.positive
                      : InsightSentiment.negative),
          ),
        );
      }

      // Fertility rate insight
      final checked = eggStats.fertile + eggStats.infertile;
      if (checked > 0) {
        final rate = (eggStats.fertile / checked * 100).toStringAsFixed(0);
        insights.add(
          QuickInsight(
            text: 'statistics.insight_fertility'.tr(args: [rate]),
            sentiment: (eggStats.fertile / checked) >= 0.5
                ? InsightSentiment.positive
                : InsightSentiment.negative,
          ),
        );
      }

      // Chick survival insight
      if (chickStats.total > 0) {
        final survivedChicks = chickStats.total - chickStats.deceased;
        insights.add(
          QuickInsight(
            text: 'statistics.insight_chick_survival'.tr(
              args: ['$survivedChicks'],
            ),
            sentiment: survivedChicks >= chickStats.total * 0.7
                ? InsightSentiment.positive
                : InsightSentiment.negative,
          ),
        );
      }

      // Active breeding insight
      if (activeBreedings > 0) {
        insights.add(
          QuickInsight(
            text: 'statistics.insight_breeding_active'.tr(
              args: ['$activeBreedings'],
            ),
            sentiment: InsightSentiment.neutral,
          ),
        );
      }

      // No data fallback
      if (insights.isEmpty) {
        insights.add(
          QuickInsight(
            text: 'statistics.insight_no_data'.tr(),
            sentiment: InsightSentiment.neutral,
          ),
        );
      }

      return AsyncData(insights);
    });
