import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';

import '../../../core/utils/logger.dart';

/// Platform-agnostic snapshot of a Play in-app update check.
class UpdateCheck {
  const UpdateCheck({
    required this.available,
    required this.immediateAllowed,
    required this.flexibleAllowed,
    required this.priority,
  });

  final bool available;
  final bool immediateAllowed;
  final bool flexibleAllowed;
  final int priority;
}

/// Thin, mockable boundary over the `in_app_update` plugin.
abstract class InAppUpdateClient {
  Future<UpdateCheck> check();
  Future<void> startImmediate();
  Future<void> startFlexible();
  Future<void> completeFlexible();

  /// Emits `true` once the flexible download has finished and is ready to
  /// install (Play `InstallStatus.downloaded`).
  Stream<bool> get flexibleDownloaded;
}

/// Concrete client backed by the Play Core App Update plugin. Android-only at
/// runtime; only ever invoked behind a `Platform.isAndroid` gate at call sites.
class PlayInAppUpdateClient implements InAppUpdateClient {
  const PlayInAppUpdateClient();

  @override
  Future<UpdateCheck> check() async {
    final info = await InAppUpdate.checkForUpdate();
    return UpdateCheck(
      available:
          info.updateAvailability == UpdateAvailability.updateAvailable,
      immediateAllowed: info.immediateUpdateAllowed,
      flexibleAllowed: info.flexibleUpdateAllowed,
      // updatePriority is a non-null int in in_app_update 4.x.
      priority: info.updatePriority,
    );
  }

  @override
  Future<void> startImmediate() async {
    await InAppUpdate.performImmediateUpdate();
  }

  @override
  Future<void> startFlexible() async {
    await InAppUpdate.startFlexibleUpdate();
  }

  @override
  Future<void> completeFlexible() async {
    await InAppUpdate.completeFlexibleUpdate();
  }

  @override
  Stream<bool> get flexibleDownloaded => InAppUpdate.installUpdateListener
      .map((status) => status == InstallStatus.downloaded)
      .where((downloaded) => downloaded);
}

/// Decides whether/how to launch a Play update. Pure logic — no platform gate
/// here; callers gate on `Platform.isAndroid`. Fail-open: any error is logged
/// and swallowed so a failed check never blocks the app.
class InAppUpdateService {
  InAppUpdateService(this._client, {this.immediatePriorityThreshold = 4});

  final InAppUpdateClient _client;
  final int immediatePriorityThreshold;

  Future<void> checkAndStart() async {
    try {
      final check = await _client.check();
      if (!check.available) return;
      if (check.immediateAllowed &&
          check.priority >= immediatePriorityThreshold) {
        await _client.startImmediate();
      } else if (check.flexibleAllowed) {
        await _client.startFlexible();
      }
    } catch (e, st) {
      AppLogger.warning('[InAppUpdate] check failed, continuing: $e');
      AppLogger.error('[InAppUpdate] check error', e, st);
    }
  }

  Future<void> completeFlexible() => _client.completeFlexible();

  Stream<bool> get flexibleDownloaded => _client.flexibleDownloaded;
}

final inAppUpdateServiceProvider = Provider<InAppUpdateService>((ref) {
  return InAppUpdateService(const PlayInAppUpdateClient());
});
