part of 'breeding_detail_screen.dart';

class _IncubationSection extends ConsumerWidget {
  final Incubation incubation;

  const _IncubationSection({required this.incubation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = ref.watch(dateFormatProvider).formatter();
    final daysElapsed = incubation.daysElapsed;
    final totalDays = incubation.totalIncubationDays();
    final isComplete = incubation.isComplete;
    final stageColor = isComplete
        ? IncubationCalculator.getCompletedStageColor()
        : IncubationCalculator.getStageColor(daysElapsed, totalDays: totalDays);
    final stageLabel = isComplete
        ? 'breeding.completed'.tr()
        : IncubationCalculator.getStageLabel(daysElapsed, totalDays: totalDays);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'breeding.incubation_process'.tr(),
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: stageColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  stageLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: stageColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppProgressBar(
            value: incubation.percentageComplete,
            color: stageColor,
            label: '${'breeding.day'.tr()} $daysElapsed / $totalDays',
            showPercentage: true,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (incubation.startDate != null)
                Flexible(
                  child: Text(
                    '${'breeding.start_date'.tr()}: ${dateFormat.format(incubation.startDate!)}',
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (incubation.computedExpectedHatchDate != null)
                Flexible(
                  child: Text(
                    '${'breeding.expected_date'.tr()}: ${dateFormat.format(incubation.computedExpectedHatchDate!)}',
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeasonSummarySection extends ConsumerWidget {
  final String incubationId;

  const _SeasonSummarySection({required this.incubationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(breedingSeasonSummaryProvider(incubationId));
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'breeding.season_summary'.tr(),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          summaryAsync.when(
            loading: () => Semantics(
              label: 'common.loading'.tr(),
              child: const LinearProgressIndicator(),
            ),
            error: (_, __) => Text(
              'common.data_load_error'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            data: (summary) => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 2.75,
              children: [
                _SeasonMetricTile(
                  icon: const AppIcon(AppIcons.egg),
                  label: 'breeding.total_eggs'.tr(),
                  value: summary.totalEggs.toString(),
                  color: AppColors.primary,
                ),
                _SeasonMetricTile(
                  icon: const AppIcon(AppIcons.fertile),
                  label: 'breeding.fertile_eggs'.tr(),
                  value: summary.fertileEggs.toString(),
                  color: AppColors.info,
                ),
                _SeasonMetricTile(
                  icon: const AppIcon(AppIcons.hatched),
                  label: 'breeding.hatched_eggs'.tr(),
                  value: summary.hatchedEggs.toString(),
                  color: AppColors.success,
                ),
                _SeasonMetricTile(
                  icon: const AppIcon(AppIcons.chick),
                  label: 'breeding.live_chicks'.tr(),
                  value: summary.liveChicks.toString(),
                  color: AppColors.stageFledgling,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonMetricTile extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  final Color color;

  const _SeasonMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            alignment: Alignment.center,
            child: IconTheme(
              data: IconThemeData(color: color, size: 20),
              child: icon,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
