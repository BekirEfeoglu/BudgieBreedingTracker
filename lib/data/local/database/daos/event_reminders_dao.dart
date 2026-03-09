import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/event_reminders_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/event_reminder_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/event_reminder_model.dart';

part 'event_reminders_dao.g.dart';

@DriftAccessor(tables: [EventRemindersTable])
class EventRemindersDao extends DatabaseAccessor<AppDatabase>
    with _$EventRemindersDaoMixin {
  EventRemindersDao(super.db);

  Stream<List<EventReminder>> watchAll(String userId) {
    return (select(eventRemindersTable)
          ..where((t) =>
              t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Stream<List<EventReminder>> watchByEvent(String eventId) {
    return (select(eventRemindersTable)
          ..where((t) =>
              t.eventId.equals(eventId) & t.isDeleted.equals(false)))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  Future<List<EventReminder>> getAll(String userId) async {
    final rows = await (select(eventRemindersTable)
          ..where((t) =>
              t.userId.equals(userId) & t.isDeleted.equals(false)))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<List<EventReminder>> getByEvent(String eventId) async {
    final rows = await (select(eventRemindersTable)
          ..where((t) =>
              t.eventId.equals(eventId) & t.isDeleted.equals(false)))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<EventReminder?> getById(String id) async {
    final row =
        await (select(eventRemindersTable)..where((t) => t.id.equals(id)))
            .getSingleOrNull();
    return row?.toModel();
  }

  Stream<EventReminder?> watchById(String id) {
    return (select(eventRemindersTable)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  /// Returns the count of unsent reminders without materializing rows.
  Future<int> countUnsent(String userId) async {
    final count = eventRemindersTable.id.count();
    final query = selectOnly(eventRemindersTable)
      ..addColumns([count])
      ..where(eventRemindersTable.userId.equals(userId) &
          eventRemindersTable.isSent.equals(false) &
          eventRemindersTable.isDeleted.equals(false));
    final row = await query.getSingle();
    return row.read(count)!;
  }

  Future<List<EventReminder>> getUnsent(String userId) async {
    final rows = await (select(eventRemindersTable)
          ..where((t) =>
              t.userId.equals(userId) &
              t.isSent.equals(false) &
              t.isDeleted.equals(false)))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }

  Future<void> insertItem(EventReminder model) {
    return into(eventRemindersTable)
        .insertOnConflictUpdate(model.toCompanion());
  }

  Future<void> insertAll(List<EventReminder> models) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        eventRemindersTable,
        models.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  Future<void> markSent(String id) {
    return (update(eventRemindersTable)..where((t) => t.id.equals(id))).write(
      EventRemindersTableCompanion(
        isSent: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> softDelete(String id) {
    return (update(eventRemindersTable)..where((t) => t.id.equals(id))).write(
      EventRemindersTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> hardDelete(String id) {
    return (delete(eventRemindersTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteByEvent(String eventId) {
    return (delete(eventRemindersTable)
          ..where((t) => t.eventId.equals(eventId)))
        .go();
  }
}
