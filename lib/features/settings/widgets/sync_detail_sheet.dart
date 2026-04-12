import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/local/database/dao_providers.dart';
import '../../../data/local/database/daos/sync_metadata_dao.dart'
    show SyncErrorDetail;
import '../../../data/providers/auth_state_providers.dart';
import '../../../domain/services/sync/sync_orchestrator.dart';
import '../../../domain/services/sync/sync_providers.dart';
import 'data_storage_dialogs.dart' show formatTimeSince;

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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PendingSection(pendingAsync: pendingAsync, theme: theme),
                    _FailedSection(errorsAsync: errorsAsync, theme: theme),
                    _ConflictSection(conflicts: conflicts, theme: theme),
                    if (_isEmpty(pendingAsync, errorsAsync, conflicts))
                      _EmptyState(theme: theme),
                    const SizedBox(height: AppSpacing.lg),
                    _ActionButtons(
                      hasConflicts: conflicts.isNotEmpty,
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
              minWidth: AppSpacing.touchTargetMin,
              minHeight: AppSpacing.touchTargetMin,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({
    required this.hasConflicts,
    required this.userId,
  });

  final bool hasConflicts;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () async {
            final orchestrator = ref.read(syncOrchestratorProvider);
            final result = await orchestrator.forceFullSync();
            if (result == SyncResult.success) {
              ref.read(syncErrorProvider.notifier).state = false;
            }
            if (context.mounted) Navigator.of(context).pop();
          },
          icon: const AppIcon(AppIcons.sync, size: 18),
          label: Text('sync.sync_now_action'.tr()),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
          ),
        ),
        if (hasConflicts) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(conflictHistoryDaoProvider).deleteAll(userId);
              ref.read(conflictHistoryProvider.notifier).clear();
            },
            icon: const Icon(LucideIcons.trash2, size: 18),
            label: Text('sync.clear_conflict_history'.tr()),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
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
      'birds' => 'sync.table_birds'.tr(),
      'eggs' => 'sync.table_eggs'.tr(),
      'chicks' => 'sync.table_chicks'.tr(),
      'breeding_pairs' => 'sync.table_breeding_pairs'.tr(),
      'clutches' => 'sync.table_clutches'.tr(),
      'nests' => 'sync.table_nests'.tr(),
      'health_records' => 'sync.table_health_records'.tr(),
      'events' => 'sync.table_events'.tr(),
      _ => 'sync.table_other'.tr(),
    };
