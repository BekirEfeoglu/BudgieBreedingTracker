import 'dart:math';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';

/// Manages exponential backoff retry logic for failed sync operations.
abstract class RetryScheduler {
  static const _tag = '[RetryScheduler]';

  /// Maximum number of retry attempts before giving up.
  static const int maxRetries = 5;

  /// Base delay for exponential backoff (in seconds).
  static const int _baseDelaySec = 30;

  /// Maximum delay cap (10 minutes).
  static const Duration _maxDelay = Duration(minutes: 10);

  /// Whether a record should be retried based on its retry count.
  static bool shouldRetry(int retryCount) {
    return retryCount < maxRetries;
  }

  /// Calculate the next retry delay using exponential backoff with proportional jitter.
  ///
  /// Formula: min(base * 2^retryCount + jitter(20% of delay), maxDelay)
  /// Proportional jitter prevents thundering herd by distributing retries
  /// more evenly across a wider time window at higher retry counts.
  static Duration getNextRetryDelay(int retryCount) {
    if (retryCount >= maxRetries) return Duration.zero;

    final exponentialDelay = _baseDelaySec * pow(2, retryCount).toInt();
    // 20% of exponential delay as jitter range (min 1 second)
    final jitterRange = max(1, (exponentialDelay * 0.2).ceil());
    final jitter = Random().nextInt(jitterRange);
    final totalSeconds = exponentialDelay + jitter;

    final delay = Duration(seconds: totalSeconds);
    return delay > _maxDelay ? _maxDelay : delay;
  }

  /// Get the estimated next retry time from now.
  static DateTime getNextRetryTime(int retryCount) {
    final delay = getNextRetryDelay(retryCount);
    return DateTime.now().add(delay);
  }

  /// Filter sync metadata records that are eligible for retry.
  ///
  /// Returns records that:
  /// - Have retryCount < maxRetries
  /// - Have status == 'error'
  static List<SyncMetadata> getRetryableRecords(List<SyncMetadata> records) {
    return records.where((record) {
      final isError = record.status == SyncStatus.error;
      final canRetry = shouldRetry(record.retryCount ?? 0);
      return isError && canRetry;
    }).toList();
  }

  /// Check if enough time has passed since last attempt for a record.
  static bool isReadyForRetry(SyncMetadata record) {
    if (record.updatedAt == null) return true;

    final delay = getNextRetryDelay(record.retryCount ?? 0);
    final nextRetryAt = record.updatedAt!.add(delay);
    return DateTime.now().isAfter(nextRetryAt);
  }

  /// Log retry status for debugging.
  static void logRetryStatus(SyncMetadata record) {
    final retryCount = record.retryCount ?? 0;
    final delay = getNextRetryDelay(retryCount);
    final ready = isReadyForRetry(record);
    AppLogger.info(
      '$_tag Record ${record.recordId} (${record.table}): '
      'retry $retryCount/$maxRetries, '
      'next delay: ${delay.inSeconds}s, '
      'ready: $ready',
    );
  }
}
