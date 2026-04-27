import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/loading_state.dart';
import '../providers/admin_providers.dart';

/// Live system health panel with the signals an admin needs first.
class DashboardLiveHealthPanel extends ConsumerWidget {
  const DashboardLiveHealthPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overviewAsync = ref.watch(adminSystemHealthOverviewProvider);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: overviewAsync.when(
          loading: () => const LoadingState(),
          error: (_, __) => Text('common.data_load_error'.tr()),
          data: (overview) {
            final color = overview.hasWarnings
                ? AppColors.warning
                : AppColors.success;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      overview.hasWarnings
                          ? LucideIcons.activity
                          : LucideIcons.checkCircle2,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'admin.live_system_health'.tr(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _HealthStatusBadge(status: overview.status, color: color),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final signals = [
                      _HealthSignal(
                        label: 'admin.pending_sync'.tr(),
                        value: overview.pendingSyncCount.toString(),
                      ),
                      _HealthSignal(
                        label: 'admin.error_sync'.tr(),
                        value: overview.errorSyncCount.toString(),
                        isWarning: overview.errorSyncCount > 0,
                      ),
                      _HealthSignal(
                        label: 'admin.open_feedback_short'.tr(),
                        value: overview.openFeedbackCount.toString(),
                      ),
                      _HealthSignal(
                        label: 'admin.security_24h_short'.tr(),
                        value: overview.securityEvents24h.toString(),
                        isWarning: overview.securityEvents24h > 0,
                      ),
                      _HealthSignal(
                        label: 'admin.alerts_short'.tr(),
                        value: overview.activeAlertCount.toString(),
                        isWarning: overview.activeAlertCount > 0,
                      ),
                      _HealthSignal(
                        label: 'admin.storage_short'.tr(),
                        value: _formatSize(overview.storageBytes),
                      ),
                    ];

                    if (constraints.maxWidth < 430) {
                      return GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 1.52,
                        children: [
                          for (final signal in signals)
                            _SignalTile(signal: signal),
                        ],
                      );
                    }

                    return Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final signal in signals)
                          _SignalChip(signal: signal),
                      ],
                    );
                  },
                ),
                if (overview.degradedServices.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'admin.degraded_services'.tr(
                      args: [overview.degradedServices.join(', ')],
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(color: color),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  static String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
}

class _HealthSignal {
  const _HealthSignal({
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  final String label;
  final String value;
  final bool isWarning;
}

class _HealthStatusBadge extends StatelessWidget {
  const _HealthStatusBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({required this.signal});

  final _HealthSignal signal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = signal.isWarning
        ? AppColors.warning
        : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        '${signal.label}: ${signal.value}',
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({required this.signal});

  final _HealthSignal signal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = signal.isWarning
        ? AppColors.warning
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              signal.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            signal.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
