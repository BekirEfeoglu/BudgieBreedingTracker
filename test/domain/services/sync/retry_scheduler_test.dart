import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/retry_scheduler.dart';

void main() {
  SyncMetadata createMetadata({
    required String id,
    required SyncStatus status,
    int? retryCount,
    DateTime? updatedAt,
  }) {
    return SyncMetadata(
      id: id,
      table: 'birds',
      userId: 'user-1',
      status: status,
      retryCount: retryCount,
      recordId: 'record-$id',
      updatedAt: updatedAt,
    );
  }

  group('RetryScheduler', () {
    test('shouldRetry is true below max and false at max', () {
      expect(RetryScheduler.shouldRetry(0), isTrue);
      expect(RetryScheduler.shouldRetry(RetryScheduler.maxRetries - 1), isTrue);
      expect(RetryScheduler.shouldRetry(RetryScheduler.maxRetries), isFalse);
    });

    test('getNextRetryDelay returns zero when max retries reached', () {
      final delay = RetryScheduler.getNextRetryDelay(RetryScheduler.maxRetries);
      expect(delay, Duration.zero);
    });

    test(
      'getNextRetryDelay is capped at maximum delay for high retry counts',
      () {
        final delay = RetryScheduler.getNextRetryDelay(4);
        expect(delay.inMinutes, lessThanOrEqualTo(10));
      },
    );

    test('getNextRetryDelay grows exponentially within jitter range', () {
      final retry0 = RetryScheduler.getNextRetryDelay(0).inSeconds;
      final retry1 = RetryScheduler.getNextRetryDelay(1).inSeconds;
      final retry2 = RetryScheduler.getNextRetryDelay(2).inSeconds;

      expect(retry0, inInclusiveRange(30, 59));
      expect(retry1, inInclusiveRange(60, 89));
      expect(retry2, inInclusiveRange(120, 149));
    });

    test('getNextRetryTime is in the future', () {
      final next = RetryScheduler.getNextRetryTime(0);
      expect(next.isAfter(DateTime.now()), isTrue);
    });

    test(
      'getRetryableRecords returns only error records below max retries',
      () {
        final records = [
          createMetadata(id: '1', status: SyncStatus.error, retryCount: 0),
          createMetadata(
            id: '2',
            status: SyncStatus.error,
            retryCount: RetryScheduler.maxRetries,
          ),
          createMetadata(id: '3', status: SyncStatus.pending, retryCount: 0),
        ];

        final retryable = RetryScheduler.getRetryableRecords(records);
        expect(retryable.map((r) => r.id), ['1']);
      },
    );

    test('isReadyForRetry true when updatedAt is null', () {
      final record = createMetadata(
        id: '1',
        status: SyncStatus.error,
        retryCount: 0,
        updatedAt: null,
      );
      expect(RetryScheduler.isReadyForRetry(record), isTrue);
    });

    test('isReadyForRetry false for a just-updated record', () {
      final record = createMetadata(
        id: '1',
        status: SyncStatus.error,
        retryCount: 0,
        updatedAt: DateTime.now(),
      );
      expect(RetryScheduler.isReadyForRetry(record), isFalse);
    });

    test('isReadyForRetry true for sufficiently old record', () {
      final record = createMetadata(
        id: '1',
        status: SyncStatus.error,
        retryCount: 0,
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );
      expect(RetryScheduler.isReadyForRetry(record), isTrue);
    });

    test('isReadyForRetry false when backoff duration has not elapsed', () {
      final record = createMetadata(
        id: '1',
        status: SyncStatus.error,
        retryCount: 3,
        updatedAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(RetryScheduler.isReadyForRetry(record), isFalse);
    });

    test('isReadyForRetry true when backoff duration has elapsed', () {
      final record = createMetadata(
        id: '1',
        status: SyncStatus.error,
        retryCount: 3,
        updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(RetryScheduler.isReadyForRetry(record), isTrue);
    });

    test('logRetryStatus does not throw', () {
      final record = createMetadata(
        id: '1',
        status: SyncStatus.error,
        retryCount: 1,
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(() => RetryScheduler.logRetryStatus(record), returnsNormally);
    });
  });
}
