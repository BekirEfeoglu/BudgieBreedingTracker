import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/sync_conflict.dart';
import '../theme/app_spacing.dart';

/// Bottom sheet displaying conflict resolution history.
class SyncConflictSheet extends StatelessWidget {
  final List<SyncConflict> conflicts;
  const SyncConflictSheet({super.key, required this.conflicts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'sync.conflict_history'.tr(),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (conflicts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                'sync.no_conflicts'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: conflicts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final conflict = conflicts[index];
                  return SyncConflictTile(conflict: conflict);
                },
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

/// A single conflict entry in the conflict history list.
class SyncConflictTile extends StatelessWidget {
  final SyncConflict conflict;
  const SyncConflictTile({super.key, required this.conflict});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = DateTime.now().difference(conflict.detectedAt);
    final timeAgo = diff.inMinutes < 1
        ? 'profile.just_now'.tr()
        : diff.inMinutes < 60
            ? 'profile.minutes_ago'.tr(args: ['${diff.inMinutes}'])
            : 'profile.hours_ago'.tr(args: ['${diff.inHours}']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            Icons.sync_problem,
            size: 18,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'sync.conflict_overwritten'.tr(
                    args: [_tableDisplayName(conflict.table)],
                  ),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  conflict.description,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            timeAgo,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _tableDisplayName(String table) => switch (table) {
    'birds' => 'birds.title'.tr(),
    'breeding_pairs' => 'breeding.title'.tr(),
    'eggs' => 'eggs.management'.tr(),
    'chicks' => 'chicks.title'.tr(),
    'nests' => 'breeding.title'.tr(),
    'clutches' => 'breeding.title'.tr(),
    'events' => 'calendar.title'.tr(),
    'health_records' => 'health_records.title'.tr(),
    'event_reminders' => 'calendar.title'.tr(),
    'notification_schedules' => 'notifications.title'.tr(),
    _ => table,
  };
}
