import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';

@DataClassName('ChickRow')
class ChicksTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get gender => text().map(birdGenderConverter)();
  TextColumn get healthStatus => text().map(chickHealthStatusConverter)();
  TextColumn get clutchId => text().nullable()();
  TextColumn get eggId => text().nullable()();
  TextColumn get birdId => text().nullable()();
  TextColumn get name => text().nullable()();
  TextColumn get ringNumber => text().nullable()();
  IntColumn get bandingDay => integer().withDefault(const Constant(10))();
  DateTimeColumn get bandingDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  RealColumn get hatchWeight => real().nullable()();
  DateTimeColumn get hatchDate => dateTime().nullable()();
  DateTimeColumn get weanDate => dateTime().nullable()();
  DateTimeColumn get deathDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'chicks';
}
