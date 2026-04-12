import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_processor.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_push_handler.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_pull_handler.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_error_handler.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart'
    show birdsDaoProvider, conflictHistoryDaoProvider;
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_service.dart';

part 'sync_time_helpers.dart';

/// Orchestrates offline-first sync between local Drift DB and Supabase.
///
/// Follows push-then-pull strategy: local changes are pushed first,
/// then remote changes are pulled to ensure no data loss.
/// Updates [isSyncingProvider] and [lastSyncTimeProvider] during operation.
///
/// Delegates to:
/// - [SyncPushHandler] for pushing local changes
/// - [SyncPullHandler] for pulling remote changes
/// - [SyncErrorHandler] for retry and cleanup
class SyncOrchestrator {
  SyncOrchestrator(this._ref)
    : _pushHandler = SyncPushHandler(_ref),
      _pullHandler = SyncPullHandler(_ref) {
    _errorHandler = SyncErrorHandler(_ref, _pushHandler);
  }

  final Ref _ref;
  final SyncPushHandler _pushHandler;
  final SyncPullHandler _pullHandler;
  late final SyncErrorHandler _errorHandler;

  Future<SyncResult>? _activeSyncFuture;
  SharedPreferences? _prefs;
  DateTime? _lastForceFullSyncAt;

  /// Whether a sync operation is currently in progress.
  bool get isSyncing => _activeSyncFuture != null;

  /// Interval between automatic full reconciliation runs.
  static const _reconcileInterval = Duration(hours: 6);

  /// Minimum interval between consecutive forceFullSync calls.
  static const _forceFullSyncCooldown = Duration(minutes: 2);

  /// Performs a sync cycle: push local changes, then pull remote.
  ///
  /// Uses incremental pull by default. Automatically performs full
  /// reconciliation (removes local orphans) every [_reconcileInterval].
  ///
  /// Returns [SyncResult.alreadySyncing] if a sync is already running.
  /// Updates [isSyncingProvider] and [lastSyncTimeProvider] automatically.
  Future<SyncResult> fullSync() {
    if (_activeSyncFuture != null) return _activeSyncFuture!;
    _activeSyncFuture = _doFullSync().whenComplete(() {
      _activeSyncFuture = null;
    });
    return _activeSyncFuture!;
  }

  Future<SyncResult> _doFullSync() async {
    _ref.read(isSyncingProvider.notifier).state = true;
    _ref.read(syncErrorProvider.notifier).state = false;

    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == 'anonymous') {
        return SyncResult.error;
      }

      // Load persisted lastSyncTime for incremental pull
      final lastSync = await _loadLastSyncTime();

      // Check if full reconciliation is due
      final needsReconcile = await _isReconcileDue();
      final since = needsReconcile ? null : lastSync;

      final pushSuccess = await _pushHandler.pushChanges(userId);

      // If push had errors, skip full reconciliation to protect unsynced
      // local records. Fall back to incremental pull instead.
      final effectiveSince = pushSuccess ? since : (lastSync ?? since);
      final pullSuccess = await _pullHandler.pullChanges(
        userId,
        since: effectiveSince,
      );
      if (!pullSuccess) {
        _ref.read(syncErrorProvider.notifier).state = true;
        // Still proceed with cleanup and notification processing
        // instead of returning early — partial data is better than none.
      }

      // Clean up unrecoverable errors AFTER sync cycle completes.
      // Running before sync would remove error metadata that protects
      // local records from being deleted during reconciliation.
      await _errorHandler.cleanupUnrecoverableErrors(userId);

      // Clean up old conflict history (30-day retention)
      try {
        final conflictDao = _ref.read(conflictHistoryDaoProvider);
        await conflictDao.deleteOlderThan(30);
      } catch (e) {
        AppLogger.debug('[SyncOrchestrator] Conflict cleanup failed: $e');
      }

      // Process pending event reminders and notification schedules
      await _processNotifications();

      // Migrate legacy encrypted payloads during full reconciliation,
      // or when a previous migration was incomplete (pending flag).
      final pendingMigration = await _hasPendingMigration();
      if (needsReconcile || lastSync == null || pendingMigration) {
        await _migrateEncryptedPayloads();
      }

