import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_settings_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/network_status_provider.dart';

/// Sync interval for periodic sync (15 minutes).
const _syncInterval = Duration(minutes: 15);

/// Periodic sync provider that triggers fullSync every 15 minutes.
///
/// Automatically starts when watched and disposes the Timer on cleanup.
/// Also retries failed sync records on each cycle.
/// Respects [wifiOnlySyncProvider] — skips sync when on cellular and WiFi-only is enabled.
///
/// Lifecycle note: this provider watches [currentUserIdProvider], so any sign-out
/// (userId → 'anonymous') forces a rebuild, disposing the old instance's timers
/// via [Ref.onDispose]. The early-return on 'anonymous' then prevents new timers
/// from being created. Timer callbacks also re-read userId defensively in case
/// a cycle fires in the narrow window between state change and provider rebuild.
final periodicSyncProvider = Provider<void>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'anonymous') return;

  // Skip periodic sync when auto-sync is disabled
  final autoSync = ref.watch(autoSyncProvider);
  if (!autoSync) return;

  // Add random initial jitter (0-60 seconds) to distribute sync load
  // across users and prevent thundering herd on the server.
  final initialJitter = Duration(seconds: Random().nextInt(60));
  final jitterTimer = Timer(initialJitter, () {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == 'anonymous') return;
    final orchestrator = ref.read(syncOrchestratorProvider);
    orchestrator.fullSync();
  });

  // Explicit proactive cancellation: if the user signs out between timer
  // creation and the Riverpod rebuild cycle, cancel immediately rather than
  // relying solely on onDispose. This tightens the cleanup guarantee and
  // documents the intent for future maintainers.
  ref.listen<String>(currentUserIdProvider, (_, next) {
    if (next == 'anonymous') {
      jitterTimer.cancel();
    }
  });

  final timer = Timer.periodic(_syncInterval, (_) async {
    // Read current userId each cycle to avoid stale closure capture
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == 'anonymous') return;

    // WiFi-only check
    final wifiOnly = ref.read(wifiOnlySyncProvider);
    if (wifiOnly) {
      final connectivity = await Connectivity().checkConnectivity();
      final isWifi = connectivity.contains(ConnectivityResult.wifi);
      if (!isWifi) {
        AppLogger.info('[PeriodicSync] Skipped: WiFi-only mode, not on WiFi');
        return;
      }
    }

    final orchestrator = ref.read(syncOrchestratorProvider);

    // First retry any failed records
    try {
      await orchestrator.retryFailedRecords(currentUserId);
    } catch (e) {
      AppLogger.warning('[PeriodicSync] Retry failed: $e');
    }

    // Then run full sync
    try {
      final result = await orchestrator.fullSync();
      if (result == SyncResult.success) {
        ref.read(syncErrorProvider.notifier).state = false;
      }
      AppLogger.info('[PeriodicSync] Periodic sync result: ${result.name}');
    } catch (e) {
      AppLogger.warning('[PeriodicSync] Full sync failed: $e');
    }
  });

  // Attach the periodic-timer cancellation to the same listener so sign-out
  // tears down both timers in one hop.
  ref.listen<String>(currentUserIdProvider, (_, next) {
    if (next == 'anonymous') {
      timer.cancel();
    }
  });

  ref.onDispose(() {
    jitterTimer.cancel();
    timer.cancel();
    AppLogger.info('[PeriodicSync] Timer disposed');
  });
});

/// Network-aware sync provider that triggers forceFullSync when device reconnects.
///
/// Watches [networkStatusProvider] and triggers sync when transitioning
/// from offline to online. Uses [forceFullSync] to ensure full
/// reconciliation after potentially long offline periods.
/// Prevents duplicate syncs via isSyncing check.
/// Respects [wifiOnlySyncProvider] — skips sync when on cellular and WiFi-only is enabled.
final networkAwareSyncProvider = Provider<void>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'anonymous') return;

  bool wasOffline = false;

  ref.listen<AsyncValue<bool>>(networkStatusProvider, (previous, next) async {
    // Skip network-aware sync when auto-sync is disabled
    final autoSync = ref.read(autoSyncProvider);
    if (!autoSync) return;

    final isOnline = next.value ?? true;
    final previouslyOnline = previous?.value ?? true;

    if (!previouslyOnline) {
      wasOffline = true;
    }

    // Trigger full sync when transitioning from offline to online
    if (isOnline && wasOffline) {
      wasOffline = false;
      final isSyncing = ref.read(isSyncingProvider);
      if (isSyncing) return;

      // WiFi-only check
      final wifiOnly = ref.read(wifiOnlySyncProvider);
      if (wifiOnly) {
        final connectivity = await Connectivity().checkConnectivity();
        final isWifi = connectivity.contains(ConnectivityResult.wifi);
        if (!isWifi) {
          AppLogger.info('[NetworkSync] Skipped: WiFi-only mode, not on WiFi');
          return;
        }
      }

      AppLogger.info('[NetworkSync] Device came online, triggering full sync');
      try {
        final orchestrator = ref.read(syncOrchestratorProvider);
        final result = await orchestrator.forceFullSync();
        if (result == SyncResult.success) {
          ref.read(syncErrorProvider.notifier).state = false;
        }
      } catch (e) {
        AppLogger.warning('[NetworkSync] Force full sync failed: $e');
      }
    }
  });
});

/// Triggers a manual sync with full reconciliation. Returns the [SyncResult].
///
/// Can be called from UI (e.g., manual sync button, pull-to-refresh).
/// Uses [forceFullSync] to ensure local orphans are cleaned up.
Future<SyncResult> triggerManualSync(Ref ref) async {
  final orchestrator = ref.read(syncOrchestratorProvider);
  final userId = ref.read(currentUserIdProvider);

  // Retry failed records first
  try {
    await orchestrator.retryFailedRecords(userId);
  } catch (e) {
    AppLogger.debug('[SyncProviders] retryFailedRecords failed: $e');
  }

  final result = await orchestrator.forceFullSync();
  if (result == SyncResult.success) {
    ref.read(syncErrorProvider.notifier).state = false;
  }
  return result;
}
