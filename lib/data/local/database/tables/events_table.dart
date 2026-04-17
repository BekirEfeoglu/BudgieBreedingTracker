import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/birds_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/breeding_pairs_table.dart';
import 'package:budgie_breeding_tracker/data/local/database/tables/chicks_table.dart';

@DataClassName('EventRow')
class EventsTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get eventDate => dateTime()();
  TextColumn get type => text().map(eventTypeConverter)();
  TextColumn get userId => text()();
  TextColumn get status => text().map(eventStatusConverter)();
  TextColumn get description => text().nullable()();
  TextColumn get birdId =>
      text().nullable().references(BirdsTable, #id)();
  TextColumn get breedingPairId =>
      text().nullable().references(BreedingPairsTable, #id)();
  TextColumn get chickId =>
      text().nullable().references(ChicksTable, #id)();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get reminderDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'events';
}
