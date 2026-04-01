import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/conflict_history_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/conflict_history_model.dart';

void main() {
  group('ConflictHistoryRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      final created = DateTime(2024, 5, 1);
      final resolved = DateTime(2024, 5, 2);

      final row = ConflictHistoryRow(
        id: 'c1',
        userId: 'u1',
        tableName_: 'birds',
        recordId: 'b1',
        description: 'Server overwrote local',
        conflictType: ConflictType.serverWins,
        resolvedAt: resolved,
        createdAt: created,
      );

      final model = row.toModel();

      expect(model.id, 'c1');
      expect(model.userId, 'u1');
      expect(model.tableName, 'birds');
      expect(model.recordId, 'b1');
      expect(model.description, 'Server overwrote local');
      expect(model.conflictType, ConflictType.serverWins);
      expect(model.resolvedAt, resolved);
      expect(model.createdAt, created);
    });

    test('maps null optional fields', () {
      const row = ConflictHistoryRow(
        id: 'c2',
        userId: 'u1',
        tableName_: 'eggs',
        recordId: 'e1',
        description: 'test',
        conflictType: ConflictType.orphanDeleted,
      );

      final model = row.toModel();

      expect(model.resolvedAt, isNull);
      expect(model.createdAt, isNull);
    });
  });

  group('ConflictHistoryModelMapper.toCompanion()', () {
    test('maps all fields to companion with Value wrappers', () {
      final created = DateTime(2024, 5, 1);
      final resolved = DateTime(2024, 5, 2);

      final model = ConflictHistory(
        id: 'c1',
        userId: 'u1',
        tableName: 'birds',
        recordId: 'b1',
        description: 'Server overwrote local',
        conflictType: ConflictType.serverWins,
        resolvedAt: resolved,
        createdAt: created,
      );

      final companion = model.toCompanion();

      expect(companion.id, const Value('c1'));
      expect(companion.userId, const Value('u1'));
      expect(companion.tableName_, const Value('birds'));
      expect(companion.recordId, const Value('b1'));
      expect(companion.description, const Value('Server overwrote local'));
      expect(companion.conflictType, const Value(ConflictType.serverWins));
      expect(companion.resolvedAt, Value(resolved));
    });

    test('sets createdAt to now when null in model', () {
      const model = ConflictHistory(
        id: 'c2',
        userId: 'u1',
        tableName: 'eggs',
        recordId: 'e1',
        description: 'test',
        conflictType: ConflictType.unknown,
      );

      final companion = model.toCompanion();
      final createdValue = companion.createdAt.value;

      expect(createdValue, isNotNull);
      // Should be approximately now (within 5 seconds)
      expect(
        createdValue!.difference(DateTime.now()).inSeconds.abs(),
        lessThan(5),
      );
    });
  });

  group('round-trip', () {
    test('Row → Model → Companion preserves all fields', () {
      final created = DateTime(2024, 5, 1);

      final row = ConflictHistoryRow(
        id: 'c1',
        userId: 'u1',
        tableName_: 'birds',
        recordId: 'b1',
        description: 'round-trip test',
        conflictType: ConflictType.localOverwritten,
        createdAt: created,
      );

      final model = row.toModel();
      final companion = model.toCompanion();

      expect(companion.id.value, row.id);
      expect(companion.userId.value, row.userId);
      expect(companion.tableName_.value, row.tableName_);
      expect(companion.recordId.value, row.recordId);
      expect(companion.description.value, row.description);
      expect(companion.conflictType.value, row.conflictType);
      expect(companion.createdAt.value, row.createdAt);
    });
  });
}
