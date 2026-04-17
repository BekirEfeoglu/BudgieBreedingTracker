import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/events_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/event_mapper.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';

part 'events_dao.g.dart';

@DriftAccessor(tables: [EventsTable])
class EventsDao extends DatabaseAccessor<AppDatabase> with _$EventsDaoMixin {
  EventsDao(super.db);

  /// Watches all non-deleted events for a user.
  Stream<List<Event>> watchAll(String userId) {
    return (select(eventsTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  /// Watches a single event by id.
  Stream<Event?> watchById(String id) {
    return (select(eventsTable)
          ..where((t) => t.id.equals(id) & t.isDeleted.equals(false)))
        .watchSingleOrNull()
        .map((row) => row?.toModel());
  }

  /// Gets all non-deleted events for a user.
  Future<List<Event>> getAll(String userId) async {
    final rows = await (select(
      eventsTable,
    )..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))).get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Gets a single event by id.
  Future<Event?> getById(String id) async {
    final row = await (select(eventsTable)..where(
      (t) => t.id.equals(id) & t.isDeleted.equals(false),
    )).getSingleOrNull();
    return row?.toModel();
  }

  /// Inserts or updates an event.
  Future<void> insertItem(Event model) {
    return into(eventsTable).insertOnConflictUpdate(model.toCompanion());
  }

  /// Batch inserts events.
  Future<void> insertAll(List<Event> models) {
    return batch((b) {
      b.insertAllOnConflictUpdate(
        eventsTable,
        models.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  /// Updates an event.
  Future<bool> updateItem(Event model) {
    return update(eventsTable).replace(model.toCompanion());
  }

  /// Soft-deletes an event by setting isDeleted to true.
  Future<void> softDelete(String id) {
    return (update(eventsTable)..where((t) => t.id.equals(id))).write(
      EventsTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Permanently deletes an event.
  Future<int> hardDelete(String id) {
    return (delete(eventsTable)..where((t) => t.id.equals(id))).go();
  }

  /// Watches events within a date range for a user.
  Stream<List<Event>> watchByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) {
    return (select(eventsTable)..where(
          (t) =>
              t.userId.equals(userId) &
              t.isDeleted.equals(false) &
              t.eventDate.isBiggerOrEqualValue(start) &
              t.eventDate.isSmallerOrEqualValue(end),
        ))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }

  /// Gets upcoming events for a user, ordered by event date ascending.
  Future<List<Event>> getUpcoming(String userId, {int limit = 10}) async {
    final rows =
        await (select(eventsTable)
              ..where(
                (t) =>
                    t.userId.equals(userId) &
                    t.isDeleted.equals(false) &
                    t.eventDate.isBiggerOrEqualValue(DateTime.now()),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.eventDate)])
              ..limit(limit))
            .get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Gets active events for a specific chick filtered by event type.
  Future<List<Event>> getActiveByChickAndType(
    String chickId,
    EventType type,
  ) async {
    final rows = await (select(eventsTable)
          ..where(
            (t) =>
                t.chickId.equals(chickId) &
                t.type.equalsValue(type) &
                t.isDeleted.equals(false) &
                t.status.equalsValue(EventStatus.active),
          ))
        .get();
    return rows.map((r) => r.toModel()).toList();
  }

  /// Watches non-deleted events for a specific bird.
  Stream<List<Event>> watchByBird(String birdId) {
    return (select(eventsTable)
          ..where((t) => t.birdId.equals(birdId) & t.isDeleted.equals(false)))
        .watch()
        .map((rows) => rows.map((r) => r.toModel()).toList());
  }
}
