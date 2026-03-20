import 'package:drift/drift.dart';

@DataClassName('UserPreferenceRow')
class UserPreferencesTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get theme => text().withDefault(const Constant('system'))();
  TextColumn get language => text().withDefault(const Constant('tr'))();
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get compactView => boolean().withDefault(const Constant(false))();
  BoolColumn get emailNotifications =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get pushNotifications =>
      boolean().withDefault(const Constant(true))();
  TextColumn get customSettings => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'user_preferences';
}
