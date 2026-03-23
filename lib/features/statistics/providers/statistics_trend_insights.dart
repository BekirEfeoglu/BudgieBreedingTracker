part of 'statistics_trend_providers.dart';

/// Produces 3-4 human-readable insights about the current period.
final quickInsightsProvider =
    Provider.family<AsyncValue<List<QuickInsight>>, String>((ref, userId) {
      final period = ref.watch(statsPeriodProvider);
      final eggsAsync = ref.watch(eggsStreamProvider(userId));
      final chicksAsync = ref.watch(chicksStreamProvider(userId));
      final pairsAsync = ref.watch(breedingPairsStreamProvider(userId));
      final trendAsync = ref.watch(trendStatsProvider(userId));

      return eggsAsync.when(
        loading: () => const AsyncLoading(),
        error: (e, st) => AsyncError(e, st),
        data: (eggs) => chicksAsync.when(
          loading: () => const AsyncLoading(),
          error: (e, st) => AsyncError(e, st),
          data: (chicks) => pairsAsync.when(
            loading: () => const AsyncLoading(),
            error: (e, st) => AsyncError(e, st),
            data: (pairs) {
              final range = buildStatsDateRange(period);

              final insights = <QuickInsight>[];
              final trends = trendAsync.value;

              // Egg production insight
              final periodEggs = eggs
                  .where((e) => range.isInCurrent(e.layDate))
                  .length;
              if (periodEggs > 0) {
                final trendText = trends != null && trends.eggsTrend.abs() > 0
                    ? ' (${trends.eggsTrend > 0 ? "+" : ""}${trends.eggsTrend.toStringAsFixed(0)}%)'
                    : '';
                insights.add(
                  QuickInsight(
                    text: 'statistics.insight_egg_production'.tr(
                      args: ['$periodEggs$trendText'],
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
              final fertile = eggs
                  .where(
                    (e) =>
                        range.isInCurrent(e.layDate) &&
                        (e.status == EggStatus.fertile ||
                            e.status == EggStatus.hatched),
                  )
                  .length;
              final infertile = eggs
                  .where(
                    (e) =>
                        range.isInCurrent(e.layDate) &&
                        e.status == EggStatus.infertile,
                  )
                  .length;
              final checked = fertile + infertile;
              if (checked > 0) {
                final rate = (fertile / checked * 100).toStringAsFixed(0);
                insights.add(
                  QuickInsight(
                    text: 'statistics.insight_fertility'.tr(args: [rate]),
                    sentiment: (fertile / checked) >= 0.5
                        ? InsightSentiment.positive
                        : InsightSentiment.negative,
                  ),
                );
              }

              // Chick survival insight
              final periodChicks = chicks
                  .where(
                    (c) =>
                        c.hatchDate != null && range.isInCurrent(c.hatchDate!),
                  )
                  .toList();
              final survivedChicks = periodChicks
                  .where((c) => c.healthStatus != ChickHealthStatus.deceased)
                  .length;
              if (periodChicks.isNotEmpty) {
                insights.add(
                  QuickInsight(
                    text: 'statistics.insight_chick_survival'.tr(
                      args: ['$survivedChicks'],
                    ),
                    sentiment: survivedChicks >= periodChicks.length * 0.7
                        ? InsightSentiment.positive
                        : InsightSentiment.negative,
                  ),
                );
              }

              // Active breeding insight
              final activeBreedings = pairs
                  .where(
                    (p) =>
                        p.status == BreedingStatus.active ||
                        p.status == BreedingStatus.ongoing,
                  )
                  .length;
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
            },
          ),
        ),
      );
    });
