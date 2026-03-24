import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  SyncMetadata makeError(String id, String table) => SyncMetadata(
        id: id,
        table: table,
        userId: 'u1',
        status: SyncStatus.error,
        recordId: 'r-$id',
        errorMessage: 'Network timeout',
        retryCount: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  SyncMetadata makePending(String id, String table) => SyncMetadata(
        id: id,
        table: table,
        userId: 'u1',
        status: SyncStatus.pending,
        recordId: 'r-$id',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  group('watchErrorsByTable', () {
    test('groups errors by table with count', () async {
      await db.syncMetadataDao.insertItem(makeError('e1', 'eggs'));
      await db.syncMetadataDao.insertItem(makeError('e2', 'eggs'));
      await db.syncMetadataDao.insertItem(makeError('b1', 'birds'));

      final results =
          await db.syncMetadataDao.watchErrorsByTable('u1').first;
      expect(results, hasLength(2));
      final eggs = results.firstWhere((d) => d.tableName == 'eggs');
      expect(eggs.errorCount, 2);
      final birds = results.firstWhere((d) => d.tableName == 'birds');
      expect(birds.errorCount, 1);
    });

    test('returns empty list when no errors', () async {
      final results =
          await db.syncMetadataDao.watchErrorsByTable('u1').first;
      expect(results, isEmpty);
    });

    test('does not include pending records', () async {
      await db.syncMetadataDao.insertItem(makePending('p1', 'eggs'));
      await db.syncMetadataDao.insertItem(makeError('e1', 'eggs'));

      final results =
          await db.syncMetadataDao.watchErrorsByTable('u1').first;
      expect(results, hasLength(1));
      expect(results.first.errorCount, 1);
    });

    test('scopes to the given userId', () async {
      await db.syncMetadataDao.insertItem(makeError('e1', 'eggs'));
      await db.syncMetadataDao.insertItem(
        SyncMetadata(
          id: 'e2',
          table: 'eggs',
          userId: 'other-user',
          status: SyncStatus.error,
          recordId: 'r-e2',
          errorMessage: 'fail',
          retryCount: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final results =
          await db.syncMetadataDao.watchErrorsByTable('u1').first;
      expect(results, hasLength(1));
      expect(results.first.errorCount, 1);
    });
  });

  group('watchPendingByTable', () {
    test('groups pending by table with count', () async {
      await db.syncMetadataDao.insertItem(makePending('p1', 'eggs'));
      await db.syncMetadataDao.insertItem(makePending('p2', 'chicks'));
      await db.syncMetadataDao.insertItem(makePending('p3', 'chicks'));

      final results =
          await db.syncMetadataDao.watchPendingByTable('u1').first;
      expect(results, hasLength(2));
      final chicks = results.firstWhere((d) => d.tableName == 'chicks');
      expect(chicks.errorCount, 2);
    });

    test('returns empty list when no pending records', () async {
      final results =
          await db.syncMetadataDao.watchPendingByTable('u1').first;
      expect(results, isEmpty);
    });

    test('does not include error records', () async {
      await db.syncMetadataDao.insertItem(makeError('e1', 'birds'));
      await db.syncMetadataDao.insertItem(makePending('p1', 'birds'));

      final results =
          await db.syncMetadataDao.watchPendingByTable('u1').first;
      expect(results, hasLength(1));
      expect(results.first.errorCount, 1);
    });
  });
}
