import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/clutches_dao.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';

void main() {
  late AppDatabase db;
  late ClutchesDao dao;

  const userId = 'user-1';
  const otherId = 'user-2';

  Clutch makeEntry({
    String id = 'clutch-1',
    String user = userId,
    String? breedingId = 'pair-1',
    bool isDeleted = false,
  }) {
    return Clutch(
      id: id,
      userId: user,
      breedingId: breedingId,
      isDeleted: isDeleted,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.clutchesDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('watchAll', () {
    test('returns non-deleted clutches for the user', () async {
      await dao.insertItem(makeEntry(id: 'c-1'));
      await dao.insertItem(makeEntry(id: 'c-2'));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(2));
    });

    test('excludes soft-deleted clutches', () async {
      await dao.insertItem(makeEntry(id: 'c-1'));
      await dao.insertItem(makeEntry(id: 'c-2', isDeleted: true));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('c-1'));
    });

    test('does not return clutches for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'c-1', user: userId));
      await dao.insertItem(makeEntry(id: 'c-2', user: otherId));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('c-1'));
    });

    test('returns empty list when no clutches exist', () async {
      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });

    test('returns empty when all clutches are soft-deleted', () async {
      await dao.insertItem(makeEntry(id: 'c-1', isDeleted: true));
      await dao.insertItem(makeEntry(id: 'c-2', isDeleted: true));

      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });
  });

  group('watchById', () {
    test('returns the clutch when it exists', () async {
      await dao.insertItem(makeEntry(id: 'c-1'));

      final result = await dao.watchById('c-1').first;
      expect(result, isNotNull);
      expect(result!.id, equals('c-1'));
    });

    test('returns null when clutch does not exist', () async {
      final result = await dao.watchById('non-existent').first;
      expect(result, isNull);
    });

    test(
      'returns soft-deleted clutch (no isDeleted filter on watchById)',
      () async {
        await dao.insertItem(makeEntry(id: 'c-1', isDeleted: true));

        final result = await dao.watchById('c-1').first;
        expect(result, isNotNull);
        expect(result!.isDeleted, isTrue);
      },
    );
  });

  group('getAll', () {
    test('returns non-deleted clutches for the user', () async {
      await dao.insertItem(makeEntry(id: 'c-1'));
      await dao.insertItem(makeEntry(id: 'c-2'));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });

    test('excludes soft-deleted clutches', () async {
      await dao.insertItem(makeEntry(id: 'c-1'));
      await dao.insertItem(makeEntry(id: 'c-2', isDeleted: true));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('does not return clutches for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'c-1', user: userId));
      await dao.insertItem(makeEntry(id: 'c-2', user: otherId));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('returns empty list when no clutches exist', () async {
      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('getById', () {
    test('returns the clutch when it exists', () async {
      await dao.insertItem(makeEntry(id: 'c-1'));

      final result = await dao.getById('c-1');
      expect(result, isNotNull);
      expect(result!.id, equals('c-1'));
      expect(result.userId, equals(userId));
    });

    test('returns null when clutch does not exist', () async {
      final result = await dao.getById('non-existent');
      expect(result, isNull);
    });
  });

  group('insertItem', () {
    test('inserts a new clutch', () async {
      await dao.insertItem(makeEntry(id: 'c-1'));

      final result = await dao.getById('c-1');
      expect(result, isNotNull);
      expect(result!.breedingId, equals('pair-1'));
    });

    test('upserts on conflict (updates existing)', () async {
      await dao.insertItem(makeEntry(id: 'c-1', breedingId: 'pair-1'));
      await dao.insertItem(makeEntry(id: 'c-1', breedingId: 'pair-2'));

      final result = await dao.getById('c-1');
      expect(result, isNotNull);
      expect(result!.breedingId, equals('pair-2'));
    });
  });

  group('insertAll', () {
    test('inserts multiple clutches in batch', () async {
      final items = [
        makeEntry(id: 'c-1'),
        makeEntry(id: 'c-2'),
        makeEntry(id: 'c-3'),
      ];
      await dao.insertAll(items);

      final results = await dao.getAll(userId);
      expect(results.length, equals(3));
    });

    test('handles empty list gracefully', () async {
      await dao.insertAll([]);

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });

    test('upserts on conflict within batch', () async {
      await dao.insertItem(makeEntry(id: 'c-1', breedingId: 'pair-1'));
      await dao.insertAll([
        makeEntry(id: 'c-1', breedingId: 'pair-updated'),
        makeEntry(id: 'c-2'),
      ]);

      final updated = await dao.getById('c-1');
      expect(updated!.breedingId, equals('pair-updated'));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });
  });

  group('softDelete', () {
    test('sets isDeleted to true', () async {
      await dao.insertItem(makeEntry(id: 'c-1'));

      await dao.softDelete('c-1');

      final result = await dao.getById('c-1');
      expect(result, isNotNull);
      expect(result!.isDeleted, isTrue);
    });

    test('excluded from watchAll after soft delete', () async {
      await dao.insertItem(makeEntry(id: 'c-1'));
      await dao.insertItem(makeEntry(id: 'c-2'));

      await dao.softDelete('c-1');

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('c-2'));
    });

    test('excluded from getAll after soft delete', () async {
      await dao.insertItem(makeEntry(id: 'c-1'));

      await dao.softDelete('c-1');

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });

    test('does not affect other clutches', () async {
      await dao.insertItem(makeEntry(id: 'c-1'));
      await dao.insertItem(makeEntry(id: 'c-2'));

      await dao.softDelete('c-1');

      final c2 = await dao.getById('c-2');
      expect(c2, isNotNull);
      expect(c2!.isDeleted, isFalse);
    });
  });

  group('hardDelete', () {
    test('permanently removes the clutch', () async {
      await dao.insertItem(makeEntry(id: 'c-1'));

      await dao.hardDelete('c-1');

      final result = await dao.getById('c-1');
      expect(result, isNull);
    });

    test('does not affect other clutches', () async {
      await dao.insertItem(makeEntry(id: 'c-1'));
      await dao.insertItem(makeEntry(id: 'c-2'));

      await dao.hardDelete('c-1');

      final remaining = await dao.getAll(userId);
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('c-2'));
    });

    test('is a no-op when clutch does not exist', () async {
      await dao.hardDelete('non-existent');

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('getByBreeding', () {
    test('returns clutches for the given breeding pair', () async {
      await dao.insertItem(makeEntry(id: 'c-1', breedingId: 'pair-1'));
      await dao.insertItem(makeEntry(id: 'c-2', breedingId: 'pair-1'));
      await dao.insertItem(makeEntry(id: 'c-3', breedingId: 'pair-2'));

      final results = await dao.getByBreeding('pair-1');
      expect(results.length, equals(2));
      final ids = results.map((c) => c.id).toSet();
      expect(ids, containsAll(['c-1', 'c-2']));
    });

    test('excludes soft-deleted clutches', () async {
      await dao.insertItem(makeEntry(id: 'c-1', breedingId: 'pair-1'));
      await dao.insertItem(
        makeEntry(id: 'c-2', breedingId: 'pair-1', isDeleted: true),
      );

      final results = await dao.getByBreeding('pair-1');
      expect(results.length, equals(1));
      expect(results.first.id, equals('c-1'));
    });

    test('returns empty list when no clutches match', () async {
      await dao.insertItem(makeEntry(id: 'c-1', breedingId: 'pair-1'));

      final results = await dao.getByBreeding('pair-99');
      expect(results, isEmpty);
    });

    test('returns clutches regardless of userId', () async {
      await dao.insertItem(
        makeEntry(id: 'c-1', user: userId, breedingId: 'pair-1'),
      );
      await dao.insertItem(
        makeEntry(id: 'c-2', user: otherId, breedingId: 'pair-1'),
      );

      final results = await dao.getByBreeding('pair-1');
      expect(results.length, equals(2));
    });
  });
}