      if (pullSuccess) {
        // Only advance sync checkpoint when pull fully succeeded.
        // Partial failures retry from the same point on next cycle.
        final now = DateTime.now();
        await _persistLastSyncTime(now);
        _ref.read(lastSyncTimeProvider.notifier).state = now;

        if (pushSuccess && (needsReconcile || lastSync == null)) {
          await _persistLastReconcileTime(now);
        }
      }

      return pullSuccess ? SyncResult.success : SyncResult.error;
    } catch (e, st) {
      AppLogger.error('[SyncOrchestrator] Full sync failed', e, st);
      Sentry.captureException(e, stackTrace: st);
      _ref.read(syncErrorProvider.notifier).state = true;
      return SyncResult.error;
    } finally {
      _ref.read(isSyncingProvider.notifier).state = false;
    }
  }

  /// Forces a full sync with reconciliation regardless of timing.
  ///
  /// Removes local records that no longer exist on the server.
  /// Use when the user explicitly requests a full refresh.
  Future<SyncResult> forceFullSync() {
    if (_activeSyncFuture != null) return _activeSyncFuture!;

    // Throttle rapid consecutive calls
    if (_lastForceFullSyncAt != null &&
        DateTime.now().difference(_lastForceFullSyncAt!) <
            _forceFullSyncCooldown) {
      AppLogger.info('[SyncOrchestrator] Force full sync skipped (cooldown)');
      return Future.value(SyncResult.throttled);
    }

    _activeSyncFuture = _doForceFullSync().whenComplete(() {
      _activeSyncFuture = null;
    });
    return _activeSyncFuture!;
  }

  Future<SyncResult> _doForceFullSync() async {
    _ref.read(isSyncingProvider.notifier).state = true;
    _ref.read(syncErrorProvider.notifier).state = false;

    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == 'anonymous') {
        return SyncResult.error;
      }

      final pushSuccess = await _pushHandler.pushChanges(userId);

      // Only do full reconciliation if push succeeded. Otherwise use
      // incremental pull to avoid deleting unsynced local records.
      final lastSync = await _loadLastSyncTime();
      final effectiveSince = pushSuccess ? null : lastSync;
      final pullSuccess = await _pullHandler.pullChanges(
        userId,
        since: effectiveSince,
      );
      if (!pullSuccess) {
        _ref.read(syncErrorProvider.notifier).state = true;
        // Still proceed with cleanup and notification processing.
      }

      // Clean up unrecoverable errors AFTER sync cycle completes.
      await _errorHandler.cleanupUnrecoverableErrors(userId);

      // Process pending event reminders and notification schedules
      await _processNotifications();

      // Migrate legacy encrypted payloads during forced reconciliation
      await _migrateEncryptedPayloads();

      if (pullSuccess) {
        final now = DateTime.now();
        _lastForceFullSyncAt = now;
        await _persistLastSyncTime(now);
        if (pushSuccess) {
          await _persistLastReconcileTime(now);
        }
        _ref.read(lastSyncTimeProvider.notifier).state = now;
      }

      return pullSuccess ? SyncResult.success : SyncResult.error;
    } catch (e, st) {
      AppLogger.error('[SyncOrchestrator] Force full sync failed', e, st);
      Sentry.captureException(e, stackTrace: st);
      _ref.read(syncErrorProvider.notifier).state = true;
      return SyncResult.error;
    } finally {
      _ref.read(isSyncingProvider.notifier).state = false;
    }
  }

  /// Delegates push to [SyncPushHandler].
  Future<bool> pushChanges(String userId) => _pushHandler.pushChanges(userId);

  /// Delegates pull to [SyncPullHandler].
  Future<bool> pullChanges(String userId, {DateTime? since}) =>
      _pullHandler.pullChanges(userId, since: since);

  /// Delegates retry to [SyncErrorHandler].
  Future<void> retryFailedRecords(String userId) =>
      _errorHandler.retryFailedRecords(userId);

  /// Delegates cleanup to [SyncErrorHandler].
  Future<int> cleanupUnrecoverableErrors(String userId) =>
      _errorHandler.cleanupUnrecoverableErrors(userId);

  // Timestamp management and notification processing helpers are in
  // sync_time_helpers.dart (part file)
}

/// Result of a sync operation.
enum SyncResult {
  /// Sync completed successfully.
  success,

  /// Sync failed due to an error.
  error,

  /// A sync was already in progress.
  alreadySyncing,

  /// Sync skipped due to cooldown throttling.
  throttled,
}
