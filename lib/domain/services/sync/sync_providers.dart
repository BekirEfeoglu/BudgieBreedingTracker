import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart'
    show SyncErrorDetail;
import 'package:budgie_breeding_tracker/domain/services/sync/network_status_provider.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/retry_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';

// Re-export split provider files for backwards compatibility
export 'package:budgie_breeding_tracker/domain/services/sync/sync_scheduling_providers.dart';
export 'package:budgie_breeding_tracker/domain/services/sync/sync_conflict_providers.dart';

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
  bool _disposed = false;

  @override
  DateTime? build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    _loadFromPrefs();
    return null;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppPreferences.keyLastSyncedAt);
    if (raw == null || _disposed) return;
    final parsed = DateTime.tryParse(raw);
    if (parsed != null && !_disposed) {
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
