import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/breeding_pairs_table.dart';

@DataClassName('IncubationRow')
class IncubationsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get species =>
      text().map(speciesConverter).withDefault(const Constant('unknown'))();
  TextColumn get status => text().map(incubationStatusConverter)();
  IntColumn get version => integer().withDefault(const Constant(1))();
  // FK to clutches is declared via a raw `.customConstraint(...)` rather than
  // `.references(ClutchesTable, #id)` — and the clutches_table import is dropped —
  // to break the clutches <-> incubations module cycle that intermittently
  // crashes drift_dev 2.31 codegen ("Circular error when deserializing drift
  // modules"). The generated `REFERENCES clutches (id)` column constraint (and
  // the nullable text column) is identical to before.
  TextColumn get clutchId =>
      text().nullable().customConstraint('NULL REFERENCES clutches (id)')();
  TextColumn get breedingPairId =>
      text().nullable().references(BreedingPairsTable, #id)();
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
