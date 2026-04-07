import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../providers/admin_actions_provider.dart';
import '../providers/admin_database_providers.dart';
import '../providers/admin_maintenance_models.dart';

/// Shows pending/error sync counts and a reset stuck button.
class DatabaseSyncStatusSection extends ConsumerWidget {
  const DatabaseSyncStatusSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncSummary = ref.watch(syncStatusSummaryProvider);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin.sync_status'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            asyncSummary.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                '${'common.data_load_error'.tr()}: $e',
                style: theme.textTheme.bodySmall,
              ),
              data: (summary) => _SyncStatusBody(summary: summary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncStatusBody extends ConsumerWidget {
  final SyncStatusSummary summary;
  const _SyncStatusBody({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasIssues = summary.pendingCount > 0 || summary.errorCount > 0;

    if (!hasIssues) {
      return Row(
        children: [
          const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'admin.no_sync_issues'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.success,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (summary.pendingCount > 0)
          _SyncRow(
            icon: LucideIcons.clock,
            color: AppColors.warning,
            label: 'admin.pending_sync'.tr(),
            count: summary.pendingCount,
          ),
        if (summary.errorCount > 0)
          _SyncRow(
            icon: LucideIcons.alertTriangle,
            color: AppColors.error,
            label: 'admin.error_sync'.tr(),
            count: summary.errorCount,
          ),
        if (summary.oldestPendingAt != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              '${'admin.oldest_pending'.tr()}: ${_formatAge(summary.oldestPendingAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (summary.errorCount > 0) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _resetStuck(context, ref),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text('admin.reset_stuck'.tr()),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _resetStuck(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.reset_stuck'.tr(),
      message: 'admin.reset_stuck_confirm'.tr(),
      isDestructive: true,
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    await ref.read(adminActionsProvider.notifier).resetStuckSyncRecords();
    ref.invalidate(syncStatusSummaryProvider);
  }

  String _formatAge(DateTime oldest) {
    final diff = DateTime.now().difference(oldest);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }
}

class _SyncRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _SyncRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            '$count',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
