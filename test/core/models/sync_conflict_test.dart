import 'package:flutter_test/flutter_test.dart';

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
