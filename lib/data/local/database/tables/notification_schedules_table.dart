import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';

@DataClassName('NotificationScheduleRow')
class NotificationSchedulesTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text().map(notificationTypeConverter)();
  TextColumn get title => text()();
  TextColumn get message => text().nullable()();
  DateTimeColumn get scheduledAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  IntColumn get intervalMinutes => integer().nullable()();
  TextColumn get relatedEntityId => text().nullable()();
  TextColumn get priority => text().map(notificationPriorityConverter)();
  TextColumn get metadata => text().nullable()();
  DateTimeColumn get processedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'notification_schedules';
}
