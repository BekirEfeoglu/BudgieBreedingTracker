import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/chicks_table.dart';

@DataClassName('GrowthMeasurementRow')
class GrowthMeasurementsTable extends Table {
  TextColumn get id => text()();
  TextColumn get chickId =>
      text().references(ChicksTable, #id)();
  RealColumn get weight => real()();
  DateTimeColumn get measurementDate => dateTime()();
  TextColumn get userId => text()();
  RealColumn get height => real().nullable()();
  RealColumn get wingLength => real().nullable()();
  RealColumn get tailLength => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'growth_measurements';
}
