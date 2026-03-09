import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/retry_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_push_handler.dart';

/// Handles sync error retry and cleanup operations.
///
/// Retries failed sync records based on exponential backoff schedule
/// and cleans up unrecoverable errors after 24 hours.
class SyncErrorHandler {
  SyncErrorHandler(this._ref, this._pushHandler);

  final Ref _ref;
  final SyncPushHandler _pushHandler;

  /// Retries failed sync records that are eligible based on [RetryScheduler].
  ///
  /// Filters error records whose backoff delay has elapsed and re-triggers
  /// pushAll for each affected repository.
  Future<void> retryFailedRecords(String userId) async {
    final syncMetadataRepo = _ref.read(syncMetadataRepositoryProvider);
    final errors = await syncMetadataRepo.getErrors(userId);

    final retryable = RetryScheduler.getRetryableRecords(errors);
    if (retryable.isEmpty) return;

    final readyRecords = retryable.where(RetryScheduler.isReadyForRetry).toList();
    if (readyRecords.isEmpty) return;

    AppLogger.info(
      '[SyncOrchestrator] Retrying ${readyRecords.length} failed records',
    );

    // Group by table and re-push affected tables
    final tables = readyRecords.map((r) => r.table).toSet();
    for (final table in tables) {
      await _pushHandler.pushTable(userId, table);
    }
  }

  /// Removes sync metadata records that have exceeded max retries and
  /// are older than 24 hours. These records are considered unrecoverable.
  /// Returns the number of cleaned up records.
  Future<int> cleanupUnrecoverableErrors(String userId) async {
    final syncDao = _ref.read(syncMetadataDaoProvider);
    final count = await syncDao.deleteStaleErrors(
      userId,
      const Duration(hours: 24),
      RetryScheduler.maxRetries,
    );
    if (count > 0) {
      AppLogger.info(
        '[SyncOrchestrator] Cleaned up $count unrecoverable sync errors',
      );
    }
    return count;
  }
}
