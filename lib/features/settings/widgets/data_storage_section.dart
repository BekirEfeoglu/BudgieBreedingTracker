import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../domain/services/sync/sync_orchestrator.dart';
import '../../../domain/services/sync/sync_providers.dart';
import '../../../router/route_names.dart';
import '../providers/settings_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';
import 'data_storage_dialogs.dart';
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
      data: (bytes) => formatBytes(bytes),
      loading: () => '...',
      error: (_, __) => '-',
    );

    final syncSubtitle = lastSyncTime != null
        ? 'settings.last_synced_at'.tr(args: [formatTimeSince(lastSyncTime)])
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
            onTap: () => showConflictHistoryDialog(context, ref, conflicts),
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
          onTap: () => showStorageInfoDialog(context),
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
        if (result == SyncResult.success) {
          ActionFeedbackService.show('settings.sync_success'.tr());
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('settings.sync_error'.tr())));
        }
      }
    } catch (e) {
      Sentry.captureException(e, stackTrace: StackTrace.current);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('settings.sync_error'.tr())));
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
        ActionFeedbackService.show('settings.cache_cleared'.tr());
      }
    } finally {
      if (mounted) setState(() => _isClearingCache = false);
    }
  }
}
