import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/sync_metadata_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';

void main() {
  group('SyncMetadataRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      final lastSynced = DateTime.utc(2024, 6, 1);
      final row = SyncMetadataRow(
        id: 'sm1',
        tableName_: 'birds',
        userId: 'u1',
        status: SyncStatus.pending,
        recordId: 'b1',
        errorMessage: null,
        retryCount: 0,
        lastSyncedAt: lastSynced,
      );
      final model = row.toModel();

      expect(model.id, 'sm1');
      expect(model.table, 'birds');
      expect(model.userId, 'u1');
      expect(model.status, SyncStatus.pending);
      expect(model.recordId, 'b1');
      expect(model.errorMessage, isNull);
      expect(model.retryCount, 0);
      expect(model.lastSyncedAt, lastSynced);
    });

    test('maps error state correctly', () {
      const row = SyncMetadataRow(
        id: 'sm2',
        tableName_: 'eggs',
        userId: 'u1',
        status: SyncStatus.error,
        recordId: 'e1',
        errorMessage: 'Network timeout',
        retryCount: 3,
      );
      final model = row.toModel();

      expect(model.status, SyncStatus.error);
      expect(model.errorMessage, 'Network timeout');
      expect(model.retryCount, 3);
    });
  });

  group('SyncMetadataModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      const model = SyncMetadata(
        id: 'sm1',
        table: 'birds',
        userId: 'u1',
        status: SyncStatus.pending,
        recordId: 'b1',
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'sm1');
      expect(companion.tableName_.value, 'birds');
      expect(companion.userId.value, 'u1');
      expect(companion.status.value, SyncStatus.pending);
      expect(companion.recordId.value, 'b1');
    });

    test('maps table field to tableName_ column', () {
      const model = SyncMetadata(id: 'sm1', table: 'chicks', userId: 'u1');
      final companion = model.toCompanion();

      expect(companion.tableName_.value, 'chicks');
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      const model = SyncMetadata(id: 'sm1', table: 'birds', userId: 'u1');
      final companion = model.toCompanion();

      expect(
        companion.updatedAt.value!.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });
  });
}
