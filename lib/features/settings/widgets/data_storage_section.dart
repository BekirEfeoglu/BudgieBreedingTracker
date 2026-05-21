import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../domain/services/sync/sync_orchestrator.dart';
import '../../../domain/services/sync/sync_providers.dart';
import '../../../router/route_names.dart';
import '../providers/settings_providers.dart';
import 'package:budgie_breeding_tracker/core/providers/action_feedback_providers.dart';
import 'data_storage_dialogs.dart';
import 'settings_action_tile.dart';
import 'settings_navigation_tile.dart';
import 'settings_section_header.dart';
import 'settings_toggle_tile.dart';
import 'sync_detail_sheet.dart';

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
    final backgroundSync = ref.watch(syncBackgroundEnabledProvider);
    final realtimeSync = ref.watch(syncRealtimeEnabledProvider);
    final cacheSizeAsync = ref.watch(cacheSizeProvider);
    final lastSyncTime = ref.watch(lastSyncTimeProvider);
    final conflicts = ref.watch(conflictHistoryProvider);
    final userId = ref.watch(currentUserIdProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider).value ?? 0;
    final staleWarningCount =
        ref.watch(pendingDeletionSyncErrorsProvider).value?.length ?? 0;
    final errorCount =
        ref
            .watch(syncErrorDetailsProvider(userId))
            .value
            ?.fold<int>(0, (sum, d) => sum + d.errorCount) ??
        0;

    final cacheSizeText = cacheSizeAsync.when(
      data: (bytes) => formatBytes(bytes),
      loading: () => '...',
      error: (_, __) => '-',
    );

    final syncSubtitle = lastSyncTime != null
        ? 'settings.last_synced_at'.tr(args: [formatTimeSince(lastSyncTime)])
        : 'settings.sync_with_server_desc'.tr();
    final syncStatusSubtitle = [
      syncSubtitle,
      'settings.pending_sync_count'.tr(args: ['$pendingCount']),
      'settings.sync_error_count'.tr(args: ['$errorCount']),
    ].join(' · ');

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
        SettingsToggleTile(
          title: 'settings.background_sync'.tr(),
          subtitle: 'settings.background_sync_desc'.tr(),
          icon: const Icon(LucideIcons.refreshCw),
          value: backgroundSync,
          onChanged: (enabled) {
            ref
                .read(syncBackgroundEnabledProvider.notifier)
                .setEnabled(enabled);
          },
        ),
        SettingsToggleTile(
          title: 'settings.realtime_sync'.tr(),
          subtitle: 'settings.realtime_sync_desc'.tr(),
          icon: const Icon(LucideIcons.radio),
          value: realtimeSync,
          onChanged: (enabled) {
            ref.read(syncRealtimeEnabledProvider.notifier).setEnabled(enabled);
          },
        ),
        SettingsActionTile(
          key: DataStorageSection.syncActionKey,
          title: 'settings.sync_with_server'.tr(),
          subtitle: syncStatusSubtitle,
          icon: const AppIcon(AppIcons.sync),
          isLoading: _isSyncing,
          onTap: _syncWithServer,
        ),
        SettingsActionTile(
          title: 'settings.sync_health_report'.tr(),
          subtitle: _syncHealthSubtitle(
            pendingCount: pendingCount,
            errorCount: errorCount,
            staleWarningCount: staleWarningCount,
            conflictCount: conflicts.length,
            backgroundSync: backgroundSync,
            realtimeSync: realtimeSync,
          ),
          icon: const Icon(LucideIcons.activity),
          onTap: () => showSyncDetailSheet(context),
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

  String _syncHealthSubtitle({
    required int pendingCount,
    required int errorCount,
    required int staleWarningCount,
    required int conflictCount,
    required bool backgroundSync,
    required bool realtimeSync,
  }) {
    final backgroundState = backgroundSync
        ? 'settings.sync_state_on'.tr()
        : 'settings.sync_state_off'.tr();
    final realtimeState = realtimeSync
        ? 'settings.sync_state_on'.tr()
        : 'settings.sync_state_off'.tr();

    return [
      'settings.pending_sync_count'.tr(args: ['$pendingCount']),
      'settings.sync_error_count'.tr(args: ['$errorCount']),
      'settings.sync_stale_warning_count'.tr(args: ['$staleWarningCount']),
      'settings.sync_conflict_count'.tr(args: ['$conflictCount']),
      '${'settings.background_sync'.tr()}: $backgroundState',
      '${'settings.realtime_sync'.tr()}: $realtimeState',
    ].join(' · ');
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
    } catch (e, st) {
      AppLogger.error('[DataStorageSection] sync failed', e, st);
      Sentry.captureException(e, stackTrace: st);
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
