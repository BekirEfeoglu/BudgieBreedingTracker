import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/core/utils/storage_url_normalizer.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';

extension PhotoRowMapper on PhotoRow {
  Photo toModel() => Photo(
    id: id,
    userId: userId,
    entityType: entityType,
    entityId: entityId,
    fileName: fileName,
    filePath: StorageUrlNormalizer.normalizePublicObjectUrl(filePath),
    fileSize: fileSize,
    mimeType: mimeType,
    isPrimary: isPrimary,
    createdAt: createdAt?.toUtc(),
    updatedAt: updatedAt?.toUtc(),
  );
}

extension PhotoModelMapper on Photo {
  PhotosTableCompanion toCompanion() => PhotosTableCompanion(
    id: Value(id),
    userId: Value(userId),
    entityType: Value(entityType),
    entityId: Value(entityId),
    fileName: Value(fileName),
    filePath: Value(StorageUrlNormalizer.normalizePublicObjectUrl(filePath)),
    fileSize: Value(fileSize),
    mimeType: Value(mimeType),
    isPrimary: Value(isPrimary),
    createdAt: Value(createdAt?.toUtc()),
    updatedAt: Value((updatedAt ?? DateTime.now()).toUtc()),
  );
}
