import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'package:budgie_breeding_tracker/bootstrap.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_settings_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_telemetry.dart';

const backgroundSyncUniqueName = 'budgie_background_sync_periodic';
const backgroundSyncTaskName = 'budgie_background_sync_push';
const backgroundSyncTaskIdentifier =
    'com.budgiebreedingtracker.sync.background';

final backgroundSyncServiceProvider = Provider<BackgroundSyncService>((ref) {
  return BackgroundSyncService(ref, Workmanager());
});

class BackgroundSyncService {
  BackgroundSyncService(this._ref, this._workmanager);

  final Ref _ref;
  final Workmanager _workmanager;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _workmanager.initialize(backgroundSyncCallbackDispatcher);
    _initialized = true;
  }

  Future<void> register() async {
    await initialize();
    if (!_ref.read(syncBackgroundEnabledProvider)) {
      await cancel();
      return;
    }

    await _workmanager.registerPeriodicTask(
      backgroundSyncUniqueName,
      backgroundSyncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      tag: backgroundSyncTaskName,
    );
  }

  Future<void> cancel() {
    return _workmanager.cancelByUniqueName(backgroundSyncUniqueName);
  }

  Future<bool> executeTask() {
    return runPushOnly(
      enabled: _ref.read(syncBackgroundEnabledProvider),
      userId: _ref.read(currentUserIdProvider),
      pushChanges: (userId) {
        return _ref.read(syncOrchestratorProvider).pushChanges(userId);
      },
    );
  }

  static Future<bool> runPushOnly({
    required bool enabled,
    required String userId,
    required Future<bool> Function(String userId) pushChanges,
    void Function(String name, Map<String, Object?> data)? telemetrySink,
  }) async {
    final stopwatch = Stopwatch()..start();
    void emit(String name, Map<String, Object?> data) {
      final payload = {
        ...data,
        'durationMs': stopwatch.elapsedMilliseconds,
        'taskBudgetSeconds': 30,
      };
      if (telemetrySink != null) {
        telemetrySink(name, payload);
      } else {
        SyncTelemetry.event(name, data: payload);
      }
    }

    if (!enabled || userId == 'anonymous') {
      AppLogger.debug('[BackgroundSync] Skipped: disabled or signed out');
      emit('background_sync_skipped', {
        'enabled': enabled,
        'signedIn': userId != 'anonymous',
      });
      return true;
    }

    try {
      final pushed = await pushChanges(userId);
      emit('background_sync_run', {'success': pushed});
      if (!pushed) {
        AppLogger.warning(
          '[BackgroundSync] Pending push completed with errors',
        );
      }
      return pushed;
    } catch (e, st) {
      AppLogger.error('[BackgroundSync] Pending push failed', e, st);
      emit('background_sync_run', {
        'success': false,
        'errorType': e.runtimeType.toString(),
      });
      return false;
    }
  }
}

@pragma('vm:entry-point')
void backgroundSyncCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (taskName != backgroundSyncTaskName &&
        taskName != backgroundSyncTaskIdentifier &&
        taskName != Workmanager.iOSBackgroundTask) {
      return true;
    }

    final ready = await ensureSupabaseInitialized(
      timeout: const Duration(seconds: 8),
    );
    if (!ready) {
      AppLogger.debug('[BackgroundSync] Supabase unavailable; deferring');
      return true;
    }

    final container = ProviderContainer();
    try {
      return await container.read(backgroundSyncServiceProvider).executeTask();
    } finally {
      container.dispose();
    }
  });
}
