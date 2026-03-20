import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../domain/services/sync/network_status_provider.dart';
import '../../../domain/services/sync/sync_orchestrator.dart';
import '../../../domain/services/sync/sync_providers.dart';
import '../../../router/route_names.dart';
import '../providers/settings_providers.dart';
import 'settings_action_tile.dart';
import 'settings_navigation_tile.dart';
import 'settings_section_header.dart';
import 'settings_toggle_tile.dart';

class DataStorageSection extends ConsumerStatefulWidget {
  const DataStorageSection({super.key});

  static const syncActionKey = Key('data_storage_sync_action');
  static const cacheActionKey = Key('data_storage_cache_action');

  @override
  ConsumerState<DataStorageSection> createState() => _DataStorageSectionState();
}

class _DataStorageSectionState extends ConsumerState<DataStorageSection> {
  bool _isClearingCache = false;
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final autoSync = ref.watch(autoSyncProvider);
    final wifiOnlySync = ref.watch(wifiOnlySyncProvider);
    final cacheSizeAsync = ref.watch(cacheSizeProvider);
    final lastSyncTime = ref.watch(lastSyncTimeProvider);
    final conflicts = ref.watch(conflictHistoryProvider);

    final cacheSizeText = cacheSizeAsync.when(
      data: (bytes) => _formatBytes(bytes),
      loading: () => '...',
      error: (_, __) => '-',
    );

    final syncSubtitle = lastSyncTime != null
        ? 'settings.last_synced_at'.tr(args: [_formatTimeSince(lastSyncTime)])
        : 'settings.sync_with_server_desc'.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(
          title: 'settings.data_storage'.tr(),
          icon: const AppIcon(AppIcons.backup),
        ),
        SettingsNavigationTile(
          title: 'settings.backup_export'.tr(),
          subtitle: 'settings.backup_export_desc'.tr(),
          icon: const AppIcon(AppIcons.backup),
          onTap: () => context.push(AppRoutes.backup),
        ),
        SettingsToggleTile(
          title: 'settings.auto_sync'.tr(),
          subtitle: 'settings.auto_sync_desc'.tr(),
          icon: const AppIcon(AppIcons.sync),
          value: autoSync,
          onChanged: (_) {
            ref.read(autoSyncProvider.notifier).toggle();
          },
        ),
        SettingsToggleTile(
          title: 'settings.wifi_only_sync'.tr(),
          subtitle: 'settings.wifi_only_sync_desc'.tr(),
          icon: const Icon(LucideIcons.wifi),
          value: wifiOnlySync,
          onChanged: (_) {
            ref.read(wifiOnlySyncProvider.notifier).toggle();
          },
        ),
        SettingsActionTile(
          key: DataStorageSection.syncActionKey,
          title: 'settings.sync_with_server'.tr(),
          subtitle: syncSubtitle,
          icon: const AppIcon(AppIcons.sync),
          isLoading: _isSyncing,
          onTap: _syncWithServer,
        ),
        if (conflicts.isNotEmpty)
          SettingsActionTile(
            title: 'sync.conflict_history'.tr(),
            subtitle: 'sync.conflict_detected'.tr(
              args: ['${conflicts.length}'],
            ),
            icon: const Icon(LucideIcons.gitMerge),
            onTap: () => _showConflictHistoryDialog(context, conflicts),
          ),
        SettingsActionTile(
          key: DataStorageSection.cacheActionKey,
          title: 'settings.clear_cache'.tr(),
          subtitle: 'settings.cache_size'.tr(args: [cacheSizeText]),
          icon: const Icon(LucideIcons.paintbrush),
          isLoading: _isClearingCache,
          onTap: _clearCache,
        ),
        SettingsNavigationTile(
          title: 'settings.storage_info'.tr(),
          subtitle: 'settings.storage_info_desc'.tr(),
          icon: const AppIcon(AppIcons.database),
          onTap: () => _showStorageInfoDialog(context),
        ),
        if (kDebugMode)
          SettingsToggleTile(
            title: 'settings.debug_offline_mode'.tr(),
            subtitle: 'settings.debug_offline_desc'.tr(),
            icon: const Icon(LucideIcons.wifiOff),
            value: ref.watch(debugOfflineModeProvider),
            onChanged: (_) {
              ref.read(debugOfflineModeProvider.notifier).state = !ref.read(
                debugOfflineModeProvider,
              );
            },
          ),
      ],
    );
  }

  Future<void> _syncWithServer() async {
    setState(() => _isSyncing = true);
    try {
      final orchestrator = ref.read(syncOrchestratorProvider);
      final result = await orchestrator.forceFullSync();
      if (mounted) {
        final message = result == SyncResult.success
            ? 'settings.sync_success'.tr()
            : 'settings.sync_error'.tr();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _clearCache() async {
    setState(() => _isClearingCache = true);
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list(
          recursive: false,
          followLinks: false,
        )) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (_) {
            // Skip files that can't be deleted
          }
        }
      }
      ref.invalidate(cacheSizeProvider);
      ref.invalidate(imageStorageSizeProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('settings.cache_cleared'.tr())));
      }
    } finally {
      if (mounted) setState(() => _isClearingCache = false);
    }
  }

  void _showConflictHistoryDialog(
    BuildContext context,
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
                            '${c.table} — ${_formatTimeSince(c.detectedAt)}',
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

  void _showStorageInfoDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) => Consumer(
        builder: (ctx, dialogRef, _) {
          final cacheSizeAsync = dialogRef.watch(cacheSizeProvider);
          final databaseSizeAsync = dialogRef.watch(databaseSizeProvider);
          final imageSizeAsync = dialogRef.watch(imageStorageSizeProvider);
          final cacheText = cacheSizeAsync.when(
            data: (bytes) => _formatBytes(bytes),
            loading: () => 'settings.storage_calculating'.tr(),
            error: (_, __) => '-',
          );
          final dbText = databaseSizeAsync.when(
            data: (bytes) => _formatBytes(bytes),
            loading: () => 'settings.storage_calculating'.tr(),
            error: (_, __) => '-',
          );
          final imageText = imageSizeAsync.when(
            data: (bytes) => _formatBytes(bytes),
            loading: () => 'settings.storage_calculating'.tr(),
            error: (_, __) => '-',
          );

          return AlertDialog(
            title: Text('settings.storage_info'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StorageInfoRow(
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
                _StorageInfoRow(
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
                _StorageInfoRow(
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatTimeSince(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'settings.just_now'.tr();
    if (diff.inMinutes < 60) {
      return 'settings.minutes_ago'.tr(args: [diff.inMinutes.toString()]);
    }
    if (diff.inHours < 24) {
      return 'settings.hours_ago'.tr(args: [diff.inHours.toString()]);
    }
    return 'settings.days_ago'.tr(args: [diff.inDays.toString()]);
  }
}

class _StorageInfoRow extends StatelessWidget {
  const _StorageInfoRow({
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
