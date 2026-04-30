import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/photos_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/photo_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_service.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

/// Repository for [Photo] entities.
///
/// Custom implementation (not extending [BaseRepository]) because photos
/// use hard-delete (no is_deleted column) and have their own sync logic
/// via [SyncMetadataDao] — the standard [SyncableRepository] soft-delete
/// pattern doesn't apply.
class PhotoRepository {
  final PhotosDao _localDao;
  final PhotoRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;
  final StorageService? _storageService;

  static const _uuid = Uuid();

  PhotoRepository({
    required PhotosDao localDao,
    required PhotoRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
    StorageService? storageService,
  }) : _localDao = localDao,
       _remoteSource = remoteSource,
       _syncDao = syncDao,
       _storageService = storageService;

  static const _table = SupabaseConstants.photosTable;

  Stream<List<Photo>> watchAll(String userId) => _localDao.watchAll(userId);

  Stream<List<Photo>> watchByEntity(String entityId) =>
      _localDao.watchByEntity(entityId);

  Future<List<Photo>> getAll(String userId) => _localDao.getAll(userId);

  Future<Photo?> getById(String id) => _localDao.getById(id);

  Future<List<Photo>> getByEntity(String entityId) =>
      _localDao.getByEntity(entityId);

  Future<String> uploadBirdPhoto({
    required String userId,
    required String birdId,
    required XFile file,
  }) {
    final storageService = _storageService;
    if (storageService == null) {
      throw StateError('Photo storage service is not configured');
    }

    return storageService.uploadBirdPhoto(
      userId: userId,
      birdId: birdId,
      file: file,
    );
  }

  Future<void> deleteStorageForPhoto(Photo photo) {
    final storageService = _storageService;
    if (storageService == null) {
      throw StateError('Photo storage service is not configured');
    }

    final filePath = photo.filePath;
    if (filePath == null || filePath.isEmpty) return Future.value();

    final storagePath = _storagePathFromPublicUrl(
      filePath,
      SupabaseConstants.birdPhotosBucket,
    );
    if (storagePath == null) return Future.value();

    return storageService.deleteBirdPhoto(storagePath: storagePath);
  }

  Future<void> save(Photo item) async {
    await _localDao.insertItem(item);
    await _markPending(item.id, item.userId);
    try {
      await push(item);
    } catch (e, st) {
      // Offline or error — pending record stays for next sync
      AppLogger.warning('[PhotoRepo] save->push deferred: $e');
      AppLogger.debug('[PhotoRepo] save->push stack trace: $st');
    }
  }

  Future<void> remove(String id) async {
    final item = await _localDao.getById(id);
    await _localDao.hardDelete(id);
    if (item != null) {
      await _markPending(id, item.userId);
      // Immediate remote delete — falls back to next sync on failure
      try {
        await _remoteSource.deleteById(id, userId: item.userId);
        await _syncDao.deleteByRecord(_table, id);
      } catch (e) {
        AppLogger.debug(
          '[PhotoRepo] Immediate remote delete failed, will retry on next sync: $e',
        );
      }
    }
  }

  Future<void> removeByEntity(String entityId) =>
      _localDao.deleteByEntity(entityId);

  Future<void> pull(String userId, {DateTime? lastSyncedAt}) async {
    try {
      final remote = lastSyncedAt != null
          ? await _remoteSource.fetchUpdatedSince(userId, lastSyncedAt)
          : await _remoteSource.fetchAll(userId);
      if (remote.isNotEmpty) {
        await _localDao.insertAll(remote);
      }
      // Full sync reconciliation: remove local orphans not on server
      if (lastSyncedAt == null) {
        final remoteIds = remote.map((r) => r.id).toSet();
        final localItems = await _localDao.getAll(userId);
        final pendingIds = await _syncDao.getPendingRecordIds(userId);
        for (final item in localItems) {
          if (!remoteIds.contains(item.id) && !pendingIds.contains(item.id)) {
            await _localDao.hardDelete(item.id);
          }
        }
      }
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('[PhotoRepository] Pull failed', e, st);
    }
  }

  Future<void> push(Photo item) async {
    try {
      await _remoteSource.upsert(item);
      await _syncDao.deleteByRecord(_table, item.id);
    } on AppException catch (e) {
      await _markError(item.id, item.userId, e.message);
    }
  }

  /// Pushes all pending photo records for a user to Supabase.
  Future<PushStats> pushAll(String userId) async {
    int pushed = 0;
    int orphansCleaned = 0;
    final tablePending = await _syncDao.getPendingByTable(userId, _table);

    for (final meta in tablePending) {
      final item = await _localDao.getById(meta.recordId ?? '');
      if (item == null) {
        // Orphan sync_metadata — clean up
        await _syncDao.deleteByRecord(_table, meta.recordId ?? '');
        orphansCleaned++;
        continue;
      }
      await push(item);
      pushed++;
    }
    return (pushed: pushed, orphansCleaned: orphansCleaned);
  }

  /// Saves multiple photos locally and marks them for sync.
  Future<void> saveAll(List<Photo> items) async {
    await _localDao.insertAll(items);
    if (items.isNotEmpty) {
      final syncEntries = items
          .map(
            (item) => SyncMetadata(
              id: _uuid.v7(),
              table: _table,
              userId: item.userId,
              status: SyncStatus.pending,
              recordId: item.id,
            ),
          )
          .toList();
      await _syncDao.insertAll(syncEntries);
    }
  }

  Future<void> _markPending(String recordId, String userId) async {
    final existing = await _syncDao.getByRecord(_table, recordId);
    if (existing != null) {
      await _syncDao.updateItem(
        existing.copyWith(
          status: SyncStatus.pending,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      await _syncDao.insertItem(
        SyncMetadata(
          id: _uuid.v7(),
          table: _table,
          userId: userId,
          status: SyncStatus.pending,
          recordId: recordId,
        ),
      );
    }
  }

  Future<void> _markError(
    String recordId,
    String userId,
    String message,
  ) async {
    final existing = await _syncDao.getByRecord(_table, recordId);
    if (existing != null) {
      await _syncDao.updateItem(
        existing.copyWith(
          status: SyncStatus.error,
          errorMessage: message,
          retryCount: (existing.retryCount ?? 0) + 1,
        ),
      );
    } else {
      await _syncDao.insertItem(
        SyncMetadata(
          id: _uuid.v7(),
          table: _table,
          userId: userId,
          status: SyncStatus.error,
          recordId: recordId,
          errorMessage: message,
          retryCount: 1,
          createdAt: DateTime.now(),
        ),
      );
    }
  }
}

String? _storagePathFromPublicUrl(String url, String bucket) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;

  final segments = uri.pathSegments;
  final bucketIdx = segments.indexOf(bucket);
  if (bucketIdx < 0 || bucketIdx + 1 >= segments.length) return null;

  return segments.sublist(bucketIdx + 1).join('/');
}
