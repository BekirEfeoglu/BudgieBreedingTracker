import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../constants/admin_constants.dart';
import '../providers/admin_actions_provider.dart';
import '../providers/admin_database_providers.dart';
import '../providers/admin_models.dart';

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
      title: 'admin.reset_stuck_title'.tr(),
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

/// Shows soft-deleted records per table and a cleanup button with day selector.
class DatabaseSoftDeleteSection extends ConsumerStatefulWidget {
  const DatabaseSoftDeleteSection({super.key});

  @override
  ConsumerState<DatabaseSoftDeleteSection> createState() =>
      _DatabaseSoftDeleteSectionState();
}

class _DatabaseSoftDeleteSectionState
    extends ConsumerState<DatabaseSoftDeleteSection> {
  int _selectedDays = AdminConstants.defaultCleanupDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncStats = ref.watch(softDeleteStatsProvider(_selectedDays));

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'admin.soft_deleted'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DropdownButton<int>(
                  value: _selectedDays,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  items: AdminConstants.cleanupDayOptions
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(
                            '$d ${'admin.days'.tr()}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDays = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            asyncStats.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                '${'common.data_load_error'.tr()}: $e',
                style: theme.textTheme.bodySmall,
              ),
              data: (stats) => _SoftDeleteBody(
                stats: stats,
                selectedDays: _selectedDays,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftDeleteBody extends ConsumerWidget {
  final List<SoftDeleteStats> stats;
  final int selectedDays;

  const _SoftDeleteBody({
    required this.stats,
    required this.selectedDays,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totalOld = stats.fold<int>(0, (sum, s) => sum + s.olderThanDaysCount);

    if (totalOld == 0) {
      return Text(
        'admin.no_deleted_records'.tr(),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.success,
        ),
      );
    }

    final withRecords = stats.where((s) => s.deletedCount > 0).toList();

    return Column(
      children: [
        ...withRecords.map(
          (s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(s.tableName, style: theme.textTheme.bodyMedium),
                ),
                Text(
                  '${s.deletedCount}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${s.olderThanDaysCount}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: s.olderThanDaysCount > 0
                        ? AppColors.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _cleanOldRecords(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            icon: const Icon(LucideIcons.trash2, size: 16),
            label: Text('admin.clean_old_records'.tr()),
          ),
        ),
      ],
    );
  }

  Future<void> _cleanOldRecords(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.clean_old_records_title'.tr(),
      message: 'admin.clean_old_records_confirm'.tr(),
      isDestructive: true,
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    await ref
        .read(adminActionsProvider.notifier)
        .cleanSoftDeletedRecords(selectedDays);
    ref.invalidate(softDeleteStatsProvider(selectedDays));
  }
}

/// Shows storage bucket usage information.
class DatabaseStorageSection extends ConsumerWidget {
  const DatabaseStorageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncUsage = ref.watch(storageUsageProvider);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin.storage_usage'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            asyncUsage.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                '${'common.data_load_error'.tr()}: $e',
                style: theme.textTheme.bodySmall,
              ),
              data: (usages) => Column(
                children: usages
                    .map((u) => _BucketRow(usage: u))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BucketRow extends StatelessWidget {
  final BucketUsage usage;
  const _BucketRow({required this.usage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(LucideIcons.hardDrive, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(usage.bucketName, style: theme.textTheme.bodyMedium),
          ),
          Text(
            '${usage.fileCount} ${'admin.files'.tr()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            _formatSize(usage.totalSizeBytes),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
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
