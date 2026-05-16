import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_conflict_providers.dart';
import 'package:budgie_breeding_tracker/shared/widgets/sync_detail_sheet.dart';

/// Compact, accessible badge for records with a persisted sync conflict.
class SyncConflictBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const SyncConflictBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = 'sync.conflict_badge'.tr();
    final badge = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.alertTriangle, size: 14, color: colorScheme.error),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      label: label,
      child: onTap == null
          ? badge
          : InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              onTap: onTap,
              child: badge,
            ),
    );
  }
}

/// Watches sync conflict history for a specific record and renders a compact
/// badge only when a conflict exists.
class RecordSyncConflictBadge extends StatelessWidget {
  final String tableName;
  final String recordId;

  const RecordSyncConflictBadge({
    super.key,
    required this.tableName,
    required this.recordId,
  });

  @override
  Widget build(BuildContext context) {
    if (recordId.isEmpty) return const SizedBox.shrink();

    try {
      ProviderScope.containerOf(context, listen: false);
      // ignore: avoid_catching_errors, harmless optional widget guard
    } on StateError {
      return const SizedBox.shrink();
    }

    return Consumer(
      builder: (context, ref, _) {
        final userId = ref.watch(currentUserIdProvider);
        if (userId.isEmpty) return const SizedBox.shrink();

        final hasConflict = ref
            .watch(
              conflictExistsForRecordProvider((
                userId: userId,
                table: tableName,
                recordId: recordId,
              )),
            )
            .asData
            ?.value;

        if (hasConflict != true) return const SizedBox.shrink();

        return SyncConflictBadge(onTap: () => showSyncDetailSheet(context));
      },
    );
  }
}
