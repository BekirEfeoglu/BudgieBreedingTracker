import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/nests_dao.dart';
import 'package:budgie_breeding_tracker/data/models/nest_model.dart';

void main() {
  late AppDatabase db;
  late NestsDao dao;

  const userId = 'user-1';
  const otherId = 'user-2';

  Nest makeEntry({
    String id = 'nest-1',
    String user = userId,
    String name = 'Nest A',
    NestStatus status = NestStatus.available,
    bool isDeleted = false,
  }) {
    return Nest(
      id: id,
      userId: user,
      name: name,
      status: status,
      isDeleted: isDeleted,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.nestsDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('watchAll', () {
    test('returns non-deleted nests for the user', () async {
      await dao.insertItem(makeEntry(id: 'n-1'));
      await dao.insertItem(makeEntry(id: 'n-2'));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(2));
    });

    test('excludes soft-deleted nests', () async {
      await dao.insertItem(makeEntry(id: 'n-1'));
      await dao.insertItem(makeEntry(id: 'n-2', isDeleted: true));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('n-1'));
    });

    test('does not return nests for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'n-1', user: userId));
      await dao.insertItem(makeEntry(id: 'n-2', user: otherId));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('n-1'));
    });

    test('returns empty list when no nests exist', () async {
      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });

    test('returns empty when all nests are soft-deleted', () async {
      await dao.insertItem(makeEntry(id: 'n-1', isDeleted: true));
      await dao.insertItem(makeEntry(id: 'n-2', isDeleted: true));

      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });
  });

  group('watchById', () {
    test('returns the nest when it exists', () async {
      await dao.insertItem(makeEntry(id: 'n-1'));

      final result = await dao.watchById('n-1').first;
      expect(result, isNotNull);
      expect(result!.id, equals('n-1'));
      expect(result.name, equals('Nest A'));
    });

    test('returns null when nest does not exist', () async {
      final result = await dao.watchById('non-existent').first;
      expect(result, isNull);
    });

    test(
      'returns soft-deleted nest (no isDeleted filter on watchById)',
      () async {
        await dao.insertItem(makeEntry(id: 'n-1', isDeleted: true));

        final result = await dao.watchById('n-1').first;
        expect(result, isNotNull);
        expect(result!.isDeleted, isTrue);
      },
    );
  });

  group('getAll', () {
    test('returns non-deleted nests for the user', () async {
      await dao.insertItem(makeEntry(id: 'n-1'));
      await dao.insertItem(makeEntry(id: 'n-2'));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });

    test('excludes soft-deleted nests', () async {
      await dao.insertItem(makeEntry(id: 'n-1'));
      await dao.insertItem(makeEntry(id: 'n-2', isDeleted: true));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('does not return nests for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'n-1', user: userId));
      await dao.insertItem(makeEntry(id: 'n-2', user: otherId));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('returns empty list when no nests exist', () async {
      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('getById', () {
    test('returns the nest when it exists', () async {
      await dao.insertItem(makeEntry(id: 'n-1'));

      final result = await dao.getById('n-1');
      expect(result, isNotNull);
      expect(result!.id, equals('n-1'));
      expect(result.status, equals(NestStatus.available));
    });

    test('returns null when nest does not exist', () async {
      final result = await dao.getById('non-existent');
      expect(result, isNull);
    });
  });

  group('insertItem', () {
    test('inserts a new nest', () async {
      await dao.insertItem(makeEntry(id: 'n-1'));

      final result = await dao.getById('n-1');
      expect(result, isNotNull);
      expect(result!.name, equals('Nest A'));
    });

    test('upserts on conflict (updates existing)', () async {
      await dao.insertItem(makeEntry(id: 'n-1', name: 'Original'));
      await dao.insertItem(makeEntry(id: 'n-1', name: 'Updated'));

      final result = await dao.getById('n-1');
      expect(result, isNotNull);
      expect(result!.name, equals('Updated'));
    });
  });

  group('insertAll', () {
    test('inserts multiple nests in batch', () async {
      final items = [
        makeEntry(id: 'n-1', name: 'Nest A'),
        makeEntry(id: 'n-2', name: 'Nest B'),
        makeEntry(id: 'n-3', name: 'Nest C'),
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
      await dao.insertItem(makeEntry(id: 'n-1', name: 'Original'));
      await dao.insertAll([
        makeEntry(id: 'n-1', name: 'Batch Updated'),
        makeEntry(id: 'n-2', name: 'New Nest'),
      ]);

      final updated = await dao.getById('n-1');
      expect(updated!.name, equals('Batch Updated'));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });
  });

  group('softDelete', () {
    test('sets isDeleted to true', () async {
      await dao.insertItem(makeEntry(id: 'n-1'));

      await dao.softDelete('n-1');

      final result = await dao.getById('n-1');
      expect(result, isNotNull);
      expect(result!.isDeleted, isTrue);
    });

    test('excluded from watchAll after soft delete', () async {
      await dao.insertItem(makeEntry(id: 'n-1'));
      await dao.insertItem(makeEntry(id: 'n-2'));

      await dao.softDelete('n-1');

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('n-2'));
    });

    test('excluded from getAll after soft delete', () async {
      await dao.insertItem(makeEntry(id: 'n-1'));

      await dao.softDelete('n-1');

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });

    test('does not affect other nests', () async {
      await dao.insertItem(makeEntry(id: 'n-1'));
      await dao.insertItem(makeEntry(id: 'n-2'));

      await dao.softDelete('n-1');

      final n2 = await dao.getById('n-2');
      expect(n2, isNotNull);
      expect(n2!.isDeleted, isFalse);
    });
  });

  group('hardDelete', () {
    test('permanently removes the nest', () async {
      await dao.insertItem(makeEntry(id: 'n-1'));

      await dao.hardDelete('n-1');

      final result = await dao.getById('n-1');
      expect(result, isNull);
    });

    test('does not affect other nests', () async {
      await dao.insertItem(makeEntry(id: 'n-1'));
      await dao.insertItem(makeEntry(id: 'n-2'));

      await dao.hardDelete('n-1');

      final remaining = await dao.getAll(userId);
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('n-2'));
    });

    test('is a no-op when nest does not exist', () async {
      await dao.hardDelete('non-existent');

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('getAvailable', () {
    test('returns only available nests for the user', () async {
      await dao.insertItem(makeEntry(id: 'n-1', status: NestStatus.available));
      await dao.insertItem(makeEntry(id: 'n-2', status: NestStatus.occupied));
      await dao.insertItem(
        makeEntry(id: 'n-3', status: NestStatus.maintenance),
      );

      final results = await dao.getAvailable(userId);
      expect(results.length, equals(1));
      expect(results.first.id, equals('n-1'));
    });

    test('excludes soft-deleted nests', () async {
      await dao.insertItem(makeEntry(id: 'n-1', status: NestStatus.available));
      await dao.insertItem(
        makeEntry(id: 'n-2', status: NestStatus.available, isDeleted: true),
      );

      final results = await dao.getAvailable(userId);
      expect(results.length, equals(1));
      expect(results.first.id, equals('n-1'));
    });

    test('does not return available nests of another user', () async {
      await dao.insertItem(
        makeEntry(id: 'n-1', user: userId, status: NestStatus.available),
      );
      await dao.insertItem(
        makeEntry(id: 'n-2', user: otherId, status: NestStatus.available),
      );

      final results = await dao.getAvailable(userId);
      expect(results.length, equals(1));
      expect(results.first.id, equals('n-1'));
    });

    test('returns empty list when no available nests exist', () async {
      await dao.insertItem(makeEntry(id: 'n-1', status: NestStatus.occupied));
      await dao.insertItem(
        makeEntry(id: 'n-2', status: NestStatus.maintenance),
      );

      final results = await dao.getAvailable(userId);
      expect(results, isEmpty);
    });

    test('returns multiple available nests', () async {
      await dao.insertItem(
        makeEntry(id: 'n-1', name: 'A', status: NestStatus.available),
      );
      await dao.insertItem(
        makeEntry(id: 'n-2', name: 'B', status: NestStatus.available),
      );
      await dao.insertItem(
        makeEntry(id: 'n-3', name: 'C', status: NestStatus.available),
      );

      final results = await dao.getAvailable(userId);
      expect(results.length, equals(3));
    });
  });
}
