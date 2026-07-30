import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/providers/action_feedback_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/local/database/daos/sync_metadata_dao.dart'
    show SyncErrorDetail;
import '../../../data/providers/auth_state_providers.dart';
import '../../../domain/services/sync/sync_orchestrator.dart';
import '../../../domain/services/sync/sync_providers.dart';
import '../../../domain/services/sync/sync_telemetry.dart';
import 'data_storage_dialogs.dart'
    show clearConflictHistory, confirmClearConflictHistory, formatTimeSince;

part 'sync_detail_sheet_sections.dart';

/// Shows the sync detail bottom sheet.
void showSyncDetailSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (_) => const SyncDetailSheet(),
  );
}

/// Bottom sheet displaying sync details: pending records, failed records,
/// and conflict history with actions to sync now or clear history.
class SyncDetailSheet extends ConsumerWidget {
  const SyncDetailSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = ref.watch(currentUserIdProvider);
    final pendingAsync = ref.watch(pendingByTableProvider(userId));
    final errorsAsync = ref.watch(syncErrorDetailsProvider(userId));
    final conflicts = ref.watch(conflictHistoryProvider);

    // A failed metadata query must not render as a green "all healthy"
    // state — surface it explicitly instead of treating error as empty.
    final hasLoadError = pendingAsync.hasError || errorsAsync.hasError;
    final isLoading =
        (pendingAsync.isLoading && !pendingAsync.hasValue) ||
        (errorsAsync.isLoading && !errorsAsync.hasValue);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            _SheetHeader(theme: theme),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasLoadError)
                      _LoadErrorState(theme: theme)
                    else if (isLoading)
                      const _LoadingState()
                    else ...[
                      _PendingSection(pendingAsync: pendingAsync, theme: theme),
                      _FailedSection(errorsAsync: errorsAsync, theme: theme),
                    ],
                    _ConflictSection(conflicts: conflicts, theme: theme),
                    if (!hasLoadError &&
                        !isLoading &&
                        _isEmpty(pendingAsync, errorsAsync, conflicts))
                      _EmptyState(theme: theme),
                    const SizedBox(height: AppSpacing.lg),
                    _ActionButtons(
                      hasConflicts: conflicts.isNotEmpty,
                      hasUnresolvedConflicts: conflicts.any(
                        (conflict) => conflict.resolvedAt == null,
                      ),
                      userId: userId,
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isEmpty(
    AsyncValue<List<SyncErrorDetail>> pendingAsync,
    AsyncValue<List<SyncErrorDetail>> errorsAsync,
    List<SyncConflict> conflicts,
  ) {
    final pendingEmpty = pendingAsync.value?.isEmpty ?? true;
    final errorsEmpty = errorsAsync.value?.isEmpty ?? true;
    return pendingEmpty && errorsEmpty && conflicts.isEmpty;
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'sync.error_details_title'.tr(),
              style: theme.textTheme.titleLarge,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.x),
            tooltip: 'common.close'.tr(),
            constraints: const BoxConstraints(
              minWidth: AppSpacing.touchTargetMd,
              minHeight: AppSpacing.touchTargetMd,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends ConsumerStatefulWidget {
  const _ActionButtons({
    required this.hasConflicts,
    required this.hasUnresolvedConflicts,
    required this.userId,
  });

  final bool hasConflicts;
  final bool hasUnresolvedConflicts;
  final String userId;

  @override
  ConsumerState<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends ConsumerState<_ActionButtons> {
  bool _busy = false;

  /// Runs [action] with a double-tap guard and shared error handling.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e, st) {
      AppLogger.error('[SyncDetailSheet] action failed', e, st);
      await Sentry.captureException(e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('settings.sync_error'.tr())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncNow() => _run(() async {
    final orchestrator = ref.read(syncOrchestratorProvider);
    final result = await orchestrator.forceFullSync();
    if (result == SyncResult.success) {
      ref.read(syncErrorProvider.notifier).state = false;
      if (mounted) Navigator.of(context).pop();
      ActionFeedbackService.show('settings.sync_success'.tr());
    } else if (mounted) {
      // Keep the sheet open on failure so the details stay visible.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('settings.sync_error'.tr())));
    }
  });

  Future<void> _keepRemote() => _run(() async {
    final recovery = ref.read(syncConflictRecoveryServiceProvider);
    final resolved = await recovery.keepRemote(widget.userId);
    await ref.read(conflictHistoryProvider.notifier).reload();
    SyncTelemetry.event(
      'conflict_resolved',
      data: {'strategy': 'remote', 'resolved': resolved},
    );
    if (mounted) Navigator.of(context).pop();
  });

  Future<void> _retryLocal() => _run(() async {
    final recovery = ref.read(syncConflictRecoveryServiceProvider);
    final retry = await recovery.retryLocal(widget.userId);

    SyncResult? syncResult;
    var restoredRecordsSynced = false;
    if (retry.restored > 0) {
      syncResult = await ref.read(syncOrchestratorProvider).fullSync();
      restoredRecordsSynced = await recovery.areRestoredRecordsSynced(
        retry.restoredRecords,
      );
    }
    // Pull can create a new conflict for the same record when its restored
    // metadata remains queued, so refresh only after the entire sync attempt.
    await ref.read(conflictHistoryProvider.notifier).reload();
    SyncTelemetry.event(
      'conflict_resolved',
      data: {
        'strategy': 'local_retry',
        'restored': retry.restored,
        'unavailable': retry.unavailable,
        'failed': retry.failed,
        'restoredRecordsSynced': restoredRecordsSynced,
      },
    );
    if (!mounted) return;

    final messageKey = switch ((
      retry.restored,
      retry.unavailable,
      retry.failed,
      syncResult,
      restoredRecordsSynced,
    )) {
      (> 0, 0, 0, SyncResult.success, true) => 'sync.retry_local_success',
      (0, > 0, 0, _, _) => 'sync.retry_local_unavailable',
      (0, _, > 0, _, _) => 'sync.retry_local_failed',
      (> 0, 0, 0, _, false) => 'sync.retry_local_queued',
      _ => 'sync.retry_local_partial',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(messageKey.tr())));
    if (messageKey == 'sync.retry_local_success') {
      Navigator.of(context).pop();
    }
  });

  Future<void> _clearHistory() async {
    final confirmed = await confirmClearConflictHistory(context);
    if (confirmed != true || !mounted) return;
    await _run(() => clearConflictHistory(ref, widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: _busy ? null : _syncNow,
          icon: const AppIcon(AppIcons.sync, size: 18),
          label: Text('sync.sync_now_action'.tr()),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.touchTargetMd),
          ),
        ),
        if (widget.hasConflicts) ...[
          if (widget.hasUnresolvedConflicts) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _busy ? null : _keepRemote,
              icon: const Icon(LucideIcons.cloud, size: 18),
              label: Text('sync.keep_remote_action'.tr()),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpacing.touchTargetMd),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _busy ? null : _retryLocal,
              icon: const Icon(LucideIcons.uploadCloud, size: 18),
              label: Text('sync.retry_local_action'.tr()),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpacing.touchTargetMd),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          OutlinedButton.icon(
            onPressed: _busy ? null : _clearHistory,
            icon: const Icon(LucideIcons.trash2, size: 18),
            label: Text('sync.clear_conflict_history'.tr()),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.touchTargetMd),
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

/// Localizes a Supabase table name to a user-friendly translated string.
String _localizeTable(String table) => switch (table) {
  SupabaseConstants.birdsTable => 'sync.table_birds'.tr(),
  SupabaseConstants.eggsTable => 'sync.table_eggs'.tr(),
  SupabaseConstants.chicksTable => 'sync.table_chicks'.tr(),
  SupabaseConstants.breedingPairsTable => 'sync.table_breeding_pairs'.tr(),
  SupabaseConstants.clutchesTable => 'sync.table_clutches'.tr(),
  SupabaseConstants.nestsTable => 'sync.table_nests'.tr(),
  SupabaseConstants.healthRecordsTable => 'sync.table_health_records'.tr(),
  SupabaseConstants.eventsTable => 'sync.table_events'.tr(),
  _ => 'sync.table_other'.tr(),
};
