import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/health_records_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/health_record_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:uuid/uuid.dart';

/// Repository for [HealthRecord] entities with offline-first sync support.
class HealthRecordRepository extends BaseRepository<HealthRecord>
    with SyncableRepository<HealthRecord> {
  final HealthRecordsDao _localDao;
  final HealthRecordRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;

  static const _uuid = Uuid();

  HealthRecordRepository({
    required HealthRecordsDao localDao,
    required HealthRecordRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
  })  : _localDao = localDao,
        _remoteSource = remoteSource,
        _syncDao = syncDao;

  static const _table = SupabaseConstants.healthRecordsTable;

  /// Conflicts detected during the last [pull] operation.
  final List<({String recordId, String detail})> lastPullConflicts = [];

  // ── SyncableRepository overrides ─────────────────────────────────────
  @override
  SyncMetadataDao get syncDao => _syncDao;

  @override
  String get syncTableName => _table;

  @override
  Stream<List<HealthRecord>> watchAll(String userId) =>
      _localDao.watchAll(userId);

  @override
  Stream<HealthRecord?> watchById(String id) => _localDao.watchById(id);

  @override
  Future<List<HealthRecord>> getAll(String userId) =>
      _localDao.getAll(userId);

  @override
  Future<HealthRecord?> getById(String id) => _localDao.getById(id);

  @override
  Future<void> save(HealthRecord item) async {
    await _localDao.insertItem(item);
    await markPending(item.id, item.userId);
    await tryImmediatePush(item);
  }

  @override
  Future<void> saveAll(List<HealthRecord> items) async {
    await _localDao.insertAll(items);
    if (items.isNotEmpty) {
      final syncEntries = items.map((item) => SyncMetadata(
        id: _uuid.v4(),
        table: _table,
        userId: item.userId,
        status: SyncStatus.pending,
        recordId: item.id,
      )).toList();
      await _syncDao.insertAll(syncEntries);
    }
  }

  @override
  Future<void> remove(String id) async {
    final item = await _localDao.getById(id);
    await _localDao.softDelete(id);
    if (item != null) {
      await markPending(id, item.userId);
      await tryImmediatePush(
        item.copyWith(isDeleted: true, updatedAt: DateTime.now()),
      );
    }
  }

  @override
  Future<void> hardRemove(String id) => _localDao.hardDelete(id);

  @override
  Future<void> pull(String userId, {DateTime? lastSyncedAt}) async {
    lastPullConflicts.clear();
    try {
      final remote = lastSyncedAt != null
          ? await _remoteSource.fetchUpdatedSince(userId, lastSyncedAt)
          : await _remoteSource.fetchAll(userId);

      if (remote.isNotEmpty) {
        // Fetch local state once for both conflict detection and reconciliation
        final localItems = await _localDao.getAll(userId);
        final pendingIds = await _syncDao.getPendingRecordIds(userId);
        final localMap = {for (final item in localItems) item.id: item};

        // Detect conflicts before overwriting local data
        for (final remoteItem in remote) {
          if (pendingIds.contains(remoteItem.id)) continue;
          final localItem = localMap[remoteItem.id];
          if (localItem == null) continue;
          if (localItem.updatedAt != null &&
              remoteItem.updatedAt != null &&
              remoteItem.updatedAt!.isAfter(localItem.updatedAt!)) {
            lastPullConflicts.add((
              recordId: remoteItem.id,
              detail: remoteItem.title,
            ));
          }
        }

        await _localDao.insertAll(remote);

        // Full sync reconciliation: remove local orphans not on server
        if (lastSyncedAt == null) {
          final remoteIds = remote.map((r) => r.id).toSet();
          for (final item in localItems) {
            if (!remoteIds.contains(item.id) && !pendingIds.contains(item.id)) {
              await _localDao.hardDelete(item.id);
            }
          }
        }
      } else if (lastSyncedAt == null) {
        // No remote data but full reconciliation needed — delete all local
        final localItems = await _localDao.getAll(userId);
        final pendingIds = await _syncDao.getPendingRecordIds(userId);
        for (final item in localItems) {
          if (!pendingIds.contains(item.id)) {
            await _localDao.hardDelete(item.id);
          }
        }
      }
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('[HealthRecordRepository] Pull failed', e, st);
    }
  }

  @override
  Future<void> push(HealthRecord item) async {
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
      final item = await _localDao.getById(meta.recordId ?? '');
      if (item == null) {
        AppLogger.warning('[HealthRecordRepo] Orphan sync_metadata cleaned: ${meta.recordId}');
        await _syncDao.deleteByRecord(_table, meta.recordId ?? '');
        orphansCleaned++;
        continue;
      }
      await push(item);
      pushed++;
    }
    return (pushed: pushed, orphansCleaned: orphansCleaned);
  }

  /// Health records for a specific bird (live stream).
  Stream<List<HealthRecord>> watchByBird(String birdId) =>
      _localDao.watchByBird(birdId);

  /// Latest health records for a bird.
  Future<List<HealthRecord>> getLatest(String birdId, {int limit = 5}) =>
      _localDao.getLatest(birdId, limit: limit);

}
