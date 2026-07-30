import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';
import 'package:budgie_breeding_tracker/core/models/sync_conflict.dart';

void main() {
  group('SyncConflict', () {
    test('creates instance with required fields', () {
      final now = DateTime.now();
      final conflict = SyncConflict(
        table: 'birds',
        recordId: 'bird-1',
        detectedAt: now,
        description: 'Server overwrote local data',
      );

      expect(conflict.table, 'birds');
      expect(conflict.recordId, 'bird-1');
      expect(conflict.detectedAt, now);
      expect(conflict.description, 'Server overwrote local data');
      expect(conflict.canRetryLocal, isFalse);
      expect(conflict.wasRestoredLocally, isFalse);
    });

    test('can retry only an unresolved conflict with a local snapshot', () {
      final recoverable = SyncConflict(
        table: 'birds',
        recordId: 'bird-1',
        detectedAt: DateTime(2026, 7, 17),
        description: 'recoverable',
        hasLocalSnapshot: true,
      );
      final resolved = SyncConflict(
        table: 'birds',
        recordId: 'bird-1',
        detectedAt: DateTime(2026, 7, 17),
        description: 'resolved',
        hasLocalSnapshot: true,
        resolvedAt: DateTime(2026, 7, 18),
        conflictType: ConflictType.localOverwritten,
      );

      expect(recoverable.canRetryLocal, isTrue);
      expect(resolved.canRetryLocal, isFalse);
      expect(resolved.wasRestoredLocally, isTrue);
    });

    test('can create multiple instances with different tables', () {
      final now = DateTime.now();
      final birdConflict = SyncConflict(
        table: 'birds',
        recordId: 'b-1',
        detectedAt: now,
        description: 'Bird conflict',
      );
      final eggConflict = SyncConflict(
        table: 'eggs',
        recordId: 'e-1',
        detectedAt: now,
        description: 'Egg conflict',
      );

      expect(birdConflict.table, isNot(eggConflict.table));
      expect(birdConflict.recordId, isNot(eggConflict.recordId));
    });
  });
}
