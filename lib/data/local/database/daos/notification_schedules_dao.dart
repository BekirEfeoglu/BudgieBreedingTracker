import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/notification_schedules_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/notification_schedule_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/notification_schedule_model.dart';

part 'notification_schedules_dao.g.dart';

@DriftAccessor(tables: [NotificationSchedulesTable])
class NotificationSchedulesDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationSchedulesDaoMixin {
  NotificationSchedulesDao(super.db);

  Stream<List<NotificationSchedule>> watchAll(String userId) {
    return (select(notificationSchedulesTable)
          ..where((t) => t.userId.equals(userId) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Stream<NotificationSchedule?> watchById(String id) {
    return (select(notificationSchedulesTable)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  Future<List<NotificationSchedule>> getAll(String userId) async {
    final rows = await (select(
      notificationSchedulesTable,
    )..where((t) => t.userId.equals(userId))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<NotificationSchedule?> getById(String id) async {
    final row = await (select(
      notificationSchedulesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toModel();
  }

  /// Returns the count of pending schedules without materializing rows.
  Future<int> countPending(String userId) async {
    final count = notificationSchedulesTable.id.count();
    final query = selectOnly(notificationSchedulesTable)
      ..addColumns([count])
      ..where(
        notificationSchedulesTable.userId.equals(userId) &
            notificationSchedulesTable.isActive.equals(true) &
            notificationSchedulesTable.processedAt.isNull(),
      );
    final row = await query.getSingle();
    return row.read(count)!;
  }

  Future<List<NotificationSchedule>> getPending(String userId) async {
    final rows =
        await (select(notificationSchedulesTable)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.isActive.equals(true) &
                  t.processedAt.isNull(),
            ))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<void> insertItem(NotificationSchedule model) {
    return into(
      notificationSchedulesTable,
    ).insertOnConflictUpdate(model.toCompanion());
  }

  Future<void> insertAll(List<NotificationSchedule> models) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        notificationSchedulesTable,
        models.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  Future<void> markProcessed(String id) {
    return (update(
      notificationSchedulesTable,
    )..where((t) => t.id.equals(id))).write(
      NotificationSchedulesTableCompanion(
        processedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deactivate(String id) {
    return (update(
      notificationSchedulesTable,
    )..where((t) => t.id.equals(id))).write(
      NotificationSchedulesTableCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> hardDelete(String id) {
    return (delete(
      notificationSchedulesTable,
    )..where((t) => t.id.equals(id))).go();
  }
}
