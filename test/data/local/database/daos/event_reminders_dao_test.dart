import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/reminder_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/event_reminders_dao.dart';
import 'package:budgie_breeding_tracker/data/models/event_reminder_model.dart';

void main() {
  late AppDatabase db;
  late EventRemindersDao dao;

  const userId = 'user-1';
  const otherId = 'user-2';

  EventReminder makeEntry({
    String id = 'rem-1',
    String user = userId,
    String eventId = 'evt-1',
    int minutesBefore = 30,
    ReminderType type = ReminderType.notification,
    bool isSent = false,
    bool isDeleted = false,
  }) {
    return EventReminder(
      id: id,
      userId: user,
      eventId: eventId,
      minutesBefore: minutesBefore,
      type: type,
      isSent: isSent,
      isDeleted: isDeleted,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Insert a minimal parent event row to satisfy FK constraints.
  Future<void> insertEvent(String id) async {
    final epoch = DateTime(2024, 1, 1).millisecondsSinceEpoch ~/ 1000;
    await db.customStatement(
      'INSERT OR IGNORE INTO events (id, title, event_date, type, user_id, status, is_deleted) '
      "VALUES ('$id', 'Test', $epoch, 'health_check', 'user-1', 'active', 0)",
    );
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.eventRemindersDao;
    // Pre-create parent events referenced by test fixtures.
    await insertEvent('evt-1');
    await insertEvent('evt-2');
    await insertEvent('evt-99');
  });

  tearDown(() async {
    await db.close();
  });

  group('watchAll', () {
    test('returns non-deleted reminders for the user', () async {
      await dao.insertItem(makeEntry(id: 'rem-1'));
      await dao.insertItem(makeEntry(id: 'rem-2'));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(2));
    });

    test('excludes soft-deleted reminders', () async {
      await dao.insertItem(makeEntry(id: 'rem-1'));
      await dao.insertItem(makeEntry(id: 'rem-2', isDeleted: true));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('rem-1'));
    });

    test('does not return reminders for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', user: userId));
      await dao.insertItem(makeEntry(id: 'rem-2', user: otherId));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('rem-1'));
    });

    test('returns empty list when no reminders exist', () async {
      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });

    test('returns empty when all reminders are soft-deleted', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', isDeleted: true));
      await dao.insertItem(makeEntry(id: 'rem-2', isDeleted: true));

      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });
  });

  group('watchByEvent', () {
    test('returns non-deleted reminders for the specified event', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', eventId: 'evt-1'));
      await dao.insertItem(makeEntry(id: 'rem-2', eventId: 'evt-1'));
      await dao.insertItem(makeEntry(id: 'rem-3', eventId: 'evt-2'));

      final results = await dao.watchByEvent('evt-1').first;
      expect(results.length, equals(2));
    });

    test('excludes soft-deleted reminders', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', eventId: 'evt-1'));
      await dao.insertItem(
        makeEntry(id: 'rem-2', eventId: 'evt-1', isDeleted: true),
      );

      final results = await dao.watchByEvent('evt-1').first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('rem-1'));
    });

    test('returns empty list when event has no reminders', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', eventId: 'evt-1'));

      final results = await dao.watchByEvent('evt-99').first;
      expect(results, isEmpty);
    });
  });

  group('getAll', () {
    test('returns non-deleted reminders for the user', () async {
      await dao.insertItem(makeEntry(id: 'rem-1'));
      await dao.insertItem(makeEntry(id: 'rem-2'));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });

    test('excludes soft-deleted reminders', () async {
      await dao.insertItem(makeEntry(id: 'rem-1'));
      await dao.insertItem(makeEntry(id: 'rem-2', isDeleted: true));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('does not return reminders for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', user: userId));
      await dao.insertItem(makeEntry(id: 'rem-2', user: otherId));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('returns empty list when no reminders exist', () async {
      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('getByEvent', () {
    test('returns non-deleted reminders for the specified event', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', eventId: 'evt-1'));
      await dao.insertItem(makeEntry(id: 'rem-2', eventId: 'evt-1'));
      await dao.insertItem(makeEntry(id: 'rem-3', eventId: 'evt-2'));

      final results = await dao.getByEvent('evt-1');
      expect(results.length, equals(2));
    });

    test('excludes soft-deleted reminders', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', eventId: 'evt-1'));
      await dao.insertItem(
        makeEntry(id: 'rem-2', eventId: 'evt-1', isDeleted: true),
      );

      final results = await dao.getByEvent('evt-1');
      expect(results.length, equals(1));
    });

    test('returns empty list when event has no reminders', () async {
      final results = await dao.getByEvent('evt-99');
      expect(results, isEmpty);
    });
  });

  group('getById', () {
    test('returns the reminder when it exists', () async {
      await dao.insertItem(makeEntry(id: 'rem-1'));

      final result = await dao.getById('rem-1');
      expect(result, isNotNull);
      expect(result!.id, equals('rem-1'));
      expect(result.minutesBefore, equals(30));
      expect(result.type, equals(ReminderType.notification));
    });

    test('returns null when reminder does not exist', () async {
      final result = await dao.getById('non-existent');
      expect(result, isNull);
    });

    test('filters out soft-deleted reminder', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', isDeleted: true));

      final result = await dao.getById('rem-1');
      expect(result, isNull);
    });
  });

  group('getUnsent', () {
    test('returns unsent non-deleted reminders for the user', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', isSent: false));
      await dao.insertItem(makeEntry(id: 'rem-2', isSent: false));

      final results = await dao.getUnsent(userId);
      expect(results.length, equals(2));
    });

    test('excludes sent reminders', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', isSent: false));
      await dao.insertItem(makeEntry(id: 'rem-2', isSent: true));

      final results = await dao.getUnsent(userId);
      expect(results.length, equals(1));
      expect(results.first.id, equals('rem-1'));
    });

    test('excludes soft-deleted reminders', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', isSent: false));
      await dao.insertItem(
        makeEntry(id: 'rem-2', isSent: false, isDeleted: true),
      );

      final results = await dao.getUnsent(userId);
      expect(results.length, equals(1));
      expect(results.first.id, equals('rem-1'));
    });

    test('does not return reminders for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', user: userId));
      await dao.insertItem(makeEntry(id: 'rem-2', user: otherId));

      final results = await dao.getUnsent(userId);
      expect(results.length, equals(1));
    });

    test('returns empty list when all reminders are sent', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', isSent: true));
      await dao.insertItem(makeEntry(id: 'rem-2', isSent: true));

      final results = await dao.getUnsent(userId);
      expect(results, isEmpty);
    });
  });

  group('insertItem', () {
    test('inserts a new reminder', () async {
      await dao.insertItem(makeEntry(id: 'rem-1'));

      final result = await dao.getById('rem-1');
      expect(result, isNotNull);
      expect(result!.eventId, equals('evt-1'));
    });

    test('upserts on conflict (updates existing)', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', minutesBefore: 30));
      await dao.insertItem(makeEntry(id: 'rem-1', minutesBefore: 60));

      final result = await dao.getById('rem-1');
      expect(result, isNotNull);
      expect(result!.minutesBefore, equals(60));
    });
  });

  group('insertAll', () {
    test('inserts multiple reminders in batch', () async {
      final items = [
        makeEntry(id: 'rem-1'),
        makeEntry(id: 'rem-2'),
        makeEntry(id: 'rem-3'),
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
      await dao.insertItem(makeEntry(id: 'rem-1', minutesBefore: 30));
      await dao.insertAll([
        makeEntry(id: 'rem-1', minutesBefore: 60),
        makeEntry(id: 'rem-2', minutesBefore: 15),
      ]);

      final updated = await dao.getById('rem-1');
      expect(updated!.minutesBefore, equals(60));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });
  });

  group('markSent', () {
    test('sets isSent to true', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', isSent: false));

      await dao.markSent('rem-1');

      final result = await dao.getById('rem-1');
      expect(result, isNotNull);
      expect(result!.isSent, isTrue);
    });

    test('excluded from getUnsent after marking sent', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', isSent: false));
      await dao.insertItem(makeEntry(id: 'rem-2', isSent: false));

      await dao.markSent('rem-1');

      final results = await dao.getUnsent(userId);
      expect(results.length, equals(1));
      expect(results.first.id, equals('rem-2'));
    });

    test('does not affect other reminders', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', isSent: false));
      await dao.insertItem(makeEntry(id: 'rem-2', isSent: false));

      await dao.markSent('rem-1');

      final rem2 = await dao.getById('rem-2');
      expect(rem2!.isSent, isFalse);
    });
  });

  group('softDelete', () {
    test('sets isDeleted to true', () async {
      await dao.insertItem(makeEntry(id: 'rem-1'));

      await dao.softDelete('rem-1');

      // getById filters out soft-deleted rows; verify via raw SQL.
      final rows = await db
          .customSelect(
            "SELECT is_deleted FROM event_reminders WHERE id = 'rem-1'",
          )
          .get();
      expect(rows, hasLength(1));
      expect(rows.first.read<int>('is_deleted'), equals(1));
    });

    test('excluded from watchAll after soft delete', () async {
      await dao.insertItem(makeEntry(id: 'rem-1'));
      await dao.insertItem(makeEntry(id: 'rem-2'));

      await dao.softDelete('rem-1');

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('rem-2'));
    });

    test('excluded from getAll after soft delete', () async {
      await dao.insertItem(makeEntry(id: 'rem-1'));

      await dao.softDelete('rem-1');

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });

    test('does not affect other reminders', () async {
      await dao.insertItem(makeEntry(id: 'rem-1'));
      await dao.insertItem(makeEntry(id: 'rem-2'));

      await dao.softDelete('rem-1');

      final rem2 = await dao.getById('rem-2');
      expect(rem2, isNotNull);
      expect(rem2!.isDeleted, isFalse);
    });
  });

  group('hardDelete', () {
    test('permanently removes the reminder', () async {
      await dao.insertItem(makeEntry(id: 'rem-1'));

      await dao.hardDelete('rem-1');

      final result = await dao.getById('rem-1');
      expect(result, isNull);
    });

    test('does not affect other reminders', () async {
      await dao.insertItem(makeEntry(id: 'rem-1'));
      await dao.insertItem(makeEntry(id: 'rem-2'));

      await dao.hardDelete('rem-1');

      final remaining = await dao.getAll(userId);
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('rem-2'));
    });

    test('is a no-op when reminder does not exist', () async {
      await dao.hardDelete('non-existent');

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('deleteByEvent', () {
    test('deletes all reminders for the specified event', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', eventId: 'evt-1'));
      await dao.insertItem(makeEntry(id: 'rem-2', eventId: 'evt-1'));
      await dao.insertItem(makeEntry(id: 'rem-3', eventId: 'evt-2'));

      await dao.deleteByEvent('evt-1');

      final evt1Reminders = await dao.getByEvent('evt-1');
      expect(evt1Reminders, isEmpty);

      final result = await dao.getById('rem-1');
      expect(result, isNull);

      final result2 = await dao.getById('rem-2');
      expect(result2, isNull);
    });

    test('does not affect reminders for other events', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', eventId: 'evt-1'));
      await dao.insertItem(makeEntry(id: 'rem-2', eventId: 'evt-2'));

      await dao.deleteByEvent('evt-1');

      final evt2Result = await dao.getById('rem-2');
      expect(evt2Result, isNotNull);
      expect(evt2Result!.eventId, equals('evt-2'));
    });

    test('is a no-op when event has no reminders', () async {
      await dao.insertItem(makeEntry(id: 'rem-1', eventId: 'evt-1'));

      await dao.deleteByEvent('evt-99');

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('deletes even soft-deleted reminders', () async {
      await dao.insertItem(
        makeEntry(id: 'rem-1', eventId: 'evt-1', isDeleted: true),
      );
      await dao.insertItem(makeEntry(id: 'rem-2', eventId: 'evt-1'));

      await dao.deleteByEvent('evt-1');

      final rem1 = await dao.getById('rem-1');
      expect(rem1, isNull);

      final rem2 = await dao.getById('rem-2');
      expect(rem2, isNull);
    });
  });
}
