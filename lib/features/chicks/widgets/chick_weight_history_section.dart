import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';

class ChickWeightHistorySection extends StatelessWidget {
  final List<GrowthMeasurement> measurements;

  const ChickWeightHistorySection({super.key, required this.measurements});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = List<GrowthMeasurement>.of(measurements)
      ..sort((a, b) => a.measurementDate.compareTo(b.measurementDate));

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'chicks.weight_history'.tr(),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (sorted.isEmpty)
            Text(
              'chicks.no_weight_records'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
              child: Column(
                children: [
                  _WeightSparkline(measurements: sorted),
                  const SizedBox(height: AppSpacing.md),
                  ...sorted.take(5).map(_WeightMeasurementRow.new),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WeightSparkline extends StatelessWidget {
  final List<GrowthMeasurement> measurements;

  const _WeightSparkline({required this.measurements});

  @override
  Widget build(BuildContext context) {
    final min = measurements
        .map((m) => m.weight)
        .reduce((a, b) => a < b ? a : b);
    final max = measurements
        .map((m) => m.weight)
        .reduce((a, b) => a > b ? a : b);
    final latest = measurements.last.weight;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          alignment: Alignment.center,
          child: const AppIcon(AppIcons.growth, color: AppColors.info),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${latest.toStringAsFixed(1)} g',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              LinearProgressIndicator(
                value: max == min ? 1 : ((latest - min) / (max - min)),
                minHeight: 6,
                backgroundColor: AppColors.info.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.info),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeightMeasurementRow extends StatelessWidget {
  final GrowthMeasurement measurement;

  const _WeightMeasurementRow(this.measurement);

  @override
  Widget build(BuildContext context) {
    final date = measurement.measurementDate;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            '${measurement.weight.toStringAsFixed(1)} g',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
