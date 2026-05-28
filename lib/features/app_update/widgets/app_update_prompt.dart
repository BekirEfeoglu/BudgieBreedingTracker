import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/services/app_update/app_update_info.dart';
import '../../../domain/services/app_update/app_update_providers.dart';

/// iOS in-app update prompt, rendered as an in-tree overlay (NOT a route) so it
/// survives GoRouter rebuilds. Mounted in the MaterialApp builder, above the
/// router.
///
/// An imperative `showDialog` from here is dismissed whenever GoRouter rebuilds
/// its pages (e.g. on an auth-token refresh), so the prompt is drawn directly
/// in the widget tree instead:
/// - optional update -> dismissible banner over the content
/// - required update (local build < min_supported_build) -> full-screen block
///
/// Android uses native Play in-app updates (see AndroidInAppUpdater); this
/// prompt is iOS-only.
class AppUpdatePrompt extends ConsumerStatefulWidget {
  const AppUpdatePrompt({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppUpdatePrompt> createState() => _AppUpdatePromptState();
}

class _AppUpdatePromptState extends ConsumerState<AppUpdatePrompt> {
  String? _dismissedVersionKey;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(appUpdateStatusProvider).asData?.value;
    final overlay = _overlayFor(context, status);
    if (overlay == null) return widget.child;
    return Stack(children: [widget.child, overlay]);
  }

  Widget? _overlayFor(BuildContext context, AppUpdateStatus? status) {
    if (status == null) return null;
    if (Theme.of(context).platform != TargetPlatform.iOS) return null;
    final versionKey =
        '${status.info.latestVersion}+${status.info.latestBuild}';
    if (!status.isRequired && _dismissedVersionKey == versionKey) return null;

    final message = _message(status.info);
    if (status.isRequired) {
      return _RequiredUpdateLayer(
        message: message,
        onUpdate: () => _openStore(status.info.storeUrl),
      );
    }
    return _OptionalUpdateBanner(
      message: message,
      onUpdate: () => _openStore(status.info.storeUrl),
      onDismiss: () => setState(() => _dismissedVersionKey = versionKey),
    );
  }

  String _message(AppUpdateInfo info) {
    final notes = _localizedReleaseNotes(info);
    return notes == null
        ? 'app_update.message'.tr(args: [info.latestVersion])
        : 'app_update.message_with_notes'.tr(args: [info.latestVersion, notes]);
  }

  String? _localizedReleaseNotes(AppUpdateInfo info) {
    final languageCode = context.locale.languageCode;
    final notes = switch (languageCode) {
      'tr' => info.releaseNotesTr,
      'de' => info.releaseNotesDe,
      _ => info.releaseNotesEn,
    };
    if (notes == null || notes.trim().isEmpty) return null;
    return notes.trim();
  }

  Future<void> _openStore(String storeUrl) async {
    final uri = Uri.tryParse(storeUrl);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e, st) {
      AppLogger.error('[AppUpdate] Store launch failed', e, st);
    }
  }
}

class _OptionalUpdateBanner extends StatelessWidget {
  const _OptionalUpdateBanner({
    required this.message,
    required this.onUpdate,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surfaceContainerHigh,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'app_update.available_title'.tr(),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(message, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: onDismiss,
                        child: Text('app_update.later'.tr()),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(
                        onPressed: onUpdate,
                        child: Text('app_update.update_now'.tr()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequiredUpdateLayer extends StatelessWidget {
  const _RequiredUpdateLayer({required this.message, required this.onUpdate});

  final String message;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: Material(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.system_update,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'app_update.required_title'.tr(),
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                FilledButton(
                  onPressed: onUpdate,
                  child: Text('app_update.update_now'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
