import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';

@DataClassName('NotificationRow')
class NotificationsTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  BoolColumn get read => boolean().withDefault(const Constant(false))();
  TextColumn get type => text().map(notificationTypeConverter)();
  TextColumn get priority => text().map(notificationPriorityConverter)();
  TextColumn get body => text().nullable()();
  TextColumn get userId => text()();
  TextColumn get referenceId => text().nullable()();
  TextColumn get referenceType => text().nullable()();
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  DateTimeColumn get readAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'notifications';
}
