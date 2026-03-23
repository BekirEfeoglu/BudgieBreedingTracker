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
import '../providers/admin_providers.dart';
import 'admin_database_backup_utils.dart';
export 'admin_database_backup_utils.dart';

/// Table list with expandable rows.
class DatabaseTableList extends StatelessWidget {
  final List<TableInfo> tables;

  const DatabaseTableList({super.key, required this.tables});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tables.map((table) => DatabaseTableRow(table: table)).toList(),
    );
  }
}

/// Single table row with action bottom sheet.
class DatabaseTableRow extends ConsumerWidget {
  final TableInfo table;

  const DatabaseTableRow({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasError = table.rowCount < 0;
    final isProtected = protectedTables.contains(table.name);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => _showTableActions(context, ref),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.table2,
                size: 18,
                color: hasError
                    ? AppColors.error
                    : isProtected
                    ? AppColors.warning
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      table.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isProtected)
                      Text(
                        'admin.protected_table'.tr(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.warning,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasError)
                const AppIcon(
                  AppIcons.warning,
                  size: 16,
                  color: AppColors.error,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '${table.rowCount}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                LucideIcons.moreVertical,
                size: 16,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTableActions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isProtected = protectedTables.contains(table.name);

    showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(maxWidth: AppSpacing.maxSheetWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.table2,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          table.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                        ),
                        child: Text(
                          '${table.rowCount} ${'admin.rows'.tr()}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                ListTile(
                  leading: AppIcon(
                    AppIcons.export,
                    color: AppColors.info,
                    semanticsLabel: 'common.export'.tr(),
                  ),
                  title: Text('admin.backup_table'.tr()),
                  subtitle: Text('admin.backup_table_desc'.tr()),
                  onTap: () {
                    Navigator.pop(ctx);
                    _backupTable(context, ref);
                  },
                ),
                if (!isProtected)
                  ListTile(
                    leading: AppIcon(
                      AppIcons.delete,
                      color: AppColors.error,
                      semanticsLabel: 'common.delete'.tr(),
                    ),
                    title: Text(
                      'admin.reset_table'.tr(),
                      style: const TextStyle(color: AppColors.error),
                    ),
                    subtitle: Text('admin.reset_table_desc'.tr()),
                    enabled: table.rowCount > 0,
                    onTap: () {
                      Navigator.pop(ctx);
                      _resetTable(context, ref);
                    },
                  )
                else
                  ListTile(
                    leading: AppIcon(
                      AppIcons.security,
                      color: AppColors.warning.withValues(alpha: 0.5),
                    ),
                    title: Text(
                      'admin.reset_table'.tr(),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.38,
                        ),
                      ),
                    ),
                    subtitle: Text('admin.protected_table_desc'.tr()),
                    enabled: false,
                  ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _backupTable(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(adminActionsProvider.notifier);
    final jsonStr = await notifier.exportTable(table.name);
    if (jsonStr != null && context.mounted) {
      await saveBackupFile(context, table.name, jsonStr);
    }
  }

  Future<void> _resetTable(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.reset_table_title'.tr(args: [table.name]),
      message: 'admin.reset_table_confirm'.tr(args: ['${table.rowCount}']),
      isDestructive: true,
    );
    if (confirmed != true) return;

    final notifier = ref.read(adminActionsProvider.notifier);
    final success = await notifier.resetTable(table.name);

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
