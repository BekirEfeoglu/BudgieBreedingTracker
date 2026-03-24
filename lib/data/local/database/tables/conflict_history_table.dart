import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';

@DataClassName('ConflictHistoryRow')
class ConflictHistoryTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get tableName_ => text().named('table_name')();
  TextColumn get recordId => text()();
  TextColumn get description => text()();
  TextColumn get conflictType => text().map(conflictTypeConverter)();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'conflict_history';
}
