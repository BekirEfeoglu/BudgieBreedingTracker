import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/events_table.dart';

@DataClassName('EventReminderRow')
class EventRemindersTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get eventId =>
      text().references(EventsTable, #id)();
  IntColumn get minutesBefore => integer().withDefault(const Constant(30))();
  TextColumn get type => text().map(reminderTypeConverter)();
  BoolColumn get isSent => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'event_reminders';
}
