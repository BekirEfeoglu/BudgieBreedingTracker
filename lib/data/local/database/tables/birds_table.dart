import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';

@DataClassName('BirdRow')
class BirdsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get gender => text().map(birdGenderConverter)();
  TextColumn get userId => text()();
  TextColumn get status => text().map(birdStatusConverter)();
  TextColumn get species => text().map(speciesConverter)();
  TextColumn get ringNumber => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  TextColumn get fatherId => text().nullable()();
  TextColumn get motherId => text().nullable()();
  TextColumn get colorMutation => text().map(birdColorConverter).nullable()();
  TextColumn get cageNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get birthDate => dateTime().nullable()();
  DateTimeColumn get deathDate => dateTime().nullable()();
  DateTimeColumn get soldDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// JSON-encoded list of mutation IDs.
  TextColumn get mutations => text().nullable()();

  /// JSON-encoded map of mutationId -> alleleState.
  TextColumn get genotypeInfo => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'birds';
}
