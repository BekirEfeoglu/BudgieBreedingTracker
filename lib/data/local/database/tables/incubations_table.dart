import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';

@DataClassName('IncubationRow')
class IncubationsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get status => text().map(incubationStatusConverter)();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get clutchId => text().nullable()();
  TextColumn get breedingPairId => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get expectedHatchDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'incubations';
}
