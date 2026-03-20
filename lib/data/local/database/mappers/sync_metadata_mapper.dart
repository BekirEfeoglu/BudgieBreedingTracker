import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';

extension SyncMetadataRowMapper on SyncMetadataRow {
  SyncMetadata toModel() => SyncMetadata(
    id: id,
    table: tableName_,
    userId: userId,
    status: status,
    recordId: recordId,
    errorMessage: errorMessage,
    retryCount: retryCount,
    lastSyncedAt: lastSyncedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension SyncMetadataModelMapper on SyncMetadata {
  SyncMetadataTableCompanion toCompanion() => SyncMetadataTableCompanion(
    id: Value(id),
    tableName_: Value(table),
    userId: Value(userId),
    status: Value(status),
    recordId: Value(recordId),
    errorMessage: Value(errorMessage),
    retryCount: Value(retryCount),
    lastSyncedAt: Value(lastSyncedAt),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt ?? DateTime.now()),
  );
}
