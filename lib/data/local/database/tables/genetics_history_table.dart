import 'package:drift/drift.dart';

@DataClassName('GeneticsHistoryRow')
class GeneticsHistoryTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();

  /// JSON-encoded map: mutationId -> alleleState for father.
  TextColumn get fatherGenotype => text()();

  /// JSON-encoded map: mutationId -> alleleState for mother.
  TextColumn get motherGenotype => text()();

  /// Optional bird ID if father was selected from collection.
  TextColumn get fatherBirdId => text().nullable()();

  /// Optional bird ID if mother was selected from collection.
  TextColumn get motherBirdId => text().nullable()();

  /// JSON-encoded offspring results.
  TextColumn get resultsJson => text()();

  /// User notes.
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'genetics_history';
}
