import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_highlights_providers.dart';

class PersonalRecordsCard extends StatelessWidget {
  final PersonalRecords records;

  const PersonalRecordsCard({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    return _HighlightCard(
      title: 'statistics.personal_records'.tr(),
      icon: const AppIcon(AppIcons.leaderboard),
      children: [
        _MetricRow(
          label: 'statistics.record_best_season'.tr(),
          value: records.mostProductiveSeason == null
              ? 'common.not_available'.tr()
              : '${records.mostProductiveSeason!.year} · '
                    '${'statistics.chick_count_short'.tr(args: [records.mostProductiveSeason!.chickCount.toString()])}',
        ),
        _MetricRow(
          label: 'statistics.record_top_pair'.tr(),
          value: records.topPair == null
              ? 'common.not_available'.tr()
              : '${records.topPair!.pairId.substring(0, records.topPair!.pairId.length.clamp(0, 8))} · '
                    '${'statistics.chick_count_short'.tr(args: [records.topPair!.chickCount.toString()])}',
        ),
        _MetricRow(
          label: 'statistics.record_longest_lived'.tr(),
          value: records.longestLivedBird == null
              ? 'common.not_available'.tr()
              : '${records.longestLivedBird!.birdName} · '
                    '${_formatYears(records.longestLivedBird!.daysLived)}',
        ),
      ],
    );
  }
}

class SeasonComparisonCard extends StatelessWidget {
  final SeasonComparison? comparison;

  const SeasonComparisonCard({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    final comparison = this.comparison;
    if (comparison == null) {
      return _HighlightCard(
        title: 'statistics.season_comparison'.tr(),
        icon: const AppIcon(AppIcons.breeding),
        children: [
          Text(
            'statistics.season_comparison_empty'.tr(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    return _HighlightCard(
      title: 'statistics.season_comparison'.tr(),
      icon: const AppIcon(AppIcons.breeding),
      children: [
        Row(
          children: [
            Expanded(child: _SeasonColumn(stats: comparison.previous)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _SeasonColumn(stats: comparison.current)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _MetricRow(
          label: 'statistics.fertility_change'.tr(),
          value:
              '${(comparison.fertilityDelta * 100).toStringAsFixed(1)} ${'statistics.percentage_point'.tr()}',
        ),
      ],
    );
  }
}

class HealthTrendSummaryCard extends StatelessWidget {
  final HealthTrendSummary trend;

  const HealthTrendSummaryCard({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    return _HighlightCard(
      title: 'statistics.health_trend'.tr(),
      icon: const AppIcon(AppIcons.health),
      children: [
        _MetricRow(
          label: 'statistics.health_peak_month'.tr(),
          value: trend.busiestMonthKey == null
              ? 'common.not_available'.tr()
              : '${trend.busiestMonthKey} · ${trend.busiestMonthRecordCount}',
        ),
        _MetricRow(
          label: 'statistics.health_most_visited'.tr(),
          value: trend.mostVisitedBirdName == null
              ? 'common.not_available'.tr()
              : '${trend.mostVisitedBirdName} · '
                    '${trend.mostVisitedBirdRecordCount}',
        ),
        _MetricRow(
          label: 'statistics.health_avg_treatment'.tr(),
          value: trend.averageTreatmentDays == null
              ? 'common.not_available'.tr()
              : '${trend.averageTreatmentDays!.toStringAsFixed(1)} '
                    '${'statistics.days_short'.tr()}',
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String title;
  final Widget icon;
  final List<Widget> children;

  const _HighlightCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                icon,
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonColumn extends StatelessWidget {
  final SeasonStats stats;

  const _SeasonColumn({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stats.year.toString(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('${'statistics.total_eggs'.tr()}: ${stats.totalEggs}'),
            Text(
              '${'statistics.fertility_rate'.tr()}: '
              '${(stats.fertilityRate * 100).toStringAsFixed(1)}%',
            ),
            Text('${'statistics.hatched_chicks'.tr()}: ${stats.hatchedChicks}'),
            Text('${'statistics.live_chicks'.tr()}: ${stats.liveChicks}'),
          ],
        ),
      ),
    );
  }
}

String _formatYears(int days) {
  final years = days / 365.25;
  return '${years.toStringAsFixed(1)} ${'statistics.years_short'.tr()}';
}
