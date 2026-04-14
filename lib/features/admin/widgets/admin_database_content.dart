import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../domain/services/sync/sync_orchestrator.dart';
import '../../../domain/services/sync/sync_providers.dart';
import '../providers/admin_actions_provider.dart';
import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';
import '../providers/admin_providers.dart';
import 'admin_database_maintenance.dart';
import 'admin_database_table_widgets.dart';

part 'admin_database_action_button.dart';

/// Main content body for the database screen.
class DatabaseContent extends ConsumerWidget {
  final List<TableInfo> tables;

  const DatabaseContent({super.key, required this.tables});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalRows = tables.fold<int>(
      0,
      (sum, t) => sum + (t.rowCount > 0 ? t.rowCount : 0),
    );

    ref.listen<AdminActionState>(adminActionsProvider, (prev, next) {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (next.isSuccess && next.successMessage != null) {
        ActionFeedbackService.show(next.successMessage!);
        ref.invalidate(adminDatabaseInfoProvider);
      } else if (next.error != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DatabaseSummaryCard(tableCount: tables.length, totalRows: totalRows),
          const SizedBox(height: AppSpacing.lg),
          const DatabaseGlobalActionsBar(),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'admin.maintenance_tools'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          const DatabaseSyncStatusSection(),
          const SizedBox(height: AppSpacing.md),
          const DatabaseSoftDeleteSection(),
          const SizedBox(height: AppSpacing.md),
          const DatabaseStorageSection(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'admin.tables'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          DatabaseTableList(tables: tables),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

/// Summary card showing table count and total rows.
class DatabaseSummaryCard extends StatelessWidget {
  final int tableCount;
  final int totalRows;

  const DatabaseSummaryCard({
    super.key,
    required this.tableCount,
    required this.totalRows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const AppIcon(
                    AppIcons.database,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '$tableCount',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text('admin.tables'.tr(), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Container(width: 1, height: 48, color: theme.dividerColor),
            Expanded(
              child: Column(
                children: [
                  const Icon(
                    LucideIcons.table2,
                    color: AppColors.info,
                    size: 28,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _formatNumber(totalRows),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.info,
                    ),
                  ),
                  Text(
                    'admin.total_rows'.tr(),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

/// Global backup/reset action bar.
class DatabaseGlobalActionsBar extends ConsumerWidget {
  const DatabaseGlobalActionsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(adminActionsProvider);

    return Row(
      children: [
        Expanded(
          child: DatabaseActionButton(
            icon: const AppIcon(AppIcons.backup, size: 18),
            label: 'admin.backup_all'.tr(),
            color: AppColors.info,
            isLoading: actionState.isLoading,
            onTap: () => _backupAll(context, ref),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: DatabaseActionButton(
            icon: const AppIcon(AppIcons.delete, size: 18),
            label: 'admin.reset_all'.tr(),
            color: AppColors.error,
            isLoading: actionState.isLoading,
            onTap: () => _resetAll(context, ref),
          ),
        ),
      ],
    );
  }

  Future<void> _backupAll(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(adminActionsProvider.notifier);
    final jsonStr = await notifier.exportAllTables();
    if (jsonStr != null && context.mounted) {
      await saveBackupFile(context, 'full_backup', jsonStr);
    }
  }

  Future<void> _resetAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.reset_all_title'.tr(),
      message: 'admin.reset_all_confirm'.tr(),
      isDestructive: true,
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final doubleConfirmed = await showConfirmDialog(
      context,
      title: 'admin.reset_all_double_title'.tr(),
      message: 'admin.reset_all_double_confirm'.tr(),
      isDestructive: true,
    );
    if (doubleConfirmed != true) return;
    if (!context.mounted) return;

    final notifier = ref.read(adminActionsProvider.notifier);
    final success = await notifier.resetAllUserData();
    if (!context.mounted) return;

    if (success) {
      final result = await ref.read(syncOrchestratorProvider).forceFullSync();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result == SyncResult.success
                  ? 'sync.sync_success'.tr()
                  : 'sync.sync_failed'.tr(),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

