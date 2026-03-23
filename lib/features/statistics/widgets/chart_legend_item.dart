import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

/// Reusable legend item for chart widgets.
///
/// Displays a color indicator (circle or rounded square based on [useCircle]),
/// a label, and an optional count in parentheses.
class ChartLegendItem extends StatelessWidget {
  const ChartLegendItem({
    super.key,
    required this.color,
    required this.label,
    this.count,
    this.useCircle = true,
  });

  final Color color;
  final String label;
  final int? count;
  final bool useCircle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSpacing.md,
          height: AppSpacing.md,
          decoration: BoxDecoration(
            color: color,
            shape: useCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: useCircle
                ? null
                : BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          count != null ? '$label ($count)' : label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
