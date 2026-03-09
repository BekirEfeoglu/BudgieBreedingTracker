import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';

void main() {
  late AppDatabase db;
  late SyncMetadataDao dao;

  const userId = 'user-1';
  const otherId = 'user-2';

  // NOTE: Schema v12 adds UNIQUE(table_name, record_id) on sync_metadata.
  // Each test entry must use a unique (table, recordId) pair unless
  // intentionally testing upsert behavior on the same record.
  SyncMetadata makeEntry({
    String id = 'sync-1',
    String table = 'birds',
    String user = userId,
    String? recordId = 'bird-1',
    SyncStatus status = SyncStatus.pending,
    int? retryCount,
    String? errorMessage,
    DateTime? createdAt,
  }) {
    return SyncMetadata(
      id: id,
      table: table,
      userId: user,
      recordId: recordId,
      status: status,
      retryCount: retryCount,
      errorMessage: errorMessage,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.syncMetadataDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('insertItem', () {
    test('inserts and retrieves a single entry', () async {
      final entry = makeEntry();
      await dao.insertItem(entry);

      final result = await dao.getById(entry.id);
      expect(result, isNotNull);
      expect(result!.id, equals('sync-1'));
      expect(result.table, equals('birds'));
      expect(result.recordId, equals('bird-1'));
      expect(result.status, equals(SyncStatus.pending));
    });

    test('upserts on conflict — updates existing entry', () async {
      await dao.insertItem(makeEntry(errorMessage: 'old'));
      await dao.insertItem(makeEntry(errorMessage: 'new'));

      final result = await dao.getById('sync-1');
      expect(result!.errorMessage, equals('new'));
    });
  });

  group('insertAll', () {
    test('inserts multiple entries in batch', () async {
      final entries = List.generate(
        5,
        (i) => makeEntry(id: 'sync-${i + 1}', recordId: 'bird-${i + 1}'),
      );
      await dao.insertAll(entries);

      final all = await dao.getAll(userId);
      expect(all.length, equals(5));
    });

    test('empty list completes without error', () async {
      await expectLater(dao.insertAll([]), completes);
    });
  });

  group('getAll', () {
    test('returns entries for the given user only', () async {
      await dao.insertItem(makeEntry(id: 'sync-1', user: userId));
      await dao.insertItem(
        makeEntry(id: 'sync-2', user: otherId, recordId: 'bird-2'),
      );

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
      expect(results.first.userId, equals(userId));
    });
  });

  group('watchAll', () {
    test('emits entries for the given user only', () async {
      await dao.insertItem(makeEntry(id: 'sync-1', user: userId));
      await dao.insertItem(
        makeEntry(id: 'sync-2', user: otherId, recordId: 'bird-2'),
      );

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('sync-1'));
    });

    test('emits empty list when no entries exist', () async {
      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });
  });

  group('hardDelete', () {
    test('permanently removes the entry', () async {
      await dao.insertItem(makeEntry());
      await dao.hardDelete('sync-1');

      final row = await dao.getById('sync-1');
      expect(row, isNull);
    });
  });

  group('getPending', () {
    test('returns only pending entries', () async {
      await dao.insertItem(makeEntry(id: 'sync-1', status: SyncStatus.pending));
      await dao.insertItem(
        makeEntry(id: 'sync-2', status: SyncStatus.error, recordId: 'bird-2'),
      );
      await dao.insertItem(
        makeEntry(id: 'sync-3', status: SyncStatus.synced, recordId: 'bird-3'),
      );

      final pending = await dao.getPending(userId);
      expect(pending.length, equals(1));
      expect(pending.first.id, equals('sync-1'));
    });

    test('scoped by userId', () async {
      await dao.insertItem(makeEntry(id: 'sync-1', user: userId));
      await dao.insertItem(
        makeEntry(id: 'sync-2', user: otherId, recordId: 'bird-2'),
      );

      final pending = await dao.getPending(userId);
      expect(pending.length, equals(1));
    });
  });

  group('getPendingByTable', () {
    test('filters by both status and table', () async {
      await dao.insertItem(
        makeEntry(id: 'sync-1', table: 'birds', status: SyncStatus.pending),
      );
      await dao.insertItem(
        makeEntry(
          id: 'sync-2',
          table: 'eggs',
          status: SyncStatus.pending,
          recordId: 'egg-1',
        ),
      );
      await dao.insertItem(
        makeEntry(
          id: 'sync-3',
          table: 'birds',
          status: SyncStatus.error,
          recordId: 'bird-2',
        ),
      );

      final result = await dao.getPendingByTable(userId, 'birds');
      expect(result.length, equals(1));
      expect(result.first.id, equals('sync-1'));
    });
  });

  group('getErrorsByTable', () {
    test('returns only error entries for specific table', () async {
      await dao.insertItem(
        makeEntry(id: 'sync-1', table: 'birds', status: SyncStatus.error),
      );
      await dao.insertItem(
        makeEntry(
          id: 'sync-2',
          table: 'eggs',
          status: SyncStatus.error,
          recordId: 'egg-1',
        ),
      );
      await dao.insertItem(
        makeEntry(
          id: 'sync-3',
          table: 'birds',
          status: SyncStatus.pending,
          recordId: 'bird-2',
        ),
      );

      final result = await dao.getErrorsByTable(userId, 'birds');
      expect(result.length, equals(1));
      expect(result.first.id, equals('sync-1'));
    });
  });

  group('getPendingRecordIds', () {
    test('returns set of record IDs for pending entries', () async {
      await dao.insertItem(makeEntry(id: 'sync-1', recordId: 'bird-1'));
      await dao.insertItem(makeEntry(id: 'sync-2', recordId: 'bird-2'));
      await dao.insertItem(
        makeEntry(id: 'sync-3', recordId: 'bird-3', status: SyncStatus.error),
      );

      final ids = await dao.getPendingRecordIds(userId);
      expect(ids, equals({'bird-1', 'bird-2', 'bird-3'}));
    });
  });

  group('getPendingTableNames', () {
    test('returns distinct table names with pending entries', () async {
      await dao.insertItem(
        makeEntry(id: 'sync-1', table: 'birds', recordId: 'b-1'),
      );
      await dao.insertItem(
        makeEntry(id: 'sync-2', table: 'birds', recordId: 'b-2'),
      );
      await dao.insertItem(
        makeEntry(id: 'sync-3', table: 'eggs', recordId: 'e-1'),
      );
      await dao.insertItem(
        makeEntry(
          id: 'sync-4',
          table: 'chicks',
          recordId: 'c-1',
          status: SyncStatus.error,
        ),
      );

      final tables = await dao.getPendingTableNames(userId);
      expect(tables, equals({'birds', 'eggs'}));
    });
  });

  group('countPending', () {
    test('returns correct count of pending entries', () async {
      await dao.insertItem(makeEntry(id: 'sync-1', status: SyncStatus.pending));
      await dao.insertItem(
        makeEntry(id: 'sync-2', status: SyncStatus.pending, recordId: 'bird-2'),
      );
      await dao.insertItem(
        makeEntry(id: 'sync-3', status: SyncStatus.error, recordId: 'bird-3'),
      );

      final count = await dao.countPending(userId);
      expect(count, equals(2));
    });

    test('returns 0 when no pending entries', () async {
      final count = await dao.countPending(userId);
      expect(count, equals(0));
    });
  });

  group('getErrors', () {
    test('returns only error entries', () async {
      await dao.insertItem(
        makeEntry(id: 'sync-1', status: SyncStatus.error, errorMessage: 'fail'),
      );
      await dao.insertItem(
        makeEntry(id: 'sync-2', status: SyncStatus.pending, recordId: 'bird-2'),
      );

      final errors = await dao.getErrors(userId);
      expect(errors.length, equals(1));
      expect(errors.first.errorMessage, equals('fail'));
    });
  });

  group('updateStatus', () {
    test('changes status of existing entry', () async {
      await dao.insertItem(makeEntry(status: SyncStatus.pending));
      await dao.updateStatus('sync-1', SyncStatus.synced);

      final result = await dao.getById('sync-1');
      expect(result!.status, equals(SyncStatus.synced));
    });
  });

  group('getByRecord', () {
    test('finds entry by table and recordId combination', () async {
      await dao.insertItem(
        makeEntry(id: 'sync-1', table: 'birds', recordId: 'bird-1'),
      );
      await dao.insertItem(
        makeEntry(id: 'sync-2', table: 'eggs', recordId: 'egg-1'),
      );

      final result = await dao.getByRecord('birds', 'bird-1');
      expect(result, isNotNull);
      expect(result!.id, equals('sync-1'));
    });

    test('returns null when not found', () async {
      final result = await dao.getByRecord('birds', 'nonexistent');
      expect(result, isNull);
    });
  });

  group('deleteByRecord', () {
    test('removes entry by table and recordId', () async {
      await dao.insertItem(
        makeEntry(id: 'sync-1', table: 'birds', recordId: 'bird-1'),
      );
      await dao.deleteByRecord('birds', 'bird-1');

      final result = await dao.getByRecord('birds', 'bird-1');
      expect(result, isNull);
    });

    test('does not affect other records', () async {
      await dao.insertItem(
        makeEntry(id: 'sync-1', table: 'birds', recordId: 'bird-1'),
      );
      await dao.insertItem(
        makeEntry(id: 'sync-2', table: 'eggs', recordId: 'egg-1'),
      );

      await dao.deleteByRecord('birds', 'bird-1');

      final remaining = await dao.getAll(userId);
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('sync-2'));
    });
  });
}
