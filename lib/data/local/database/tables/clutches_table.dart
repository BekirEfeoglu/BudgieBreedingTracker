import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';

@DataClassName('ClutchRow')
class ClutchesTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text().nullable()();
  TextColumn get breedingId => text().nullable()();
  TextColumn get incubationId => text().nullable()();
  TextColumn get maleBirdId => text().nullable()();
  TextColumn get femaleBirdId => text().nullable()();
  TextColumn get nestId => text().nullable()();
  DateTimeColumn get pairDate => dateTime().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get status => text().map(breedingStatusConverter)();
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'clutches';
}
