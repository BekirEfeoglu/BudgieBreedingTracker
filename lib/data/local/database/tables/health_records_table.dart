import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/birds_table.dart';

@DataClassName('HealthRecordRow')
class HealthRecordsTable extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get type => text().map(healthRecordTypeConverter)();
  TextColumn get title => text()();
  TextColumn get userId => text()();
  TextColumn get birdId =>
      text().nullable().references(BirdsTable, #id)();
  TextColumn get description => text().nullable()();
  TextColumn get treatment => text().nullable()();
  TextColumn get veterinarian => text().nullable()();
  TextColumn get notes => text().nullable()();
  RealColumn get weight => real().nullable()();
  RealColumn get cost => real().nullable()();
  DateTimeColumn get followUpDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'health_records';
}
