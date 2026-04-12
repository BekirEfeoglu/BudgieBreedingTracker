import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';

/// Repository for [SyncMetadata] — local-only, no remote source.
///
/// Provides a clean API for querying and managing sync state across
/// all entity tables.
class SyncMetadataRepository {
  final SyncMetadataDao _localDao;

  SyncMetadataRepository({required SyncMetadataDao localDao})
    : _localDao = localDao;

  /// Watches all sync metadata for a user.
  Stream<List<SyncMetadata>> watchAll(String userId) =>
      _localDao.watchAll(userId);

  /// Gets all sync metadata for a user.
  Future<List<SyncMetadata>> getAll(String userId) => _localDao.getAll(userId);

  /// Gets sync metadata by id.
  Future<SyncMetadata?> getById(String id) => _localDao.getById(id);

  /// Gets sync metadata for a specific record.
  Future<SyncMetadata?> getByRecord(String tableName, String recordId) =>
      _localDao.getByRecord(tableName, recordId);

  /// Gets all pending sync records for a user.
  Future<List<SyncMetadata>> getPending(String userId) =>
      _localDao.getPending(userId);

  /// Gets all error sync records for a user.
  Future<List<SyncMetadata>> getErrors(String userId) =>
      _localDao.getErrors(userId);

  /// Inserts or updates a sync metadata record.
  Future<void> save(SyncMetadata metadata) => _localDao.insertItem(metadata);

  /// Updates sync status for a record.
  Future<void> updateStatus(String id, SyncStatus status) =>
      _localDao.updateStatus(id, status);

  /// Deletes sync metadata for a specific record.
  Future<void> deleteByRecord(String tableName, String recordId) =>
      _localDao.deleteByRecord(tableName, recordId);

  /// Permanently deletes a sync metadata entry.
  Future<void> hardRemove(String id) => _localDao.hardDelete(id);
}
