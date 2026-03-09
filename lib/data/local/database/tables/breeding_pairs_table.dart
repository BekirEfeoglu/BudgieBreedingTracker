import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';

@DataClassName('BreedingPairRow')
class BreedingPairsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get status => text().map(breedingStatusConverter)();
  TextColumn get maleId => text().nullable()();
  TextColumn get femaleId => text().nullable()();
  TextColumn get cageNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get pairingDate => dateTime().nullable()();
  DateTimeColumn get separationDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'breeding_pairs';
}
