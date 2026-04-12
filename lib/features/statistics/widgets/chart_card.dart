import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_states.dart';
export 'package:budgie_breeding_tracker/features/statistics/widgets/chart_states.dart';

/// Reusable card wrapper for chart sections.
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.dataCount,
    this.lowDataThreshold = 3,
    this.onLowDataAction,
    this.lowDataActionLabel,
  });

  final String title;
  final String? subtitle;
  final Widget icon;
  final Widget child;
  final int? dataCount;
  final int lowDataThreshold;
  final VoidCallback? onLowDataAction;
  final String? lowDataActionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: title,
      child: Card(
      elevation: 1,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTheme(
                  data: const IconThemeData(size: AppSpacing.xl),
                  child: icon,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              height: 1,
            ),
            const SizedBox(height: AppSpacing.md),
            if (dataCount != null &&
                dataCount! > 0 &&
                dataCount! < lowDataThreshold)
              ChartLowData(
                onAction: onLowDataAction,
                actionLabel: lowDataActionLabel,
                child: child,
              )
            else
              child,
          ],
        ),
      ),
    ),
    );
  }
}
