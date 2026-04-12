part of 'sync_orchestrator.dart';

// ---------------------------------------------------------------------------
// Timestamp persistence and notification processing helpers
// for [SyncOrchestrator]. Top-level private functions accessible
// via the `part` directive.
// ---------------------------------------------------------------------------

extension _SyncTimeHelpers on SyncOrchestrator {
  /// Audits encrypted payloads and migrates legacy formats during reconciliation.
  ///
  /// Runs as part of the 6-hour full reconciliation cycle. Collects all
  /// encrypted field values from local DB, audits their format, and
  /// batch-upgrades any legacy payloads to the current authenticated format.
  /// Reports audit results to Sentry when legacy payloads are found.
  ///
  /// Errors are caught and logged — they should not break the sync cycle.
  /// SharedPreferences key for pending encryption migration flag.
  static const _keyPendingEncryptionMigration =
      'budgie_pending_encryption_migration';

  Future<void> _migrateEncryptedPayloads() async {
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == 'anonymous') return;

      final encryptionService = _ref.read(encryptionServiceProvider);
      final birdsDao = _ref.read(birdsDaoProvider);

      // Fetch only birds with ring numbers (lightweight query).
      // When additional encrypted fields are added (geneticInfo, etc.),
      // add their collection logic here following the same pattern.
      final birds = await birdsDao.getWithRingNumber(userId);
      final encryptedValues = <String>[];
      final idToValue = <String, String>{};
      for (final bird in birds) {
        if (bird.ringNumber != null && bird.ringNumber!.isNotEmpty) {
          if (looksLikeEncrypted(bird.ringNumber!)) {
            encryptedValues.add(bird.ringNumber!);
            idToValue[bird.id] = bird.ringNumber!;
          }
        }
      }

      if (encryptedValues.isEmpty) {
        await _clearPendingMigration();
        return;
      }

      // Audit and report to Sentry
      final audit = encryptionService.auditAndReport(
        encryptedValues,
        source: 'sync_reconciliation',
      );

      if (audit.legacy == 0) {
        await _clearPendingMigration();
        return;
      }

      // Batch re-encrypt legacy payloads (chunk-limited to 50 per cycle)
      final upgraded = await encryptionService.batchReEncrypt(idToValue);
      if (upgraded.isNotEmpty) {
        for (final entry in upgraded.entries) {
          await birdsDao.updateRingNumber(entry.key, entry.value);
        }
        AppLogger.info(
          '[SyncOrchestrator] Encryption migration: '
          '${upgraded.length} ring numbers upgraded',
        );
      }

      // If there are still remaining legacy payloads, flag for next cycle
      final remaining = audit.legacy - upgraded.length;
      if (remaining > 0) {
        await _setPendingMigration();
        AppLogger.info(
          '[SyncOrchestrator] Encryption migration incomplete: '
          '$remaining legacy payloads remaining — will retry next sync cycle',
        );
      } else {
        await _clearPendingMigration();
      }
    } catch (e, st) {
      AppLogger.warning(
        '[SyncOrchestrator] Encryption migration failed: $e',
      );
      Sentry.captureException(e, stackTrace: st);
    }
  }

  /// Returns true if a previous migration cycle was incomplete and
  /// there are still legacy payloads to process.
  Future<bool> _hasPendingMigration() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(_keyPendingEncryptionMigration) ?? false;
    } catch (e) {
      AppLogger.debug('[SyncOrchestrator] Failed to check pending migration: $e');
      return false;
    }
  }

  Future<void> _setPendingMigration() async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(_keyPendingEncryptionMigration, true);
    } catch (e) {
      AppLogger.debug('[SyncOrchestrator] Failed to set pending migration: $e');
    }
  }

  Future<void> _clearPendingMigration() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_keyPendingEncryptionMigration);
    } catch (e) {
      AppLogger.debug('[SyncOrchestrator] Failed to clear pending migration: $e');
    }
  }

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
