import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notifications_dao.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';

void main() {
  late AppDatabase db;
  late NotificationsDao dao;

  const userId = 'user-1';
  const otherId = 'user-2';

  AppNotification makeEntry({
    String id = 'notif-1',
    String user = userId,
    String title = 'Test Notification',
    NotificationType type = NotificationType.eggTurning,
    bool read = false,
  }) {
    return AppNotification(
      id: id,
      title: title,
      userId: user,
      type: type,
      read: read,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.notificationsDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('watchAll', () {
    test('returns all notifications for the user', () async {
      await dao.insertItem(makeEntry(id: 'notif-1'));
      await dao.insertItem(makeEntry(id: 'notif-2'));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(2));
    });

    test('does not return notifications for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'notif-1', user: userId));
      await dao.insertItem(makeEntry(id: 'notif-2', user: otherId));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('notif-1'));
    });

    test('returns empty list when no notifications exist', () async {
      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });

    test('returns both read and unread notifications', () async {
      await dao.insertItem(makeEntry(id: 'notif-1', read: false));
      await dao.insertItem(makeEntry(id: 'notif-2', read: true));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(2));
    });
  });

  group('watchById', () {
    test('returns the notification when it exists', () async {
      await dao.insertItem(makeEntry(id: 'notif-1'));

      final result = await dao.watchById('notif-1').first;
      expect(result, isNotNull);
      expect(result!.id, equals('notif-1'));
      expect(result.title, equals('Test Notification'));
    });

    test('returns null when notification does not exist', () async {
      final result = await dao.watchById('non-existent').first;
      expect(result, isNull);
    });
  });

  group('getAll', () {
    test('returns all notifications for the user', () async {
      await dao.insertItem(makeEntry(id: 'notif-1'));
      await dao.insertItem(makeEntry(id: 'notif-2'));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });

    test('does not return notifications for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'notif-1', user: userId));
      await dao.insertItem(makeEntry(id: 'notif-2', user: otherId));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('returns empty list when no notifications exist', () async {
      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('getById', () {
    test('returns the notification when it exists', () async {
      await dao.insertItem(makeEntry(id: 'notif-1'));

      final result = await dao.getById('notif-1');
      expect(result, isNotNull);
      expect(result!.id, equals('notif-1'));
      expect(result.type, equals(NotificationType.eggTurning));
    });

    test('returns null when notification does not exist', () async {
      final result = await dao.getById('non-existent');
      expect(result, isNull);
    });
  });

  group('insertItem', () {
    test('inserts a new notification', () async {
      await dao.insertItem(makeEntry(id: 'notif-1'));

      final result = await dao.getById('notif-1');
      expect(result, isNotNull);
      expect(result!.title, equals('Test Notification'));
    });

    test('upserts on conflict (updates existing)', () async {
      await dao.insertItem(makeEntry(id: 'notif-1', title: 'Original'));
      await dao.insertItem(makeEntry(id: 'notif-1', title: 'Updated'));

      final result = await dao.getById('notif-1');
      expect(result, isNotNull);
      expect(result!.title, equals('Updated'));
    });
  });

  group('insertAll', () {
    test('inserts multiple notifications in batch', () async {
      final items = [
        makeEntry(id: 'notif-1'),
        makeEntry(id: 'notif-2'),
        makeEntry(id: 'notif-3'),
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
      await dao.insertItem(makeEntry(id: 'notif-1', title: 'Original'));
      await dao.insertAll([
        makeEntry(id: 'notif-1', title: 'Batch Updated'),
        makeEntry(id: 'notif-2', title: 'New Notification'),
      ]);

      final updated = await dao.getById('notif-1');
      expect(updated!.title, equals('Batch Updated'));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });
  });

  group('hardDelete', () {
    test('permanently removes the notification', () async {
      await dao.insertItem(makeEntry(id: 'notif-1'));

      await dao.hardDelete('notif-1');

      final result = await dao.getById('notif-1');
      expect(result, isNull);
    });

    test('does not affect other notifications', () async {
      await dao.insertItem(makeEntry(id: 'notif-1'));
      await dao.insertItem(makeEntry(id: 'notif-2'));

      await dao.hardDelete('notif-1');

      final remaining = await dao.getAll(userId);
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('notif-2'));
    });

    test('is a no-op when notification does not exist', () async {
      await dao.hardDelete('non-existent');

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('watchUnread', () {
    test('returns only unread notifications for the user', () async {
      await dao.insertItem(makeEntry(id: 'notif-1', read: false));
      await dao.insertItem(makeEntry(id: 'notif-2', read: true));

      final results = await dao.watchUnread(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('notif-1'));
    });

    test('does not return notifications for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'notif-1', user: userId, read: false));
      await dao.insertItem(
        makeEntry(id: 'notif-2', user: otherId, read: false),
      );

      final results = await dao.watchUnread(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('notif-1'));
    });

    test('returns empty list when all notifications are read', () async {
      await dao.insertItem(makeEntry(id: 'notif-1', read: true));
      await dao.insertItem(makeEntry(id: 'notif-2', read: true));

      final results = await dao.watchUnread(userId).first;
      expect(results, isEmpty);
    });

    test('returns empty list when no notifications exist', () async {
      final results = await dao.watchUnread(userId).first;
      expect(results, isEmpty);
    });
  });

  group('markAsRead', () {
    test('sets read to true', () async {
      await dao.insertItem(makeEntry(id: 'notif-1', read: false));

      await dao.markAsRead('notif-1');

      final result = await dao.getById('notif-1');
      expect(result, isNotNull);
      expect(result!.read, isTrue);
    });

    test('sets readAt timestamp', () async {
      await dao.insertItem(makeEntry(id: 'notif-1', read: false));

      await dao.markAsRead('notif-1');

      final result = await dao.getById('notif-1');
      expect(result, isNotNull);
      expect(result!.readAt, isNotNull);
    });

    test('excluded from watchUnread after marking read', () async {
      await dao.insertItem(makeEntry(id: 'notif-1', read: false));
      await dao.insertItem(makeEntry(id: 'notif-2', read: false));

      await dao.markAsRead('notif-1');

      final results = await dao.watchUnread(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('notif-2'));
    });

    test('does not affect other notifications', () async {
      await dao.insertItem(makeEntry(id: 'notif-1', read: false));
      await dao.insertItem(makeEntry(id: 'notif-2', read: false));

      await dao.markAsRead('notif-1');

      final notif2 = await dao.getById('notif-2');
      expect(notif2!.read, isFalse);
    });
  });

  group('markAllAsRead', () {
    test('marks all unread notifications as read for the user', () async {
      await dao.insertItem(makeEntry(id: 'notif-1', read: false));
      await dao.insertItem(makeEntry(id: 'notif-2', read: false));
      await dao.insertItem(makeEntry(id: 'notif-3', read: true));

      await dao.markAllAsRead(userId);

      final unread = await dao.watchUnread(userId).first;
      expect(unread, isEmpty);

      final all = await dao.getAll(userId);
      expect(all.every((n) => n.read), isTrue);
    });

    test('does not affect notifications for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'notif-1', user: userId, read: false));
      await dao.insertItem(
        makeEntry(id: 'notif-2', user: otherId, read: false),
      );

      await dao.markAllAsRead(userId);

      final userResults = await dao.watchUnread(userId).first;
      expect(userResults, isEmpty);

      final otherResults = await dao.watchUnread(otherId).first;
      expect(otherResults.length, equals(1));
      expect(otherResults.first.id, equals('notif-2'));
    });

    test('is a no-op when no unread notifications exist', () async {
      await dao.insertItem(makeEntry(id: 'notif-1', read: true));

      await dao.markAllAsRead(userId);

      final all = await dao.getAll(userId);
      expect(all.length, equals(1));
      expect(all.first.read, isTrue);
    });

    test('sets readAt for all marked notifications', () async {
      await dao.insertItem(makeEntry(id: 'notif-1', read: false));
      await dao.insertItem(makeEntry(id: 'notif-2', read: false));

      await dao.markAllAsRead(userId);

      final notif1 = await dao.getById('notif-1');
      final notif2 = await dao.getById('notif-2');
      expect(notif1!.readAt, isNotNull);
      expect(notif2!.readAt, isNotNull);
    });
  });
}
