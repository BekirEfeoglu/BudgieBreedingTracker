import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';

@DataClassName('SyncMetadataRow')
class SyncMetadataTable extends Table {
  TextColumn get id => text()();
  TextColumn get tableName_ => text().named('table_name')();
  TextColumn get userId => text()();
  TextColumn get status => text().map(syncStatusConverter)();
  TextColumn get recordId => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get retryCount => integer().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'sync_metadata';
}
