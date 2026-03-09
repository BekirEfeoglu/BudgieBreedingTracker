import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';

@DataClassName('ProfileRow')
class ProfilesTable extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  BoolColumn get isPremium => boolean().withDefault(const Constant(false))();
  TextColumn get subscriptionStatus =>
      text().map(subscriptionStatusConverter)();
  TextColumn get displayName => text().nullable()();
  TextColumn get fullName => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get role => text().nullable()();
  TextColumn get language => text().nullable()();
  DateTimeColumn get premiumExpiresAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'profiles';
}
