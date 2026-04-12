import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../domain/services/sync/sync_providers.dart';
import '../providers/settings_providers.dart';

/// Shows the conflict history dialog.
void showConflictHistoryDialog(
  BuildContext context,
  WidgetRef ref,
  List<SyncConflict> conflicts,
) {
  final theme = Theme.of(context);
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('sync.conflict_history'.tr()),
      content: SizedBox(
        width: double.maxFinite,
        child: conflicts.isEmpty
            ? Text('sync.no_conflicts'.tr())
            : ListView.separated(
                shrinkWrap: true,
                itemCount: conflicts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final c = conflicts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.description, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 2),
                        Text(
                          '${c.table} — ${formatTimeSince(c.detectedAt)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(conflictHistoryProvider.notifier).clear();
            Navigator.of(context).pop();
          },
          child: Text('common.delete'.tr()),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common.close'.tr()),
        ),
      ],
    ),
  );
}

/// Shows the storage info dialog with database, cache, and image sizes.
void showStorageInfoDialog(BuildContext context) {
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (_) => Consumer(
      builder: (ctx, dialogRef, _) {
        final cacheSizeAsync = dialogRef.watch(cacheSizeProvider);
        final databaseSizeAsync = dialogRef.watch(databaseSizeProvider);
        final imageSizeAsync = dialogRef.watch(imageStorageSizeProvider);
        final cacheText = cacheSizeAsync.when(
          data: (bytes) => formatBytes(bytes),
          loading: () => 'settings.storage_calculating'.tr(),
          error: (_, __) => '-',
        );
        final dbText = databaseSizeAsync.when(
          data: (bytes) => formatBytes(bytes),
          loading: () => 'settings.storage_calculating'.tr(),
          error: (_, __) => '-',
        );
        final imageText = imageSizeAsync.when(
          data: (bytes) => formatBytes(bytes),
          loading: () => 'settings.storage_calculating'.tr(),
          error: (_, __) => '-',
        );

        return AlertDialog(
          title: Text('settings.storage_info'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StorageInfoRow(
                label: 'settings.storage_database'.tr(),
                value: dbText,
                icon: AppIcon(
                  AppIcons.database,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                theme: theme,
              ),
              const Divider(height: 1),
              StorageInfoRow(
                label: 'settings.storage_cache'.tr(),
                value: cacheText,
                icon: Icon(
                  LucideIcons.hardDrive,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                theme: theme,
              ),
              const Divider(height: 1),
              StorageInfoRow(
                label: 'settings.storage_images'.tr(),
                value: imageText,
                icon: AppIcon(
                  AppIcons.photo,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                theme: theme,
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('common.close'.tr()),
            ),
          ],
        );
      },
    ),
  );
}

/// A single row in the storage info dialog.
class StorageInfoRow extends StatelessWidget {
  const StorageInfoRow({
    super.key,
    required this.label,
    required this.icon,
    required this.theme,
    this.value,
  });

  final String label;
  final String? value;
  final Widget icon;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          icon,
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value ?? 'settings.storage_calculating'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats byte count into a human-readable string.
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Formats time difference as a localized relative string.
String formatTimeSince(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'common.just_now'.tr();
  if (diff.inMinutes < 60) {
    return 'common.minutes_ago'.tr(args: [diff.inMinutes.toString()]);
  }
  if (diff.inHours < 24) {
    return 'common.hours_ago'.tr(args: [diff.inHours.toString()]);
  }
  return 'common.days_ago'.tr(args: [diff.inDays.toString()]);
}
