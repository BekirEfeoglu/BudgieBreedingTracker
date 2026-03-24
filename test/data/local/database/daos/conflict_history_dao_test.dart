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
  });
}
