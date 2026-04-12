import 'package:drift/drift.dart';

@DataClassName('NotificationSettingsRow')
class NotificationSettingsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get language => text().withDefault(const Constant('tr'))();
  BoolColumn get soundEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get vibrationEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get eggTurningEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get temperatureAlertEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get humidityAlertEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get feedingReminderEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get incubationReminderEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get healthCheckEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get bandingEnabled =>
      boolean().withDefault(const Constant(true))();
  RealColumn get temperatureMin =>
      real().withDefault(const Constant(36.5))();
  RealColumn get temperatureMax =>
      real().withDefault(const Constant(38.5))();
  RealColumn get humidityMin =>
      real().withDefault(const Constant(50.0))();
  RealColumn get humidityMax =>
      real().withDefault(const Constant(70.0))();
  IntColumn get eggTurningIntervalMinutes =>
      integer().withDefault(const Constant(480))();
  IntColumn get feedingReminderIntervalMinutes =>
      integer().withDefault(const Constant(720))();
  IntColumn get temperatureCheckIntervalMinutes =>
      integer().withDefault(const Constant(360))();
  IntColumn get cleanupDaysOld =>
      integer().withDefault(const Constant(30))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'notification_settings';
}
