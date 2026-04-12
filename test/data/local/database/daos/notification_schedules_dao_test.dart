import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notification_schedules_dao.dart';
import 'package:budgie_breeding_tracker/data/models/notification_schedule_model.dart';

void main() {
  late AppDatabase db;
  late NotificationSchedulesDao dao;

  const userId = 'user-1';
  const otherId = 'user-2';

  NotificationSchedule makeEntry({
    String id = 'sched-1',
    String user = userId,
    NotificationType type = NotificationType.eggTurning,
    String title = 'Egg Turn',
    DateTime? scheduledAt,
    bool isActive = true,
    DateTime? processedAt,
  }) {
    return NotificationSchedule(
      id: id,
      userId: user,
      type: type,
      title: title,
      scheduledAt: scheduledAt ?? DateTime(2024, 3, 1),
      isActive: isActive,
      processedAt: processedAt,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.notificationSchedulesDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('watchAll', () {
    test('returns active schedules for the user', () async {
      await dao.insertItem(makeEntry(id: 'sched-1', isActive: true));
      await dao.insertItem(makeEntry(id: 'sched-2', isActive: true));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(2));
    });

    test('excludes inactive schedules', () async {
      await dao.insertItem(makeEntry(id: 'sched-1', isActive: true));
      await dao.insertItem(makeEntry(id: 'sched-2', isActive: false));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('sched-1'));
    });

    test('does not return schedules for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'sched-1', user: userId));
      await dao.insertItem(makeEntry(id: 'sched-2', user: otherId));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('sched-1'));
    });

    test('returns empty list when no schedules exist', () async {
      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });

    test('returns empty when all schedules are inactive', () async {
      await dao.insertItem(makeEntry(id: 'sched-1', isActive: false));
      await dao.insertItem(makeEntry(id: 'sched-2', isActive: false));

      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });
  });

  group('watchById', () {
    test('returns the schedule when it exists', () async {
      await dao.insertItem(makeEntry(id: 'sched-1'));

      final result = await dao.watchById('sched-1').first;
      expect(result, isNotNull);
      expect(result!.id, equals('sched-1'));
      expect(result.title, equals('Egg Turn'));
    });

    test('returns null when schedule does not exist', () async {
      final result = await dao.watchById('non-existent').first;
      expect(result, isNull);
    });

    test('returns inactive schedule (no isActive filter)', () async {
      await dao.insertItem(makeEntry(id: 'sched-1', isActive: false));

      final result = await dao.watchById('sched-1').first;
      expect(result, isNotNull);
      expect(result!.isActive, isFalse);
    });
  });

  group('getAll', () {
    test('returns all schedules for the user (including inactive)', () async {
      await dao.insertItem(makeEntry(id: 'sched-1', isActive: true));
      await dao.insertItem(makeEntry(id: 'sched-2', isActive: false));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });

    test('does not return schedules for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'sched-1', user: userId));
      await dao.insertItem(makeEntry(id: 'sched-2', user: otherId));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('returns empty list when no schedules exist', () async {
      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('getById', () {
    test('returns the schedule when it exists', () async {
      await dao.insertItem(makeEntry(id: 'sched-1'));

      final result = await dao.getById('sched-1');
      expect(result, isNotNull);
      expect(result!.id, equals('sched-1'));
      expect(result.type, equals(NotificationType.eggTurning));
    });

    test('returns null when schedule does not exist', () async {
      final result = await dao.getById('non-existent');
      expect(result, isNull);
    });
  });

  group('getPending', () {
    test('returns active schedules with no processedAt', () async {
      await dao.insertItem(
        makeEntry(id: 'sched-1', isActive: true, processedAt: null),
      );
      await dao.insertItem(
        makeEntry(id: 'sched-2', isActive: true, processedAt: null),
      );

      final results = await dao.getPending(userId);
      expect(results.length, equals(2));
    });

    test('excludes inactive schedules', () async {
      await dao.insertItem(makeEntry(id: 'sched-1', isActive: true));
      await dao.insertItem(makeEntry(id: 'sched-2', isActive: false));

      final results = await dao.getPending(userId);
      expect(results.length, equals(1));
      expect(results.first.id, equals('sched-1'));
    });

    test('excludes already processed schedules', () async {
      await dao.insertItem(makeEntry(id: 'sched-1', processedAt: null));
      await dao.insertItem(
        makeEntry(id: 'sched-2', processedAt: DateTime(2024, 2, 1)),
      );

      final results = await dao.getPending(userId);
      expect(results.length, equals(1));
      expect(results.first.id, equals('sched-1'));
    });

    test('does not return schedules for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'sched-1', user: userId));
      await dao.insertItem(makeEntry(id: 'sched-2', user: otherId));

      final results = await dao.getPending(userId);
      expect(results.length, equals(1));
    });

    test('returns empty list when all are processed or inactive', () async {
      await dao.insertItem(makeEntry(id: 'sched-1', isActive: false));
      await dao.insertItem(
        makeEntry(id: 'sched-2', processedAt: DateTime(2024, 2, 1)),
      );

      final results = await dao.getPending(userId);
      expect(results, isEmpty);
    });
  });

  group('insertItem', () {
    test('inserts a new schedule', () async {
      await dao.insertItem(makeEntry(id: 'sched-1'));

      final result = await dao.getById('sched-1');
      expect(result, isNotNull);
      expect(result!.title, equals('Egg Turn'));
    });

    test('upserts on conflict (updates existing)', () async {
      await dao.insertItem(makeEntry(id: 'sched-1', title: 'Original'));
      await dao.insertItem(makeEntry(id: 'sched-1', title: 'Updated'));

      final result = await dao.getById('sched-1');
      expect(result, isNotNull);
      expect(result!.title, equals('Updated'));
    });
  });

  group('insertAll', () {
    test('inserts multiple schedules in batch', () async {
      final items = [
        makeEntry(id: 'sched-1'),
        makeEntry(id: 'sched-2'),
        makeEntry(id: 'sched-3'),
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
      await dao.insertItem(makeEntry(id: 'sched-1', title: 'Original'));
      await dao.insertAll([
        makeEntry(id: 'sched-1', title: 'Batch Updated'),
        makeEntry(id: 'sched-2', title: 'New Schedule'),
      ]);

      final updated = await dao.getById('sched-1');
      expect(updated!.title, equals('Batch Updated'));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });
  });

  group('markProcessed', () {
    test('sets processedAt timestamp', () async {
      await dao.insertItem(makeEntry(id: 'sched-1'));

      await dao.markProcessed('sched-1');

      final result = await dao.getById('sched-1');
      expect(result, isNotNull);
      expect(result!.processedAt, isNotNull);
    });

    test('excluded from getPending after marking processed', () async {
      await dao.insertItem(makeEntry(id: 'sched-1'));
      await dao.insertItem(makeEntry(id: 'sched-2'));

      await dao.markProcessed('sched-1');

      final results = await dao.getPending(userId);
      expect(results.length, equals(1));
      expect(results.first.id, equals('sched-2'));
    });

    test('does not affect other schedules', () async {
      await dao.insertItem(makeEntry(id: 'sched-1'));
      await dao.insertItem(makeEntry(id: 'sched-2'));

      await dao.markProcessed('sched-1');

      final sched2 = await dao.getById('sched-2');
      expect(sched2!.processedAt, isNull);
    });
  });

  group('deactivate', () {
    test('sets isActive to false', () async {
      await dao.insertItem(makeEntry(id: 'sched-1', isActive: true));

      await dao.deactivate('sched-1');

      final result = await dao.getById('sched-1');
      expect(result, isNotNull);
      expect(result!.isActive, isFalse);
    });

    test('excluded from watchAll after deactivation', () async {
      await dao.insertItem(makeEntry(id: 'sched-1', isActive: true));
      await dao.insertItem(makeEntry(id: 'sched-2', isActive: true));

      await dao.deactivate('sched-1');

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('sched-2'));
    });

    test('excluded from getPending after deactivation', () async {
      await dao.insertItem(makeEntry(id: 'sched-1', isActive: true));

      await dao.deactivate('sched-1');

      final results = await dao.getPending(userId);
      expect(results, isEmpty);
    });

    test('does not affect other schedules', () async {
      await dao.insertItem(makeEntry(id: 'sched-1', isActive: true));
      await dao.insertItem(makeEntry(id: 'sched-2', isActive: true));

      await dao.deactivate('sched-1');

      final sched2 = await dao.getById('sched-2');
      expect(sched2!.isActive, isTrue);
    });
  });

  group('hardDelete', () {
    test('permanently removes the schedule', () async {
      await dao.insertItem(makeEntry(id: 'sched-1'));

      await dao.hardDelete('sched-1');

      final result = await dao.getById('sched-1');
      expect(result, isNull);
    });

    test('does not affect other schedules', () async {
      await dao.insertItem(makeEntry(id: 'sched-1'));
      await dao.insertItem(makeEntry(id: 'sched-2'));

      await dao.hardDelete('sched-1');

      final remaining = await dao.getAll(userId);
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('sched-2'));
    });

    test('is a no-op when schedule does not exist', () async {
      await dao.hardDelete('non-existent');

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });
}
