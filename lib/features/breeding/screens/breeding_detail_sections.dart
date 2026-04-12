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
              Text(
                'breeding.incubation_process'.tr(),
                style: theme.textTheme.titleMedium,
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
