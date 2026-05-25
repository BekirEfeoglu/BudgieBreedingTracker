import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';

/// Global offline/sync error surface shown above routed app content.
class OfflineBanner extends ConsumerStatefulWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner> {
  bool _isRetrying = false;

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(syncOfflineBannerEnabledProvider);
    if (!enabled) return widget.child;

    ref.listen<SyncDisplayStatus>(syncStatusProvider, (previous, next) {
      if (previous == SyncDisplayStatus.offline &&
          next != SyncDisplayStatus.offline) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('sync.reconnected_toast'.tr()),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    final status = ref.watch(syncStatusProvider);
    final pendingCount = ref
        .watch(pendingSyncCountProvider)
        .maybeWhen(data: (count) => count, orElse: () => 0);
    final pendingDeletionCount = ref
        .watch(pendingDeletionSyncErrorsProvider)
        .maybeWhen(data: (records) => records.length, orElse: () => 0);
    final hasClockSkewWarning = ref.watch(clockSkewWarningProvider) != null;
    final userId = ref.watch(currentUserIdProvider);
    final conflictCount = userId == 'anonymous' || userId.isEmpty
        ? 0
        : ref
              .watch(persistedConflictCountProvider(userId))
              .maybeWhen(data: (count) => count, orElse: () => 0);
    final banner = _bannerModel(
      status,
      pendingCount,
      pendingDeletionCount,
      hasClockSkewWarning,
      conflictCount,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (banner != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: _SyncBanner(
                model: banner,
                isRetrying: _isRetrying,
                onRetry: banner.canRetry ? _retrySync : null,
              ),
            ),
          ),
      ],
    );
  }

  _OfflineBannerModel? _bannerModel(
    SyncDisplayStatus status,
    int pendingCount,
    int pendingDeletionCount,
    bool hasClockSkewWarning,
    int conflictCount,
  ) {
    if (status == SyncDisplayStatus.offline) {
      return _OfflineBannerModel(
        icon: LucideIcons.wifiOff,
        titleKey: 'sync.offline_banner',
        subtitleKey: pendingCount > 0 ? 'sync.pending_changes_count' : null,
        subtitleArgs: pendingCount > 0 ? ['$pendingCount'] : null,
        color: Theme.of(context).colorScheme.tertiary,
        canRetry: false,
      );
    }

    if (status == SyncDisplayStatus.error) {
      return _OfflineBannerModel(
        icon: LucideIcons.alertTriangle,
        titleKey: 'sync.error_banner',
        color: Theme.of(context).colorScheme.error,
        canRetry: true,
      );
    }

    if (pendingDeletionCount > 0) {
      return _OfflineBannerModel(
        icon: LucideIcons.clock,
        titleKey: 'sync.pending_deletion_warning',
        subtitleKey: 'sync.pending_changes_count',
        subtitleArgs: ['$pendingDeletionCount'],
        color: Theme.of(context).colorScheme.error,
        canRetry: true,
      );
    }

    if (conflictCount > 0) {
      return _OfflineBannerModel(
        icon: LucideIcons.alertCircle,
        titleKey: 'sync.conflict_banner_title',
        subtitleKey: 'sync.conflict_banner_subtitle',
        subtitleArgs: ['$conflictCount'],
        color: Theme.of(context).colorScheme.error,
        canRetry: false,
      );
    }

    if (hasClockSkewWarning) {
      return _OfflineBannerModel(
        icon: LucideIcons.clock,
        titleKey: 'sync.clock_skew_warning',
        color: Theme.of(context).colorScheme.tertiary,
        canRetry: false,
      );
    }

    return null;
  }

  Future<void> _retrySync() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);

    try {
      final result = await ref.read(syncOrchestratorProvider).forceFullSync();
      if (!mounted) return;
      if (result == SyncResult.success) {
        ref.read(syncErrorProvider.notifier).state = false;
        ref.invalidate(pendingDeletionSyncErrorsProvider);
      }
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }
}

class _SyncBanner extends StatelessWidget {
  final _OfflineBannerModel model;
  final bool isRetrying;
  final VoidCallback? onRetry;

  const _SyncBanner({
    required this.model,
    required this.isRetrying,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onError;

    return Semantics(
      liveRegion: true,
      label: model.titleKey.tr(),
      child: Material(
        color: model.color,
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(model.icon, color: textColor, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      model.titleKey.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (model.subtitleKey != null)
                      Text(
                        model.subtitleKey!.tr(args: model.subtitleArgs),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor.withValues(alpha: 0.9),
                        ),
                      ),
                  ],
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(width: AppSpacing.md),
                TextButton(
                  onPressed: isRetrying ? null : onRetry,
                  style: TextButton.styleFrom(foregroundColor: textColor),
                  child: isRetrying
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: textColor.withValues(alpha: 0.9),
                          ),
                        )
                      : Text('sync.retry_action'.tr()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineBannerModel {
  final IconData icon;
  final String titleKey;
  final String? subtitleKey;
  final List<String>? subtitleArgs;
  final Color color;
  final bool canRetry;

  const _OfflineBannerModel({
    required this.icon,
    required this.titleKey,
    this.subtitleKey,
    this.subtitleArgs,
    required this.color,
    required this.canRetry,
  });
}
