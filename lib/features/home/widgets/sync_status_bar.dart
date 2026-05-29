import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/shared/widgets/sync_detail_sheet.dart';

class SyncStatusBar extends ConsumerStatefulWidget {
  const SyncStatusBar({super.key});

  @override
  ConsumerState<SyncStatusBar> createState() => _SyncStatusBarState();
}

class _SyncStatusBarState extends ConsumerState<SyncStatusBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // Seed the spinner once after the first frame so it matches the initial
    // sync status without driving the controller from inside build().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyRotation(ref.read(syncStatusProvider));
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  /// Start/stop the rotation to match the current sync status. Called only on
  /// state transitions (ref.listen) and the initial post-frame seed — never on
  /// every build, so we don't re-trigger repeat()/stop() unnecessarily.
  void _applyRotation(SyncDisplayStatus status) {
    if (status == SyncDisplayStatus.syncing) {
      if (!_rotationController.isAnimating) _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
  }

  String _errorLabel(String userId) {
    final total = ref.watch(
      syncErrorDetailsProvider(userId).select(
        (details) =>
            details.value?.fold<int>(0, (sum, d) => sum + d.errorCount) ?? 0,
      ),
    );
    if (total > 0) return 'sync.error_count_summary'.tr(args: ['$total']);
    return 'sync.sync_error'.tr();
  }

  @override
  Widget build(BuildContext context) {
    // Drive the rotation animation from state transitions only — the listener
    // fires when the status changes, not on every rebuild.
    ref.listen<SyncDisplayStatus>(syncStatusProvider, (prev, next) {
      _applyRotation(next);
    });

    final status = ref.watch(syncStatusProvider);
    final userId = ref.watch(currentUserIdProvider);
    // Count of conflicts detected within the last 24h. Non-zero means at
    // least one local change was overridden by the server-wins resolution
    // — surface it so the user can open the detail sheet.
    final recentConflictCount = ref.watch(
      persistedConflictCountProvider(
        userId,
      ).select((count) => count.asData?.value ?? 0),
    );

    final colorScheme = Theme.of(context).colorScheme;

    final (Widget icon, Color color, String label) = switch (status) {
      SyncDisplayStatus.synced => (
        Icon(LucideIcons.cloud, size: 14, color: colorScheme.primary),
        colorScheme.primary,
        'sync.synced'.tr(),
      ),
      SyncDisplayStatus.syncing => (
        AppIcon(AppIcons.sync, size: 14, color: colorScheme.tertiary),
        colorScheme.tertiary,
        'sync.syncing'.tr(),
      ),
      SyncDisplayStatus.offline => (
        AppIcon(AppIcons.offline, size: 14, color: colorScheme.error),
        colorScheme.error,
        'sync.offline'.tr(),
      ),
      SyncDisplayStatus.error => (
        AppIcon(AppIcons.offline, size: 14, color: colorScheme.error),
        colorScheme.error,
        _errorLabel(userId),
      ),
    };

    final theme = Theme.of(context);

    return Semantics(
      label: label,
      button: status != SyncDisplayStatus.syncing,
      child: GestureDetector(
        onTap: () {
          // Any tap while there are recent conflicts routes to the detail
          // sheet so the user can review them — otherwise keep the existing
          // tap-to-sync / tap-to-see-errors behavior.
          if (recentConflictCount > 0 || status == SyncDisplayStatus.error) {
            showSyncDetailSheet(context);
          } else if (status != SyncDisplayStatus.syncing) {
            final orchestrator = ref.read(syncOrchestratorProvider);
            orchestrator.fullSync();
          }
        },
        child: Container(
          width: double.infinity,
          // 48dp minimum tap target (WCAG 2.5.5). The visual band stays
          // compact via Row alignment; only the hit area grows.
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          color: color.withValues(alpha: 0.12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              status == SyncDisplayStatus.syncing
                  ? RotationTransition(turns: _rotationController, child: icon)
                  : icon,
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              if (recentConflictCount > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                _ConflictChip(count: recentConflictCount),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small inline badge shown on [SyncStatusBar] when recent conflicts exist.
class _ConflictChip extends StatelessWidget {
  const _ConflictChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        'sync.conflict_detected'.tr(args: ['$count']),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onErrorContainer,
        ),
      ),
    );
  }
}
