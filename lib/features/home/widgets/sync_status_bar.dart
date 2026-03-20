import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';

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

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(syncStatusProvider);

    if (status == SyncDisplayStatus.syncing) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }

    final colorScheme = Theme.of(context).colorScheme;

    final (IconData icon, Color color, String label) = switch (status) {
      SyncDisplayStatus.synced => (
        Icons.cloud_done,
        colorScheme.primary,
        'sync.synced'.tr(),
      ),
      SyncDisplayStatus.syncing => (
        Icons.sync,
        colorScheme.tertiary,
        'sync.syncing'.tr(),
      ),
      SyncDisplayStatus.offline => (
        Icons.cloud_off,
        colorScheme.error,
        'sync.offline'.tr(),
      ),
      SyncDisplayStatus.error => (
        Icons.cloud_off,
        colorScheme.error,
        'sync.sync_error'.tr(),
      ),
    };

    final theme = Theme.of(context);

    return Semantics(
      label: label,
      button: status != SyncDisplayStatus.syncing,
      child: GestureDetector(
        onTap: () {
          if (status != SyncDisplayStatus.syncing) {
            final orchestrator = ref.read(syncOrchestratorProvider);
            orchestrator.fullSync();
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          color: theme.colorScheme.surfaceContainerLow,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              status == SyncDisplayStatus.syncing
                  ? RotationTransition(
                      turns: _rotationController,
                      child: Icon(icon, size: 13, color: color),
                    )
                  : Icon(icon, size: 13, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
