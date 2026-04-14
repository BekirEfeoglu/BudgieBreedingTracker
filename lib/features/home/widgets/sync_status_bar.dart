import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/sync_detail_sheet.dart'; // Cross-feature import: home↔settings sync status display

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
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  String _errorLabel() {
    final userId = ref.watch(currentUserIdProvider);
    final details = ref.watch(syncErrorDetailsProvider(userId));
    final total =
        details.value?.fold<int>(0, (sum, d) => sum + d.errorCount) ?? 0;
    if (total > 0) return 'sync.error_count_summary'.tr(args: ['$total']);
    return 'sync.sync_error'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(syncStatusProvider);

    if (status == SyncDisplayStatus.syncing) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }

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
        _errorLabel(),
      ),
    };

    final theme = Theme.of(context);

    return Semantics(
      label: label,
      button: status != SyncDisplayStatus.syncing,
      child: GestureDetector(
        onTap: () {
          if (status == SyncDisplayStatus.error) {
            showSyncDetailSheet(context);
          } else if (status != SyncDisplayStatus.syncing) {
            final orchestrator = ref.read(syncOrchestratorProvider);
            orchestrator.fullSync();
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          color: color.withValues(alpha: 0.12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              status == SyncDisplayStatus.syncing
                  ? RotationTransition(
                      turns: _rotationController,
                      child: icon,
                    )
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
            ],
          ),
        ),
      ),
    );
  }
}
