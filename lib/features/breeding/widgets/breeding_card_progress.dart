import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/progress_bar.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_calculator.dart';

/// Progress section of the breeding card showing incubation progress.
class BreedingCardProgress extends StatelessWidget {
  final Incubation incubation;

  const BreedingCardProgress({super.key, required this.incubation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysElapsed = incubation.daysElapsed;
    final totalDays = incubation.totalIncubationDays();
    final stageColor = incubation.isComplete
        ? IncubationCalculator.getCompletedStageColor()
        : IncubationCalculator.getStageColor(daysElapsed, totalDays: totalDays);
    final stageLabel = incubation.isComplete
        ? 'breeding.completed'.tr()
        : IncubationCalculator.getStageLabel(daysElapsed, totalDays: totalDays);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                stageLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: stageColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'breeding.day_progress'.tr(
                args: [daysElapsed.toString(), totalDays.toString()],
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        AppProgressBar(value: incubation.percentageComplete, color: stageColor),
      ],
    );
  }
}
