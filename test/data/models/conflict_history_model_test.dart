import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';
import 'package:budgie_breeding_tracker/data/models/conflict_history_model.dart';

void main() {
  group('ConflictHistory model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final model = ConflictHistory(
          id: 'conflict-1',
          userId: 'user-1',
          tableName: 'birds',
          recordId: 'bird-123',
          description: 'Server overwrote local',
          conflictType: ConflictType.serverWins,
          resolvedAt: DateTime(2024, 6, 1),
          createdAt: DateTime(2024, 5, 1),
        );

        final json = model.toJson();
        final restored = ConflictHistory.fromJson(json);

        expect(restored.id, model.id);
        expect(restored.userId, model.userId);
        expect(restored.tableName, model.tableName);
        expect(restored.recordId, model.recordId);
        expect(restored.description, model.description);
        expect(restored.conflictType, model.conflictType);
        expect(restored.resolvedAt, model.resolvedAt);
        expect(restored.createdAt, model.createdAt);
      });

      test('handles null optional fields', () {
        const model = ConflictHistory(
          id: 'conflict-2',
          userId: 'user-1',
          tableName: 'eggs',
          recordId: 'egg-1',
          description: 'Orphan deleted',
          conflictType: ConflictType.orphanDeleted,
        );

        final json = model.toJson();
        final restored = ConflictHistory.fromJson(json);

        expect(restored.resolvedAt, isNull);
        expect(restored.createdAt, isNull);
      });

      test('deserializes unknown conflictType to ConflictType.unknown', () {
        final json = {
          'id': 'conflict-3',
          'user_id': 'user-1',
          'table_name': 'birds',
          'record_id': 'bird-1',
          'description': 'test',
          'conflict_type': 'future_conflict_type',
        };

        final model = ConflictHistory.fromJson(json);
        expect(model.conflictType, ConflictType.unknown);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        const original = ConflictHistory(
          id: 'conflict-1',
          userId: 'user-1',
          tableName: 'birds',
          recordId: 'bird-1',
          description: 'original',
          conflictType: ConflictType.serverWins,
        );

        final now = DateTime.now();
        final copy = original.copyWith(
          resolvedAt: now,
          description: 'resolved',
        );

        expect(copy.resolvedAt, now);
        expect(copy.description, 'resolved');
        expect(copy.id, original.id);
        expect(copy.conflictType, original.conflictType);
      });
    });

    group('equality', () {
      test('two instances with same fields are equal', () {
        const a = ConflictHistory(
          id: 'c1',
          userId: 'u1',
          tableName: 'birds',
          recordId: 'b1',
          description: 'desc',
          conflictType: ConflictType.localOverwritten,
        );
        const b = ConflictHistory(
          id: 'c1',
          userId: 'u1',
          tableName: 'birds',
          recordId: 'b1',
          description: 'desc',
          conflictType: ConflictType.localOverwritten,
        );

        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });
    });
  });
}
