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
                    'admin.soft_delete_cleanup'.tr(),
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
                            '$d ${'admin.days_label'.tr()}',
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
        'admin.no_soft_deleted'.tr(),
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
            label: Text('admin.clean_soft_deleted'.tr()),
          ),
        ),
      ],
    );
  }

  Future<void> _cleanOldRecords(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.clean_soft_deleted'.tr(),
      message: 'admin.clean_soft_deleted_confirm'.tr(),
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
