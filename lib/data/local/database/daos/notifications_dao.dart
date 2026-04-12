import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/notifications_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/notification_settings_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/notification_mapper.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/notification_settings_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';

part 'notifications_dao.g.dart';

@DriftAccessor(tables: [NotificationsTable, NotificationSettingsTable])
class NotificationsDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationsDaoMixin {
  NotificationsDao(super.db);

  Stream<List<AppNotification>> watchAll(String userId) {
    return (select(notificationsTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Stream<AppNotification?> watchById(String id) {
    return (select(notificationsTable)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  Future<List<AppNotification>> getAll(String userId) async {
    final rows = await (select(
      notificationsTable,
    )..where((t) => t.userId.equals(userId))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<AppNotification?> getById(String id) async {
    final row = await (select(
      notificationsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  Future<void> insertItem(AppNotification notification) {
    return into(
      notificationsTable,
    ).insertOnConflictUpdate(notification.toCompanion());
  }

  Future<void> insertAll(List<AppNotification> notifications) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        notificationsTable,
        notifications.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  Future<void> updateItem(AppNotification notification) {
    return update(notificationsTable).replace(notification.toCompanion());
  }

  Future<void> hardDelete(String id) {
    return (delete(notificationsTable)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<AppNotification>> watchUnread(String userId) {
    return (select(notificationsTable)
          ..where((t) => t.userId.equals(userId) & t.read.equals(false)))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Future<void> markAsRead(String id) {
    return (update(notificationsTable)..where((t) => t.id.equals(id))).write(
      NotificationsTableCompanion(
        read: const Value(true),
        readAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markAllAsRead(String userId) {
    return (update(
      notificationsTable,
    )..where((t) => t.userId.equals(userId) & t.read.equals(false))).write(
      NotificationsTableCompanion(
        read: const Value(true),
        readAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Deletes read notifications older than [daysOld] for a user.
  ///
  /// Returns the number of deleted rows. Called periodically during
  /// notification processing to prevent database bloat.
  Future<int> deleteOldRead(String userId, {int daysOld = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    return (delete(notificationsTable)..where(
          (t) =>
              t.userId.equals(userId) &
              t.read.equals(true) &
              t.createdAt.isSmallerThanValue(cutoff),
        ))
        .go();
  }

  Future<NotificationSettings?> getSettings(String userId) async {
    final row = await (select(
      notificationSettingsTable,
    )..where((t) => t.userId.equals(userId))).getSingleOrNull();
    return row?.toModel();
  }

  Future<void> upsertSettings(NotificationSettings settings) {
    return into(
      notificationSettingsTable,
    ).insertOnConflictUpdate(settings.toCompanion());
  }
}
