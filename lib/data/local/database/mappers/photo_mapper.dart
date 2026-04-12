import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';

extension PhotoRowMapper on PhotoRow {
  Photo toModel() => Photo(
    id: id,
    userId: userId,
    entityType: entityType,
    entityId: entityId,
    fileName: fileName,
    filePath: filePath,
    fileSize: fileSize,
    mimeType: mimeType,
    isPrimary: isPrimary,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension PhotoModelMapper on Photo {
  PhotosTableCompanion toCompanion() => PhotosTableCompanion(
    id: Value(id),
    userId: Value(userId),
    entityType: Value(entityType),
    entityId: Value(entityId),
    fileName: Value(fileName),
    filePath: Value(filePath),
    fileSize: Value(fileSize),
    mimeType: Value(mimeType),
    isPrimary: Value(isPrimary),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt ?? DateTime.now()),
  );
}
