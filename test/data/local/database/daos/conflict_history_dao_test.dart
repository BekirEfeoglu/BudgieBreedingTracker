import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/conflict_history_model.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  group('ConflictHistoryDao', () {
    final conflict = ConflictHistory(
      id: 'c1',
      userId: 'u1',
      tableName: 'eggs',
      recordId: 'e1',
      description: 'Egg #3',
      conflictType: ConflictType.serverWins,
      createdAt: DateTime.now(),
    );

    test('insert and watchAll returns conflict', () async {
      await db.conflictHistoryDao.insert(conflict);
      final results = await db.conflictHistoryDao.watchAll('u1').first;
      expect(results, hasLength(1));
      expect(results.first.tableName, 'eggs');
      expect(results.first.conflictType, ConflictType.serverWins);
    });

    test('watchAll is user-scoped', () async {
      await db.conflictHistoryDao.insert(conflict);
      final results = await db.conflictHistoryDao.watchAll('other').first;
      expect(results, isEmpty);
    });

    test('deleteAll removes all for user', () async {
      await db.conflictHistoryDao.insert(conflict);
      await db.conflictHistoryDao.deleteAll('u1');
      final results = await db.conflictHistoryDao.watchAll('u1').first;
      expect(results, isEmpty);
    });

    test('deleteOlderThan removes old records', () async {
      final old = conflict.copyWith(
        id: 'c-old',
        createdAt: DateTime.now().subtract(const Duration(days: 31)),
      );
      await db.conflictHistoryDao.insert(old);
      await db.conflictHistoryDao.insert(conflict);
      await db.conflictHistoryDao.deleteOlderThan(30);
      final results = await db.conflictHistoryDao.watchAll('u1').first;
      expect(results, hasLength(1));
      expect(results.first.id, 'c1');
    });

    test('watchRecentCount returns count within duration', () async {
      await db.conflictHistoryDao.insert(conflict);
      final count = await db.conflictHistoryDao
          .watchRecentCount('u1', const Duration(hours: 24))
          .first;
      expect(count, 1);
    });

    test('insertAll persists payloads and resolution is atomic', () async {
      final recoverable = conflict.copyWith(
        id: 'recoverable',
        localPayload: 'encrypted-local',
        serverPayload: 'encrypted-server',
        payloadVersion: 1,
      );
      await db.conflictHistoryDao.insertAll([recoverable]);

      final unresolved = await db.conflictHistoryDao.getUnresolved('u1');
      expect(unresolved, hasLength(1));
      expect(unresolved.single.localPayload, 'encrypted-local');
      expect(unresolved.single.serverPayload, 'encrypted-server');

      final updated = await db.conflictHistoryDao.markResolvedIfUnresolved(
        'recoverable',
        DateTime.utc(2026, 7, 17),
        conflictType: ConflictType.localOverwritten,
      );
      final duplicate = await db.conflictHistoryDao.markResolvedIfUnresolved(
        'recoverable',
        DateTime.utc(2026, 7, 18),
      );

      expect(updated, 1);
      expect(duplicate, 0);
      expect(await db.conflictHistoryDao.getUnresolved('u1'), isEmpty);
      expect(
        (await db.conflictHistoryDao.getById('recoverable'))?.conflictType,
        ConflictType.localOverwritten,
      );
      expect(
        await db.conflictHistoryDao
            .watchRecentCount('u1', const Duration(days: 1))
            .first,
        0,
      );
    });

    test(
      'repeated unresolved conflict preserves oldest local payload',
      () async {
        final first = conflict.copyWith(
          id: 'first',
          localPayload: 'encrypted-original-local',
          serverPayload: 'encrypted-server-v1',
          payloadVersion: 1,
          createdAt: DateTime.utc(2026, 7, 17, 10),
        );
        final repeated = conflict.copyWith(
          id: 'repeated',
          localPayload: 'encrypted-server-v1',
          serverPayload: 'encrypted-server-v1',
          payloadVersion: 1,
          createdAt: DateTime.utc(2026, 7, 17, 11),
        );

        final firstInsert = await db.conflictHistoryDao
            .insertAllPreservingOldestRecoverable([first]);
        final repeatedInsert = await db.conflictHistoryDao
            .insertAllPreservingOldestRecoverable([repeated]);

        final unresolved = await db.conflictHistoryDao.getUnresolved('u1');
        expect(firstInsert, 1);
        expect(repeatedInsert, 0);
        expect(unresolved, hasLength(1));
        expect(unresolved.single.id, 'first');
        expect(unresolved.single.localPayload, 'encrypted-original-local');
      },
    );
  });
}
