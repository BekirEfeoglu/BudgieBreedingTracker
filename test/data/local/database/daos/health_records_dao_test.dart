import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/health_records_dao.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';

void main() {
  late AppDatabase db;
  late HealthRecordsDao dao;

  const userId = 'user-1';
  const otherId = 'user-2';

  HealthRecord makeEntry({
    String id = 'hr-1',
    String user = userId,
    DateTime? date,
    HealthRecordType type = HealthRecordType.checkup,
    String title = 'Annual Check',
    String? birdId = 'bird-1',
    bool isDeleted = false,
  }) {
    return HealthRecord(
      id: id,
      date: date ?? DateTime(2024, 2, 1),
      type: type,
      title: title,
      userId: user,
      birdId: birdId,
      isDeleted: isDeleted,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Insert a minimal parent bird row to satisfy FK constraints.
  Future<void> insertBird(String id) async {
    await db.customStatement(
      'INSERT OR IGNORE INTO birds (id, name, gender, user_id, status, species, is_deleted) '
      "VALUES ('$id', 'Test', 'male', 'user-1', 'alive', 'budgie', 0)",
    );
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.healthRecordsDao;
    // Pre-create parent birds referenced by test fixtures.
    await insertBird('bird-1');
    await insertBird('bird-2');
    await insertBird('bird-99');
  });

  tearDown(() async {
    await db.close();
  });

  group('watchAll', () {
    test('returns non-deleted records for the user', () async {
      await dao.insertItem(makeEntry(id: 'hr-1'));
      await dao.insertItem(makeEntry(id: 'hr-2'));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(2));
    });

    test('excludes soft-deleted records', () async {
      await dao.insertItem(makeEntry(id: 'hr-1'));
      await dao.insertItem(makeEntry(id: 'hr-2', isDeleted: true));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('hr-1'));
    });

    test('does not return records for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'hr-1', user: userId));
      await dao.insertItem(makeEntry(id: 'hr-2', user: otherId));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('hr-1'));
    });

    test('returns empty list when no records exist', () async {
      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });

    test('returns empty when all records are soft-deleted', () async {
      await dao.insertItem(makeEntry(id: 'hr-1', isDeleted: true));
      await dao.insertItem(makeEntry(id: 'hr-2', isDeleted: true));

      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });
  });

  group('watchById', () {
    test('returns the record when it exists', () async {
      await dao.insertItem(makeEntry(id: 'hr-1'));

      final result = await dao.watchById('hr-1').first;
      expect(result, isNotNull);
      expect(result!.id, equals('hr-1'));
      expect(result.title, equals('Annual Check'));
    });

    test('returns null when record does not exist', () async {
      final result = await dao.watchById('non-existent').first;
      expect(result, isNull);
    });

    test('filters out soft-deleted record', () async {
      await dao.insertItem(makeEntry(id: 'hr-1', isDeleted: true));

      final result = await dao.watchById('hr-1').first;
      expect(result, isNull);
    });
  });

  group('getAll', () {
    test('returns non-deleted records for the user', () async {
      await dao.insertItem(makeEntry(id: 'hr-1'));
      await dao.insertItem(makeEntry(id: 'hr-2'));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });

    test('excludes soft-deleted records', () async {
      await dao.insertItem(makeEntry(id: 'hr-1'));
      await dao.insertItem(makeEntry(id: 'hr-2', isDeleted: true));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('does not return records for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'hr-1', user: userId));
      await dao.insertItem(makeEntry(id: 'hr-2', user: otherId));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('returns empty list when no records exist', () async {
      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('getById', () {
    test('returns the record when it exists', () async {
      await dao.insertItem(makeEntry(id: 'hr-1'));

      final result = await dao.getById('hr-1');
      expect(result, isNotNull);
      expect(result!.id, equals('hr-1'));
      expect(result.type, equals(HealthRecordType.checkup));
    });

    test('returns null when record does not exist', () async {
      final result = await dao.getById('non-existent');
      expect(result, isNull);
    });
  });

  group('insertItem', () {
    test('inserts a new record', () async {
      await dao.insertItem(makeEntry(id: 'hr-1'));

      final result = await dao.getById('hr-1');
      expect(result, isNotNull);
      expect(result!.title, equals('Annual Check'));
    });

    test('upserts on conflict (updates existing)', () async {
      await dao.insertItem(makeEntry(id: 'hr-1', title: 'Original'));
      await dao.insertItem(makeEntry(id: 'hr-1', title: 'Updated'));

      final result = await dao.getById('hr-1');
      expect(result, isNotNull);
      expect(result!.title, equals('Updated'));
    });
  });

  group('insertAll', () {
    test('inserts multiple records in batch', () async {
      final items = [
        makeEntry(id: 'hr-1'),
        makeEntry(id: 'hr-2'),
        makeEntry(id: 'hr-3'),
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
      await dao.insertItem(makeEntry(id: 'hr-1', title: 'Original'));
      await dao.insertAll([
        makeEntry(id: 'hr-1', title: 'Batch Updated'),
        makeEntry(id: 'hr-2', title: 'New Record'),
      ]);

      final updated = await dao.getById('hr-1');
      expect(updated!.title, equals('Batch Updated'));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });
  });

  group('softDelete', () {
    test('sets isDeleted to true', () async {
      await dao.insertItem(makeEntry(id: 'hr-1'));

      await dao.softDelete('hr-1');

      // getById filters out soft-deleted rows; verify via raw SQL.
      final rows = await db
          .customSelect(
            "SELECT is_deleted FROM health_records WHERE id = 'hr-1'",
          )
          .get();
      expect(rows, hasLength(1));
      expect(rows.first.read<int>('is_deleted'), equals(1));
    });

    test('excluded from watchAll after soft delete', () async {
      await dao.insertItem(makeEntry(id: 'hr-1'));
      await dao.insertItem(makeEntry(id: 'hr-2'));

      await dao.softDelete('hr-1');

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('hr-2'));
    });

    test('excluded from getAll after soft delete', () async {
      await dao.insertItem(makeEntry(id: 'hr-1'));

      await dao.softDelete('hr-1');

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });

    test('does not affect other records', () async {
      await dao.insertItem(makeEntry(id: 'hr-1'));
      await dao.insertItem(makeEntry(id: 'hr-2'));

      await dao.softDelete('hr-1');

      final hr2 = await dao.getById('hr-2');
      expect(hr2, isNotNull);
      expect(hr2!.isDeleted, isFalse);
    });
  });

  group('hardDelete', () {
    test('permanently removes the record', () async {
      await dao.insertItem(makeEntry(id: 'hr-1'));

      await dao.hardDelete('hr-1');

      final result = await dao.getById('hr-1');
      expect(result, isNull);
    });

    test('does not affect other records', () async {
      await dao.insertItem(makeEntry(id: 'hr-1'));
      await dao.insertItem(makeEntry(id: 'hr-2'));

      await dao.hardDelete('hr-1');

      final remaining = await dao.getAll(userId);
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('hr-2'));
    });

    test('is a no-op when record does not exist', () async {
      await dao.hardDelete('non-existent');

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('watchCount', () {
    test('returns count of non-deleted records for the user', () async {
      await dao.insertItem(makeEntry(id: 'hr-1'));
      await dao.insertItem(makeEntry(id: 'hr-2'));

      final count = await dao.watchCount(userId).first;
      expect(count, equals(2));
    });

    test('excludes soft-deleted records', () async {
      await dao.insertItem(makeEntry(id: 'hr-1'));
      await dao.insertItem(makeEntry(id: 'hr-2', isDeleted: true));

      final count = await dao.watchCount(userId).first;
      expect(count, equals(1));
    });

    test('does not count records for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'hr-1', user: userId));
      await dao.insertItem(makeEntry(id: 'hr-2', user: otherId));

      final count = await dao.watchCount(userId).first;
      expect(count, equals(1));
    });

    test('returns zero when no records exist', () async {
      final count = await dao.watchCount(userId).first;
      expect(count, equals(0));
    });

    test('updates count after soft delete', () async {
      await dao.insertItem(makeEntry(id: 'hr-1'));
      await dao.insertItem(makeEntry(id: 'hr-2'));

      final initialCount = await dao.watchCount(userId).first;
      expect(initialCount, equals(2));

      await dao.softDelete('hr-1');

      final afterCount = await dao.watchCount(userId).first;
      expect(afterCount, equals(1));
    });
  });

  group('watchByBird', () {
    test('returns non-deleted records for the specified bird', () async {
      await dao.insertItem(makeEntry(id: 'hr-1', birdId: 'bird-1'));
      await dao.insertItem(makeEntry(id: 'hr-2', birdId: 'bird-1'));
      await dao.insertItem(makeEntry(id: 'hr-3', birdId: 'bird-2'));

      final results = await dao.watchByBird('bird-1').first;
      expect(results.length, equals(2));
    });

    test('excludes soft-deleted records', () async {
      await dao.insertItem(makeEntry(id: 'hr-1', birdId: 'bird-1'));
      await dao.insertItem(
        makeEntry(id: 'hr-2', birdId: 'bird-1', isDeleted: true),
      );

      final results = await dao.watchByBird('bird-1').first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('hr-1'));
    });

    test('returns empty list when bird has no records', () async {
      await dao.insertItem(makeEntry(id: 'hr-1', birdId: 'bird-1'));

      final results = await dao.watchByBird('bird-99').first;
      expect(results, isEmpty);
    });

    test(
      'returns records regardless of userId (filters by birdId only)',
      () async {
        await dao.insertItem(
          makeEntry(id: 'hr-1', user: userId, birdId: 'bird-1'),
        );
        await dao.insertItem(
          makeEntry(id: 'hr-2', user: otherId, birdId: 'bird-1'),
        );

        final results = await dao.watchByBird('bird-1').first;
        expect(results.length, equals(2));
      },
    );
  });

  group('getLatest', () {
    test('returns records ordered by date descending', () async {
      await dao.insertItem(
        makeEntry(id: 'hr-1', birdId: 'bird-1', date: DateTime(2024, 1, 1)),
      );
      await dao.insertItem(
        makeEntry(id: 'hr-2', birdId: 'bird-1', date: DateTime(2024, 3, 1)),
      );
      await dao.insertItem(
        makeEntry(id: 'hr-3', birdId: 'bird-1', date: DateTime(2024, 2, 1)),
      );

      final results = await dao.getLatest('bird-1');
      expect(results.length, equals(3));
      expect(results[0].id, equals('hr-2'));
      expect(results[1].id, equals('hr-3'));
      expect(results[2].id, equals('hr-1'));
    });

    test('respects limit parameter', () async {
      for (var i = 1; i <= 10; i++) {
        await dao.insertItem(
          makeEntry(id: 'hr-$i', birdId: 'bird-1', date: DateTime(2024, 1, i)),
        );
      }

      final results = await dao.getLatest('bird-1', limit: 3);
      expect(results.length, equals(3));
    });

    test('uses default limit of 5', () async {
      for (var i = 1; i <= 10; i++) {
        await dao.insertItem(
          makeEntry(id: 'hr-$i', birdId: 'bird-1', date: DateTime(2024, 1, i)),
        );
      }

      final results = await dao.getLatest('bird-1');
      expect(results.length, equals(5));
    });

    test('excludes soft-deleted records', () async {
      await dao.insertItem(
        makeEntry(id: 'hr-1', birdId: 'bird-1', date: DateTime(2024, 3, 1)),
      );
      await dao.insertItem(
        makeEntry(
          id: 'hr-2',
          birdId: 'bird-1',
          date: DateTime(2024, 2, 1),
          isDeleted: true,
        ),
      );

      final results = await dao.getLatest('bird-1');
      expect(results.length, equals(1));
      expect(results.first.id, equals('hr-1'));
    });

    test('returns only records for the specified bird', () async {
      await dao.insertItem(
        makeEntry(id: 'hr-1', birdId: 'bird-1', date: DateTime(2024, 3, 1)),
      );
      await dao.insertItem(
        makeEntry(id: 'hr-2', birdId: 'bird-2', date: DateTime(2024, 3, 1)),
      );

      final results = await dao.getLatest('bird-1');
      expect(results.length, equals(1));
      expect(results.first.id, equals('hr-1'));
    });

    test('returns empty list when bird has no records', () async {
      final results = await dao.getLatest('bird-99');
      expect(results, isEmpty);
    });
  });
}
