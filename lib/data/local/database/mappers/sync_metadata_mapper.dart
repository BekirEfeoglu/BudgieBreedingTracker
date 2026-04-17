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
    lastSyncedAt: lastSyncedAt?.toUtc(),
    createdAt: createdAt?.toUtc(),
    updatedAt: updatedAt?.toUtc(),
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
    lastSyncedAt: Value(lastSyncedAt?.toUtc()),
    createdAt: Value(createdAt?.toUtc()),
    updatedAt: Value((updatedAt ?? DateTime.now()).toUtc()),
  );
}
