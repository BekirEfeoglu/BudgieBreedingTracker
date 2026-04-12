import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/conflict_history_model.dart';

extension ConflictHistoryRowMapper on ConflictHistoryRow {
  ConflictHistory toModel() => ConflictHistory(
    id: id,
    userId: userId,
    tableName: tableName_,
    recordId: recordId,
    description: description,
    conflictType: conflictType,
    resolvedAt: resolvedAt,
    createdAt: createdAt,
  );
}

extension ConflictHistoryModelMapper on ConflictHistory {
  ConflictHistoryTableCompanion toCompanion() => ConflictHistoryTableCompanion(
    id: Value(id),
    userId: Value(userId),
    tableName_: Value(tableName),
    recordId: Value(recordId),
    description: Value(description),
    conflictType: Value(conflictType),
    resolvedAt: Value(resolvedAt),
    createdAt: Value(createdAt ?? DateTime.now()),
  );
}
