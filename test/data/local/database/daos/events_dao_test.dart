import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/events_dao.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';

void main() {
  late AppDatabase db;
  late EventsDao dao;

  const userId = 'user-1';
  const otherId = 'user-2';

  Event makeEntry({
    String id = 'evt-1',
    String user = userId,
    String title = 'Checkup',
    EventType type = EventType.healthCheck,
    DateTime? eventDate,
    String? birdId,
    bool isDeleted = false,
  }) {
    return Event(
      id: id,
      title: title,
      eventDate: eventDate ?? DateTime(2024, 3, 1),
      type: type,
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
    dao = db.eventsDao;
    // Pre-create parent birds referenced by test fixtures.
    await insertBird('bird-1');
    await insertBird('bird-2');
    await insertBird('bird-99');
  });

  tearDown(() async {
    await db.close();
  });

  group('watchAll', () {
    test('returns non-deleted events for the user', () async {
      await dao.insertItem(makeEntry(id: 'evt-1'));
      await dao.insertItem(makeEntry(id: 'evt-2'));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(2));
    });

    test('excludes soft-deleted events', () async {
      await dao.insertItem(makeEntry(id: 'evt-1'));
      await dao.insertItem(makeEntry(id: 'evt-2', isDeleted: true));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('evt-1'));
    });

    test('does not return events for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'evt-1', user: userId));
      await dao.insertItem(makeEntry(id: 'evt-2', user: otherId));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('evt-1'));
    });

    test('returns empty list when no events exist', () async {
      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });

    test('returns empty when all events are soft-deleted', () async {
      await dao.insertItem(makeEntry(id: 'evt-1', isDeleted: true));
      await dao.insertItem(makeEntry(id: 'evt-2', isDeleted: true));

      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });
  });

  group('watchById', () {
    test('returns the event when it exists', () async {
      await dao.insertItem(makeEntry(id: 'evt-1'));

      final result = await dao.watchById('evt-1').first;
      expect(result, isNotNull);
      expect(result!.id, equals('evt-1'));
      expect(result.title, equals('Checkup'));
    });

    test('returns null when event does not exist', () async {
      final result = await dao.watchById('non-existent').first;
      expect(result, isNull);
    });

    test('filters out soft-deleted event', () async {
      await dao.insertItem(makeEntry(id: 'evt-1', isDeleted: true));

      final result = await dao.watchById('evt-1').first;
      expect(result, isNull);
    });
  });

  group('getAll', () {
    test('returns non-deleted events for the user', () async {
      await dao.insertItem(makeEntry(id: 'evt-1'));
      await dao.insertItem(makeEntry(id: 'evt-2'));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });

    test('excludes soft-deleted events', () async {
      await dao.insertItem(makeEntry(id: 'evt-1'));
      await dao.insertItem(makeEntry(id: 'evt-2', isDeleted: true));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('does not return events for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'evt-1', user: userId));
      await dao.insertItem(makeEntry(id: 'evt-2', user: otherId));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('returns empty list when no events exist', () async {
      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('getById', () {
    test('returns the event when it exists', () async {
      await dao.insertItem(makeEntry(id: 'evt-1'));

      final result = await dao.getById('evt-1');
      expect(result, isNotNull);
      expect(result!.id, equals('evt-1'));
      expect(result.type, equals(EventType.healthCheck));
    });

    test('returns null when event does not exist', () async {
      final result = await dao.getById('non-existent');
      expect(result, isNull);
    });
  });

  group('insertItem', () {
    test('inserts a new event', () async {
      await dao.insertItem(makeEntry(id: 'evt-1'));

      final result = await dao.getById('evt-1');
      expect(result, isNotNull);
      expect(result!.title, equals('Checkup'));
    });

    test('upserts on conflict (updates existing)', () async {
      await dao.insertItem(makeEntry(id: 'evt-1', title: 'Original'));
      await dao.insertItem(makeEntry(id: 'evt-1', title: 'Updated'));

      final result = await dao.getById('evt-1');
      expect(result, isNotNull);
      expect(result!.title, equals('Updated'));
    });
  });

  group('insertAll', () {
    test('inserts multiple events in batch', () async {
      final items = [
        makeEntry(id: 'evt-1'),
        makeEntry(id: 'evt-2'),
        makeEntry(id: 'evt-3'),
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
      await dao.insertItem(makeEntry(id: 'evt-1', title: 'Original'));
      await dao.insertAll([
        makeEntry(id: 'evt-1', title: 'Batch Updated'),
        makeEntry(id: 'evt-2', title: 'New Event'),
      ]);

      final updated = await dao.getById('evt-1');
      expect(updated!.title, equals('Batch Updated'));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });
  });

  group('softDelete', () {
    test('sets isDeleted to true', () async {
      await dao.insertItem(makeEntry(id: 'evt-1'));

      await dao.softDelete('evt-1');

      // getById filters out soft-deleted rows; verify via raw SQL.
      final rows = await db
          .customSelect(
            "SELECT is_deleted FROM events WHERE id = 'evt-1'",
          )
          .get();
      expect(rows, hasLength(1));
      expect(rows.first.read<int>('is_deleted'), equals(1));
    });

    test('excluded from watchAll after soft delete', () async {
      await dao.insertItem(makeEntry(id: 'evt-1'));
      await dao.insertItem(makeEntry(id: 'evt-2'));

      await dao.softDelete('evt-1');

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('evt-2'));
    });

    test('excluded from getAll after soft delete', () async {
      await dao.insertItem(makeEntry(id: 'evt-1'));

      await dao.softDelete('evt-1');

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });

    test('does not affect other events', () async {
      await dao.insertItem(makeEntry(id: 'evt-1'));
      await dao.insertItem(makeEntry(id: 'evt-2'));

      await dao.softDelete('evt-1');

      final evt2 = await dao.getById('evt-2');
      expect(evt2, isNotNull);
      expect(evt2!.isDeleted, isFalse);
    });
  });

  group('hardDelete', () {
    test('permanently removes the event', () async {
      await dao.insertItem(makeEntry(id: 'evt-1'));

      await dao.hardDelete('evt-1');

      final result = await dao.getById('evt-1');
      expect(result, isNull);
    });

    test('does not affect other events', () async {
      await dao.insertItem(makeEntry(id: 'evt-1'));
      await dao.insertItem(makeEntry(id: 'evt-2'));

      await dao.hardDelete('evt-1');

      final remaining = await dao.getAll(userId);
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('evt-2'));
    });

    test('is a no-op when event does not exist', () async {
      await dao.hardDelete('non-existent');

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('watchByDateRange', () {
    test('returns events within the date range', () async {
      await dao.insertItem(
        makeEntry(id: 'evt-1', eventDate: DateTime(2024, 3, 1)),
      );
      await dao.insertItem(
        makeEntry(id: 'evt-2', eventDate: DateTime(2024, 3, 15)),
      );
      await dao.insertItem(
        makeEntry(id: 'evt-3', eventDate: DateTime(2024, 4, 1)),
      );

      final results = await dao
          .watchByDateRange(userId, DateTime(2024, 3, 1), DateTime(2024, 3, 31))
          .first;
      expect(results.length, equals(2));
      final ids = results.map((e) => e.id).toSet();
      expect(ids, containsAll(['evt-1', 'evt-2']));
    });

    test('includes events on range boundaries', () async {
      await dao.insertItem(
        makeEntry(id: 'evt-1', eventDate: DateTime(2024, 3, 1)),
      );
      await dao.insertItem(
        makeEntry(id: 'evt-2', eventDate: DateTime(2024, 3, 31)),
      );

      final results = await dao
          .watchByDateRange(userId, DateTime(2024, 3, 1), DateTime(2024, 3, 31))
          .first;
      expect(results.length, equals(2));
    });

    test('excludes soft-deleted events', () async {
      await dao.insertItem(
        makeEntry(id: 'evt-1', eventDate: DateTime(2024, 3, 1)),
      );
      await dao.insertItem(
        makeEntry(
          id: 'evt-2',
          eventDate: DateTime(2024, 3, 15),
          isDeleted: true,
        ),
      );

      final results = await dao
          .watchByDateRange(userId, DateTime(2024, 3, 1), DateTime(2024, 3, 31))
          .first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('evt-1'));
    });

    test('does not return events for a different userId', () async {
      await dao.insertItem(
        makeEntry(id: 'evt-1', user: userId, eventDate: DateTime(2024, 3, 1)),
      );
      await dao.insertItem(
        makeEntry(id: 'evt-2', user: otherId, eventDate: DateTime(2024, 3, 1)),
      );

      final results = await dao
          .watchByDateRange(userId, DateTime(2024, 3, 1), DateTime(2024, 3, 31))
          .first;
      expect(results.length, equals(1));
    });

    test('returns empty list when no events in range', () async {
      await dao.insertItem(
        makeEntry(id: 'evt-1', eventDate: DateTime(2024, 1, 1)),
      );

      final results = await dao
          .watchByDateRange(userId, DateTime(2024, 3, 1), DateTime(2024, 3, 31))
          .first;
      expect(results, isEmpty);
    });
  });

  group('getUpcoming', () {
    test('returns future events ordered by eventDate', () async {
      final now = DateTime.now();
      final future1 = now.add(const Duration(days: 1));
      final future2 = now.add(const Duration(days: 5));
      final past = now.subtract(const Duration(days: 1));

      await dao.insertItem(makeEntry(id: 'evt-future2', eventDate: future2));
      await dao.insertItem(makeEntry(id: 'evt-future1', eventDate: future1));
      await dao.insertItem(makeEntry(id: 'evt-past', eventDate: past));

      final results = await dao.getUpcoming(userId);
      expect(results.length, equals(2));
      expect(results[0].id, equals('evt-future1'));
      expect(results[1].id, equals('evt-future2'));
    });

    test('respects limit parameter', () async {
      final now = DateTime.now();
      for (var i = 1; i <= 15; i++) {
        await dao.insertItem(
          makeEntry(
            id: 'evt-$i',
            eventDate: now.add(Duration(days: i)),
          ),
        );
      }

      final results = await dao.getUpcoming(userId, limit: 5);
      expect(results.length, equals(5));
    });

    test('excludes soft-deleted events', () async {
      final future = DateTime.now().add(const Duration(days: 1));
      await dao.insertItem(makeEntry(id: 'evt-1', eventDate: future));
      await dao.insertItem(
        makeEntry(id: 'evt-2', eventDate: future, isDeleted: true),
      );

      final results = await dao.getUpcoming(userId);
      expect(results.length, equals(1));
      expect(results.first.id, equals('evt-1'));
    });

    test('does not return events for a different userId', () async {
      final future = DateTime.now().add(const Duration(days: 1));
      await dao.insertItem(
        makeEntry(id: 'evt-1', user: userId, eventDate: future),
      );
      await dao.insertItem(
        makeEntry(id: 'evt-2', user: otherId, eventDate: future),
      );

      final results = await dao.getUpcoming(userId);
      expect(results.length, equals(1));
    });

    test('returns empty list when no upcoming events', () async {
      final past = DateTime.now().subtract(const Duration(days: 10));
      await dao.insertItem(makeEntry(id: 'evt-1', eventDate: past));

      final results = await dao.getUpcoming(userId);
      expect(results, isEmpty);
    });
  });

  group('watchByBird', () {
    test('returns events for the specified bird', () async {
      await dao.insertItem(makeEntry(id: 'evt-1', birdId: 'bird-1'));
      await dao.insertItem(makeEntry(id: 'evt-2', birdId: 'bird-1'));
      await dao.insertItem(makeEntry(id: 'evt-3', birdId: 'bird-2'));

      final results = await dao.watchByBird('bird-1').first;
      expect(results.length, equals(2));
    });

    test('excludes soft-deleted events', () async {
      await dao.insertItem(makeEntry(id: 'evt-1', birdId: 'bird-1'));
      await dao.insertItem(
        makeEntry(id: 'evt-2', birdId: 'bird-1', isDeleted: true),
      );

      final results = await dao.watchByBird('bird-1').first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('evt-1'));
    });

    test('returns empty list when bird has no events', () async {
      await dao.insertItem(makeEntry(id: 'evt-1', birdId: 'bird-1'));

      final results = await dao.watchByBird('bird-99').first;
      expect(results, isEmpty);
    });

    test(
      'returns events regardless of userId (filters by birdId only)',
      () async {
        await dao.insertItem(
          makeEntry(id: 'evt-1', user: userId, birdId: 'bird-1'),
        );
        await dao.insertItem(
          makeEntry(id: 'evt-2', user: otherId, birdId: 'bird-1'),
        );

        final results = await dao.watchByBird('bird-1').first;
        expect(results.length, equals(2));
      },
    );
  });
}
