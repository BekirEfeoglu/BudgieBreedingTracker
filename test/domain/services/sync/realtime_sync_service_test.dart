import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/domain/services/sync/realtime_sync_service.dart';

void main() {
  group('RealtimeSyncService.shouldSubscribe', () {
    test('requires enabled, online, and authenticated user', () {
      expect(
        RealtimeSyncService.shouldSubscribe(
          enabled: true,
          userId: 'user-1',
          online: true,
        ),
        isTrue,
      );
      expect(
        RealtimeSyncService.shouldSubscribe(
          enabled: false,
          userId: 'user-1',
          online: true,
        ),
        isFalse,
      );
      expect(
        RealtimeSyncService.shouldSubscribe(
          enabled: true,
          userId: 'anonymous',
          online: true,
        ),
        isFalse,
      );
      expect(
        RealtimeSyncService.shouldSubscribe(
          enabled: true,
          userId: 'user-1',
          online: false,
        ),
        isFalse,
      );
      expect(
        RealtimeSyncService.shouldSubscribe(
          enabled: true,
          userId: 'user-1',
          online: true,
          rolloutAllowed: false,
        ),
        isFalse,
      );
    });
  });

  group('RealtimeSyncService rollout helpers', () {
    test('clamps rollout percentage to 0-100', () {
      expect(RealtimeSyncService.normalizeRolloutPercent(-10), 0);
      expect(RealtimeSyncService.normalizeRolloutPercent(5), 5);
      expect(RealtimeSyncService.normalizeRolloutPercent(120), 100);
    });

    test('rollout decisions are deterministic and authenticated only', () {
      expect(
        RealtimeSyncService.isUserInRollout(userId: 'user-1', percent: 100),
        isTrue,
      );
      expect(
        RealtimeSyncService.isUserInRollout(userId: 'user-1', percent: 0),
        isFalse,
      );
      expect(
        RealtimeSyncService.isUserInRollout(userId: 'anonymous', percent: 100),
        isFalse,
      );
      expect(
        RealtimeSyncService.rolloutBucket('user-1'),
        RealtimeSyncService.rolloutBucket('user-1'),
      );
    });
  });

  group('RealtimeSyncService.extractRecordId', () {
    test('reads id from new record first', () {
      final payload = PostgresChangePayload(
        schema: 'public',
        table: 'eggs',
        commitTimestamp: DateTime(2026, 5, 16),
        eventType: PostgresChangeEvent.update,
        newRecord: const {'id': 'new-id'},
        oldRecord: const {'id': 'old-id'},
        errors: null,
      );

      expect(RealtimeSyncService.extractRecordId(payload), 'new-id');
    });

    test('falls back to old record for delete events', () {
      final payload = PostgresChangePayload(
        schema: 'public',
        table: 'eggs',
        commitTimestamp: DateTime(2026, 5, 16),
        eventType: PostgresChangeEvent.delete,
        newRecord: const {},
        oldRecord: const {'id': 'deleted-id'},
        errors: null,
      );

      expect(RealtimeSyncService.extractRecordId(payload), 'deleted-id');
    });
  });
}
