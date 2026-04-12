import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';

SyncMetadata _buildMetadata({
  String id = 'sync-1',
  String table = 'birds',
  String userId = 'user-1',
  SyncStatus status = SyncStatus.pending,
  String? recordId,
  String? errorMessage,
  int? retryCount,
  DateTime? lastSyncedAt,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return SyncMetadata(
    id: id,
    table: table,
    userId: userId,
    status: status,
    recordId: recordId,
    errorMessage: errorMessage,
    retryCount: retryCount,
    lastSyncedAt: lastSyncedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

void main() {
  group('SyncMetadata model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final metadata = _buildMetadata(
          id: 'sync-42',
          table: 'eggs',
          userId: 'user-42',
          status: SyncStatus.error,
          recordId: 'egg-1',
          errorMessage: 'Network timeout',
          retryCount: 2,
          lastSyncedAt: DateTime(2024, 2, 1, 12, 0),
          createdAt: DateTime(2024, 2, 1, 8, 0),
          updatedAt: DateTime(2024, 2, 1, 9, 0),
        );

        final restored = SyncMetadata.fromJson(metadata.toJson());
        expect(restored, metadata);
      });

      test('applies default status pending', () {
        final metadata = SyncMetadata.fromJson({
          'id': 'sync-1',
          'table_name': 'birds',
          'user_id': 'user-1',
        });

        expect(metadata.status, SyncStatus.pending);
      });

      test('falls back to pending for unknown status', () {
        final metadata = SyncMetadata.fromJson({
          'id': 'sync-1',
          'table_name': 'birds',
          'user_id': 'user-1',
          'status': 'not-a-status',
        });

        expect(metadata.status, SyncStatus.pending);
      });
    });

    group('copyWith', () {
      test('updates selected fields', () {
        final metadata = _buildMetadata(
          status: SyncStatus.pending,
          retryCount: 0,
        );
        final updated = metadata.copyWith(
          status: SyncStatus.error,
          retryCount: 1,
          errorMessage: 'Failed',
        );

        expect(updated.status, SyncStatus.error);
        expect(updated.retryCount, 1);
        expect(updated.errorMessage, 'Failed');
        expect(updated.id, metadata.id);
        expect(updated.table, metadata.table);
      });
    });
  });

  group('SyncStatus enum', () {
    test('toJson and fromJson work for all values', () {
      for (final status in SyncStatus.values) {
        final json = status.toJson();
        expect(SyncStatus.fromJson(json), status);
      }
    });
  });
}
