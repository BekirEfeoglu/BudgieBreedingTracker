import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/clutches_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/incubations_table.dart';

@DataClassName('EggRow')
class EggsTable extends Table {
  TextColumn get id => text()();
  DateTimeColumn get layDate => dateTime()();
  TextColumn get userId => text()();
  TextColumn get status => text().map(eggStatusConverter)();
  TextColumn get clutchId =>
      text().nullable().references(ClutchesTable, #id)();
  TextColumn get incubationId =>
      text().nullable().references(IncubationsTable, #id)();
  IntColumn get eggNumber => integer().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  DateTimeColumn get hatchDate => dateTime().nullable()();
  DateTimeColumn get fertileCheckDate => dateTime().nullable()();
  DateTimeColumn get discardDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'eggs';
}
