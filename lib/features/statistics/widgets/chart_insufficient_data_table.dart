import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_states.dart';

class ChartInsufficientDataEntry {
  const ChartInsufficientDataEntry({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

/// Table fallback for chart types that would be misleading with tiny samples.
class ChartInsufficientDataTable extends StatelessWidget {
  const ChartInsufficientDataTable({
    super.key,
    required this.total,
    required this.entries,
  });

  final int total;
  final List<ChartInsufficientDataEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChartLowData(
      child: Semantics(
        label: 'statistics.low_data_hint'.tr(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'statistics.total_label'.tr(args: ['$total']),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(),
                1: IntrinsicColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: entries
                  .map((entry) {
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: entry.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  entry.label,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: AppSpacing.md,
                            top: AppSpacing.xs,
                            bottom: AppSpacing.xs,
                          ),
                          child: Text(
                            '${entry.count}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    );
                  })
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}
