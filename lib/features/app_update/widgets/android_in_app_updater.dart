import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../../../domain/services/app_update/in_app_update_service.dart';

/// App-wide wrapper. On Android it triggers the Play in-app update check on
/// mount and shows a "restart to update" SnackBar when a flexible download
/// finishes. On every other platform it is a passthrough.
class AndroidInAppUpdater extends ConsumerStatefulWidget {
  const AndroidInAppUpdater({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AndroidInAppUpdater> createState() =>
      _AndroidInAppUpdaterState();
}

class _AndroidInAppUpdaterState extends ConsumerState<AndroidInAppUpdater> {
  StreamSubscription<bool>? _downloadSub;

  @override
  void initState() {
    super.initState();
    if (!Platform.isAndroid) return;
    final service = ref.read(inAppUpdateServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(service.checkAndStart());
    });
    _downloadSub = service.flexibleDownloaded.listen((_) {
      if (mounted) _promptRestart();
    });
  }

  void _promptRestart() {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('app_update.download_complete'.tr()),
        duration: const Duration(days: 1),
        action: SnackBarAction(
          label: 'app_update.restart'.tr(),
          onPressed: () {
            unawaited(
              ref
                  .read(inAppUpdateServiceProvider)
                  .completeFlexible()
                  .catchError((Object e, StackTrace st) {
                    AppLogger.error(
                      '[InAppUpdate] completeFlexible failed',
                      e,
                      st,
                    );
                  }),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
