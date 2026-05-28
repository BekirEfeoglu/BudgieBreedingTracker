import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/logger.dart';
import '../../../domain/services/app_update/app_update_info.dart';
import '../../../domain/services/app_update/app_update_providers.dart';
import '../../../router/router_notifier.dart';

class AppUpdatePrompt extends ConsumerStatefulWidget {
  const AppUpdatePrompt({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppUpdatePrompt> createState() => _AppUpdatePromptState();
}

class _AppUpdatePromptState extends ConsumerState<AppUpdatePrompt> {
  String? _shownVersionKey;
  bool _isDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppUpdateStatus?>>(appUpdateStatusProvider, (
      previous,
      next,
    ) {
      next.whenData((status) {
        if (status == null ||
            Theme.of(context).platform != TargetPlatform.iOS) {
          return;
        }
        final versionKey =
            '${status.info.latestVersion}+${status.info.latestBuild}';
        if (_isDialogOpen || _shownVersionKey == versionKey) {
          return;
        }
        _shownVersionKey = versionKey;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showUpdateDialog(status);
        });
      });
    });

    return widget.child;
  }

  Future<void> _showUpdateDialog(AppUpdateStatus status) async {
    // AppUpdatePrompt is mounted in the MaterialApp builder, above the router's
    // Navigator, so its own context has no Navigator ancestor. Show the dialog
    // through the root navigator's context instead.
    final navigatorContext = rootNavigatorKey.currentContext;
    if (navigatorContext == null) return;
    _isDialogOpen = true;
    final notes = _localizedReleaseNotes(status.info);
    try {
      await showDialog<void>(
        context: navigatorContext,
        barrierDismissible: !status.isRequired,
        builder: (dialogContext) => PopScope(
          canPop: !status.isRequired,
          child: AlertDialog(
            title: Text(
              status.isRequired
                  ? 'app_update.required_title'.tr()
                  : 'app_update.available_title'.tr(),
            ),
            content: Text(
              notes == null
                  ? 'app_update.message'.tr(args: [status.info.latestVersion])
                  : 'app_update.message_with_notes'.tr(
                      args: [status.info.latestVersion, notes],
                    ),
            ),
            actions: [
              if (!status.isRequired)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('app_update.later'.tr()),
                ),
              FilledButton(
                onPressed: () => _openStore(status.info.storeUrl),
                child: Text('app_update.update_now'.tr()),
              ),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) _isDialogOpen = false;
    }
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
