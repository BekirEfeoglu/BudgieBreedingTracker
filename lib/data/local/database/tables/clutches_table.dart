import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/breeding_pairs_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/birds_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/nests_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/incubations_table.dart';

@DataClassName('ClutchRow')
class ClutchesTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text().nullable()();
  TextColumn get breedingId =>
      text().nullable().references(BreedingPairsTable, #id)();
  TextColumn get incubationId =>
      text().nullable().references(IncubationsTable, #id)();
  TextColumn get maleBirdId =>
      text().nullable().references(BirdsTable, #id)();
  TextColumn get femaleBirdId =>
      text().nullable().references(BirdsTable, #id)();
  TextColumn get nestId =>
      text().nullable().references(NestsTable, #id)();
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
