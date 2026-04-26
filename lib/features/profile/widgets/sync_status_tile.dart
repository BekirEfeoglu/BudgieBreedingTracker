import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../domain/services/sync/sync_orchestrator.dart';
import '../../../domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/shared/widgets/sync_detail_sheet.dart';

/// Displays current sync status with last sync time, pending count,
/// stale error warning, and manual sync button.
class SyncStatusTile extends ConsumerWidget {
  const SyncStatusTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final lastSync = ref.watch(lastSyncTimeProvider);
    final isSyncing = ref.watch(isSyncingProvider);
    final pendingAsync = ref.watch(pendingSyncCountProvider);
    final staleAsync = ref.watch(staleErrorCountProvider);
    final theme = Theme.of(context);

    final pendingCount = pendingAsync.value ?? 0;
    final staleCount = staleAsync.value ?? 0;

    return GestureDetector(
      onTap: () => showSyncDetailSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        child: Row(
          children: [
            IconTheme(
              data: IconThemeData(size: 22, color: _statusColor(syncStatus)),
              child: const AppIcon(AppIcons.sync),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'profile.sync_status'.tr(),
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusSubtitle(syncStatus, lastSync, pendingCount, ref),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _statusColor(syncStatus),
                    ),
                  ),
                  if (staleCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'sync.stale_errors'.tr(args: ['$staleCount']),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSyncing)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                onPressed: () => _triggerSync(ref),
                icon: const AppIcon(AppIcons.sync, size: 18),
                tooltip: 'profile.sync_now'.tr(),
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.touchTargetMin,
                  minHeight: AppSpacing.touchTargetMin,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(SyncDisplayStatus status) => switch (status) {
    SyncDisplayStatus.synced => AppColors.success,
    SyncDisplayStatus.syncing => AppColors.warning,
    SyncDisplayStatus.offline => AppColors.neutral500,
    SyncDisplayStatus.error => AppColors.error,
  };

  String _statusSubtitle(
    SyncDisplayStatus status,
    DateTime? lastSync,
    int pendingCount,
    WidgetRef ref,
  ) {
    final pendingSuffix = pendingCount > 0
        ? ' — ${pendingCount == 1 ? 'sync.pending_one'.tr() : 'sync.pending_count'.tr(args: ['$pendingCount'])}'
        : '';

    if (status == SyncDisplayStatus.syncing) {
      return 'sync.syncing'.tr() + pendingSuffix;
    }
    if (status == SyncDisplayStatus.offline) {
      return 'sync.offline'.tr() + pendingSuffix;
    }
    if (status == SyncDisplayStatus.error) {
      final userId = ref.watch(currentUserIdProvider);
      final errorDetails = ref.watch(syncErrorDetailsProvider(userId));
      final totalErrors =
          errorDetails.value?.fold<int>(0, (sum, d) => sum + d.errorCount) ?? 0;
      if (totalErrors > 0) {
        return 'sync.error_count_summary'.tr(args: ['$totalErrors']) +
            pendingSuffix;
      }
      return 'profile.sync_error'.tr() + pendingSuffix;
    }
    if (lastSync == null) return 'profile.sync_never'.tr();
    return '${'profile.last_synced'.tr()}: ${_relativeTime(lastSync)}$pendingSuffix';
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'common.just_now'.tr();
    if (diff.inMinutes < 60) {
      return 'common.minutes_ago'.tr(args: ['${diff.inMinutes}']);
    }
    if (diff.inHours < 24) {
      return 'common.hours_ago'.tr(args: ['${diff.inHours}']);
    }
    return 'common.days_ago'.tr(args: ['${diff.inDays}']);
  }

  Future<void> _triggerSync(WidgetRef ref) async {
    AppHaptics.lightImpact();
    final orchestrator = ref.read(syncOrchestratorProvider);
    final result = await orchestrator.forceFullSync();
    if (result == SyncResult.success) {
      AppHaptics.mediumImpact();
      ref.read(syncErrorProvider.notifier).state = false;
    }
  }
}
