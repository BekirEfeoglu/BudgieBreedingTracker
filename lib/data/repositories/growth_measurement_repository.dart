import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/growth_measurements_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/growth_measurement_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:uuid/uuid.dart';

/// Repository for [GrowthMeasurement] entities with offline-first sync.
///
/// GrowthMeasurement has no `isDeleted` field, so [remove] performs a
/// hard delete.
class GrowthMeasurementRepository extends BaseRepository<GrowthMeasurement>
    with SyncableRepository<GrowthMeasurement> {
  final GrowthMeasurementsDao _localDao;
  final GrowthMeasurementRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;

  static const _uuid = Uuid();

  GrowthMeasurementRepository({
    required GrowthMeasurementsDao localDao,
    required GrowthMeasurementRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
  }) : _localDao = localDao,
       _remoteSource = remoteSource,
       _syncDao = syncDao;

  static const _table = SupabaseConstants.growthMeasurementsTable;

  // ── SyncableRepository overrides ─────────────────────────────────────
  @override
  SyncMetadataDao get syncDao => _syncDao;

  @override
  String get syncTableName => _table;

  @override
  Stream<List<GrowthMeasurement>> watchAll(String userId) =>
      _localDao.watchAll(userId);

  @override
  Stream<GrowthMeasurement?> watchById(String id) => _localDao.watchById(id);

  @override
  Future<List<GrowthMeasurement>> getAll(String userId) =>
      _localDao.getAll(userId);

  @override
  Future<GrowthMeasurement?> getById(String id) => _localDao.getById(id);

  @override
  Future<void> save(GrowthMeasurement item) async {
    await _localDao.insertItem(item);
    await markPending(item.id, item.userId);
    await tryImmediatePush(item);
  }

  @override
  Future<void> saveAll(List<GrowthMeasurement> items) async {
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

  /// No soft-delete for GrowthMeasurement; performs hard delete + sync mark.
  @override
  Future<void> remove(String id) async {
    final item = await _localDao.getById(id);
    await _localDao.hardDelete(id);
    if (item != null) {
      await _syncDao.insertItem(
        SyncMetadata(
          id: _uuid.v7(),
          table: _table,
          userId: item.userId,
          status: SyncStatus.pendingDelete,
          recordId: id,
        ),
      );
      // Immediate remote delete — falls back to next sync on failure
      try {
        await _remoteSource.deleteById(id, userId: item.userId);
        await _syncDao.deleteByRecord(_table, id);
      } catch (e) {
        AppLogger.debug(
          '[GrowthMeasurementRepo] Immediate remote delete failed, will retry on next sync: $e',
        );
      }
    }
  }

  @override
  Future<void> hardRemove(String id) => _localDao.hardDelete(id);

  @override
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
      AppLogger.error('[GrowthMeasurementRepository] Pull failed', e, st);
    }
  }

  @override
  Future<void> push(GrowthMeasurement item) async {
    try {
      await _remoteSource.upsert(item);
      await _syncDao.deleteByRecord(_table, item.id);
    } on AppException catch (e) {
      await markError(item.id, item.userId, e.message);
    }
  }

  @override
  Future<PushStats> pushAll(String userId) async {
    int pushed = 0;
    int orphansCleaned = 0;
    final tablePending = await _syncDao.getPendingByTable(userId, _table);
    for (final meta in tablePending) {
      if (meta.status == SyncStatus.pendingDelete) {
        try {
          await _remoteSource.deleteById(meta.recordId ?? '', userId: userId);
          await _syncDao.deleteByRecord(_table, meta.recordId ?? '');
          pushed++;
        } on AppException catch (e) {
          await markError(meta.recordId ?? '', userId, e.message);
        }
      } else {
        final item = await _localDao.getById(meta.recordId ?? '');
        if (item == null) {
          AppLogger.warning(
            '[GrowthMeasurementRepo] Orphan sync_metadata cleaned: ${meta.recordId}',
          );
          await _syncDao.deleteByRecord(_table, meta.recordId ?? '');
          orphansCleaned++;
          continue;
        }
        await push(item);
        pushed++;
      }
    }
    return (pushed: pushed, orphansCleaned: orphansCleaned);
  }

  /// Growth measurements for a specific chick (live stream).
  Stream<List<GrowthMeasurement>> watchByChick(String chickId) =>
      _localDao.watchByChick(chickId);

  /// Latest measurement for a chick.
  Future<GrowthMeasurement?> getLatest(String chickId) =>
      _localDao.getLatest(chickId);
}
