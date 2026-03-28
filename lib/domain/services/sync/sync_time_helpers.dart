part of 'sync_orchestrator.dart';

// ---------------------------------------------------------------------------
// Timestamp persistence and notification processing helpers
// for [SyncOrchestrator]. Top-level private functions accessible
// via the `part` directive.
// ---------------------------------------------------------------------------

extension _SyncTimeHelpers on SyncOrchestrator {
  /// Processes pending event reminders and notification schedules.
  ///
  /// Called after pull to handle any new or existing unsent items.
  /// Errors are caught and logged — they should not break the sync cycle.
  Future<void> _processNotifications() async {
    try {
      final processor = _ref.read(notificationProcessorProvider);
      await processor.processAll();
    } catch (e, st) {
      AppLogger.warning(
        '[SyncOrchestrator] Notification processing failed: $e',
      );
      Sentry.captureException(e, stackTrace: st);
    }
  }

  /// Returns cached SharedPreferences instance.
  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Loads persisted last sync timestamp from SharedPreferences.
  Future<DateTime?> _loadLastSyncTime() async {
    try {
      final prefs = await _getPrefs();
      final value = prefs.getString(AppPreferences.keyLastSyncedAt);
      if (value == null) return null;
      return DateTime.tryParse(value);
    } catch (_) {
      return null;
    }
  }

  /// Persists the last sync timestamp to SharedPreferences.
  Future<void> _persistLastSyncTime(DateTime time) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(
        AppPreferences.keyLastSyncedAt,
        time.toIso8601String(),
      );
    } catch (e) {
      AppLogger.warning('[SyncOrchestrator] Failed to persist sync time: $e');
    }
  }

  /// Checks whether a full reconciliation is due based on the interval.
  Future<bool> _isReconcileDue() async {
    try {
      final prefs = await _getPrefs();
      final value = prefs.getString(AppPreferences.keyLastReconciledAt);
      if (value == null) return true; // Never reconciled
      final lastReconcile = DateTime.tryParse(value);
      if (lastReconcile == null) return true;
      return DateTime.now().difference(lastReconcile) >=
          SyncOrchestrator._reconcileInterval;
    } catch (_) {
      return true;
    }
  }

  /// Persists the last reconciliation timestamp.
  Future<void> _persistLastReconcileTime(DateTime time) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(
        AppPreferences.keyLastReconciledAt,
        time.toIso8601String(),
      );
    } catch (e) {
      AppLogger.warning(
        '[SyncOrchestrator] Failed to persist reconcile time: $e',
      );
    }
  }
}
