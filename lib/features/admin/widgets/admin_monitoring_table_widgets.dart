import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/admin_providers.dart';

/// Table details section with header and rows.
class MonitoringTableDetailsSection extends StatelessWidget {
  final List<TableCapacity> tables;

  const MonitoringTableDetailsSection({super.key, required this.tables});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (tables.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.table2,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'admin.table_details'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${tables.length} ${'admin.tables'.tr().toLowerCase()}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _MonitoringTableHeader(theme: theme),
              const Divider(height: 1),
              ...tables.asMap().entries.map((entry) {
                return _MonitoringTableRow(
                  table: entry.value,
                  isEven: entry.key.isEven,
                  theme: theme,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonitoringTableHeader extends StatelessWidget {
  final ThemeData theme;

  const _MonitoringTableHeader({required this.theme});

  @override
  Widget build(BuildContext context) {
    final style = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('admin.tables'.tr(), style: style)),
          Expanded(
            flex: 2,
            child: Text(
              'admin.table_size'.tr(),
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'admin.table_rows'.tr(),
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'admin.dead_tuples'.tr(),
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitoringTableRow extends StatelessWidget {
  final TableCapacity table;
  final bool isEven;
  final ThemeData theme;

  const _MonitoringTableRow({
    required this.table,
    required this.isEven,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final bodyStyle = theme.textTheme.bodySmall;
    final deadColor = table.deadTupleRatio > 10
        ? AppColors.error
        : table.deadTupleRatio > 5
        ? AppColors.warning
        : null;

    return Container(
      color: isEven
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              table.name,
              style: bodyStyle?.copyWith(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatBytes(table.sizeBytes),
              style: bodyStyle,
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatNumber(table.rowCount),
              style: bodyStyle,
              textAlign: TextAlign.end,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${table.deadTupleRatio.toStringAsFixed(1)}%',
              style: bodyStyle?.copyWith(color: deadColor),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  final i = (math.log(bytes) / math.log(1024)).floor().clamp(
    0,
    units.length - 1,
  );
  final value = bytes / math.pow(1024, i);
  return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[i]}';
}

String formatNumber(int n) {
  if (n < 1000) return n.toString();
  final str = n.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
    buffer.write(str[i]);
  }
  return buffer.toString();
}

Color capacityColor(double ratio, [bool invert = false]) {
  if (invert) {
    if (ratio >= 0.95) return AppColors.success;
    if (ratio >= 0.80) return AppColors.warning;
    return AppColors.error;
  }
  if (ratio < 0.70) return AppColors.success;
  if (ratio < 0.90) return AppColors.warning;
  return AppColors.error;
}
