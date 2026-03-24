import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/core/models/sync_conflict.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';

export 'package:budgie_breeding_tracker/core/models/sync_conflict.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart'
    show SyncErrorDetail;
import 'package:budgie_breeding_tracker/domain/services/sync/network_status_provider.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/retry_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_settings_providers.dart';

/// Provider for the [SyncOrchestrator] singleton.
final syncOrchestratorProvider = Provider<SyncOrchestrator>((ref) {
  return SyncOrchestrator(ref);
});

/// Notifier for whether a sync is currently running.
class IsSyncingNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}

/// Whether a sync is currently running.
final isSyncingProvider = NotifierProvider<IsSyncingNotifier, bool>(
  IsSyncingNotifier.new,
);

/// Notifier for last successful sync timestamp (initialized from SharedPreferences).
class LastSyncTimeNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    _loadFromPrefs();
    return null;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppPreferences.keyLastSyncedAt);
    if (raw == null) return;
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      state = parsed;
    }
  }
}

/// Last successful sync timestamp (initialized from SharedPreferences).
final lastSyncTimeProvider = NotifierProvider<LastSyncTimeNotifier, DateTime?>(
  LastSyncTimeNotifier.new,
);

/// Notifier for whether the last sync had an error.
class SyncErrorNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}

/// Whether the last sync had an error.
final syncErrorProvider = NotifierProvider<SyncErrorNotifier, bool>(
  SyncErrorNotifier.new,
);

/// Sync interval for periodic sync (15 minutes).
const _syncInterval = Duration(minutes: 15);

/// High-level sync status for UI display.
enum SyncDisplayStatus {
  /// All data is synced with the server.
  synced,

  /// A sync operation is currently in progress.
  syncing,

  /// Device is offline; changes will sync when reconnected.
  offline,

  /// Last sync attempt resulted in an error.
  error,
}

/// Combined sync status derived from network and sync state.
///
/// UI widgets can watch this provider to show appropriate
/// sync indicators (e.g., offline banner, syncing spinner).
final syncStatusProvider = Provider<SyncDisplayStatus>((ref) {
  final isSyncing = ref.watch(isSyncingProvider);
  final hasError = ref.watch(syncErrorProvider);
  final isOnline = ref.watch(networkStatusProvider).value ?? true;

  if (!isOnline) return SyncDisplayStatus.offline;
  if (isSyncing) return SyncDisplayStatus.syncing;
  if (hasError) return SyncDisplayStatus.error;
  return SyncDisplayStatus.synced;
});

/// Periodic sync provider that triggers fullSync every 15 minutes.
///
/// Automatically starts when watched and disposes the Timer on cleanup.
/// Also retries failed sync records on each cycle.
/// Respects [wifiOnlySyncProvider] — skips sync when on cellular and WiFi-only is enabled.
final periodicSyncProvider = Provider<void>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'anonymous') return;

  // Skip periodic sync when auto-sync is disabled
  final autoSync = ref.watch(autoSyncProvider);
  if (!autoSync) return;

  final timer = Timer.periodic(_syncInterval, (_) async {
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
      await orchestrator.retryFailedRecords(userId);
    } catch (e) {
      AppLogger.warning('[PeriodicSync] Retry failed: $e');
    }

    // Then run full sync
    final result = await orchestrator.fullSync();
    if (result == SyncResult.success) {
      ref.read(syncErrorProvider.notifier).state = false;
    }
    AppLogger.info('[PeriodicSync] Periodic sync result: ${result.name}');
  });

  ref.onDispose(() {
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
      final orchestrator = ref.read(syncOrchestratorProvider);
      final result = await orchestrator.forceFullSync();
      if (result == SyncResult.success) {
        ref.read(syncErrorProvider.notifier).state = false;
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

// ---------------------------------------------------------------------------
// Pending Sync Count (reactive stream)
// ---------------------------------------------------------------------------

/// Stream of pending sync record count for the current user.
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'anonymous') return Stream.value(0);
  final syncDao = ref.watch(syncMetadataDaoProvider);
  return syncDao.watchPendingCount(userId);
});

// ---------------------------------------------------------------------------
// Stale Error Count
// ---------------------------------------------------------------------------

/// Count of stale (unrecoverable) sync errors for the current user.
/// Records older than 24h with retryCount >= maxRetries.
final staleErrorCountProvider = FutureProvider<int>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'anonymous') return 0;
  final syncDao = ref.watch(syncMetadataDaoProvider);
  return syncDao.countStaleErrors(
    userId,
    const Duration(hours: 24),
    RetryScheduler.maxRetries,
  );
});

// ---------------------------------------------------------------------------
// Table-Level Error Details (reactive stream)
// ---------------------------------------------------------------------------

/// Stream of sync errors grouped by table for the current user.
final syncErrorDetailsProvider =
    StreamProvider.family<List<SyncErrorDetail>, String>((ref, userId) {
  if (userId == 'anonymous') return Stream.value([]);
  final syncDao = ref.watch(syncMetadataDaoProvider);
  return syncDao.watchErrorsByTable(userId);
});

/// Stream of pending sync records grouped by table for the current user.
final pendingByTableProvider =
    StreamProvider.family<List<SyncErrorDetail>, String>((ref, userId) {
  if (userId == 'anonymous') return Stream.value([]);
  final syncDao = ref.watch(syncMetadataDaoProvider);
  return syncDao.watchPendingByTable(userId);
});

/// Stream count of persisted conflict history records.
final persistedConflictCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  if (userId == 'anonymous') return Stream.value(0);
  final dao = ref.watch(conflictHistoryDaoProvider);
  return dao.watchRecentCount(userId, const Duration(hours: 24));
});

// ---------------------------------------------------------------------------
// Conflict History (DB-backed, max 50 entries, FIFO)
// ---------------------------------------------------------------------------

class ConflictHistoryNotifier extends Notifier<List<SyncConflict>> {
  static const _maxEntries = 50;

  @override
  List<SyncConflict> build() {
    _restoreFromDb();
    return [];
  }

  Future<void> _restoreFromDb() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == 'anonymous') return;
      final dao = ref.read(conflictHistoryDaoProvider);
      final persisted = await dao.watchAll(userId).first;
      if (persisted.isNotEmpty) {
        state = persisted
            .map((c) => SyncConflict(
                  table: c.tableName,
                  recordId: c.recordId,
                  detectedAt: c.createdAt ?? DateTime.now(),
                  description: c.description,
                ))
            .take(_maxEntries)
            .toList();
      }
    } catch (e) {
      AppLogger.debug('[ConflictHistory] Restore failed: $e');
    }
  }

  void addConflict(SyncConflict conflict) {
    state = [conflict, ...state].take(_maxEntries).toList();
  }

  void clear() => state = [];
}

final conflictHistoryProvider =
    NotifierProvider<ConflictHistoryNotifier, List<SyncConflict>>(
      ConflictHistoryNotifier.new,
    );
