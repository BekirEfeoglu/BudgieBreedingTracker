import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/incubations_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/incubation_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:uuid/uuid.dart';

/// Repository for [Incubation] entities with offline-first sync support.
///
/// Incubation has no `isDeleted` field, so [remove] performs a hard delete.
class IncubationRepository extends BaseRepository<Incubation>
    with SyncableRepository<Incubation> {
  final IncubationsDao _localDao;
  final IncubationRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;

  static const _uuid = Uuid();

  IncubationRepository({
    required IncubationsDao localDao,
    required IncubationRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
  }) : _localDao = localDao,
       _remoteSource = remoteSource,
       _syncDao = syncDao;

  static const _table = SupabaseConstants.incubationsTable;

  /// Conflicts detected during the last [pull] operation.
  final List<({String recordId, String detail})> _lastPullConflicts = [];
  List<({String recordId, String detail})> get lastPullConflicts =>
      List.unmodifiable(_lastPullConflicts);

  // ── SyncableRepository overrides ─────────────────────────────────────
  @override
  SyncMetadataDao get syncDao => _syncDao;

  @override
  String get syncTableName => _table;

  @override
  Stream<List<Incubation>> watchAll(String userId) =>
      _localDao.watchAll(userId);

  @override
  Stream<Incubation?> watchById(String id) => _localDao.watchById(id);

  @override
  Future<List<Incubation>> getAll(String userId) => _localDao.getAll(userId);

  /// Returns the count of active incubations (SQL COUNT).
  Future<int> getActiveCount(String userId) =>
      _localDao.getActiveCount(userId);

  @override
  Future<Incubation?> getById(String id) => _localDao.getById(id);

  @override
  Future<void> save(Incubation item) async {
    await _localDao.insertItem(item);
    await markPending(item.id, item.userId);
    await tryImmediatePush(item);
  }

  @override
  Future<void> saveAll(List<Incubation> items) async {
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

  /// No soft-delete for Incubation; performs hard delete + sync mark.
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
          '[IncubationRepo] Immediate remote delete failed, will retry on next sync: $e',
        );
      }
    }
  }

  @override
  Future<void> hardRemove(String id) => _localDao.hardDelete(id);

  @override
  Future<void> pull(String userId, {DateTime? lastSyncedAt}) async {
    _lastPullConflicts.clear();
    try {
      final remote = lastSyncedAt != null
          ? await _remoteSource.fetchUpdatedSince(userId, lastSyncedAt)
          : await _remoteSource.fetchAll(userId);
      // Fetch local state BEFORE overwriting with remote data, so we have
      // accurate local/pending snapshots for reconciliation and conflict detection.
      final localItems = await _localDao.getAll(userId);
      final pendingIds = await _syncDao.getPendingRecordIds(userId);

      if (remote.isNotEmpty) {
        // Detect real conflicts: a conflict is when a local record has
        // PENDING sync metadata AND the remote record overwrites it.
        final localMap = {for (final item in localItems) item.id: item};
        for (final remoteItem in remote) {
          if (!pendingIds.contains(remoteItem.id)) continue;
          final localItem = localMap[remoteItem.id];
          if (localItem == null) continue;
          if (localItem.updatedAt != null &&
              remoteItem.updatedAt != null &&
              remoteItem.updatedAt!.isAfter(localItem.updatedAt!)) {
            _lastPullConflicts.add((
              recordId: remoteItem.id,
              detail: remoteItem.id,
            ));
          }
        }

        await _localDao.insertAll(remote);
      }
      // Full sync reconciliation: remove local orphans not on server
      if (lastSyncedAt == null) {
        final remoteIds = remote.map((r) => r.id).toSet();
        for (final item in localItems) {
          if (!remoteIds.contains(item.id) && !pendingIds.contains(item.id)) {
            await _localDao.hardDelete(item.id);
          }
        }
      }
    } on AppException {
      rethrow;
    } catch (e, st) {
      AppLogger.error('[IncubationRepository] Pull failed', e, st);
    }
  }

  @override
  Future<void> push(Incubation item) async {
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
            '[IncubationRepo] Orphan sync_metadata cleaned: ${meta.recordId}',
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

  /// Active incubations (live stream).
  Stream<List<Incubation>> watchActive(String userId) =>
      _localDao.watchActive(userId);

  /// Incubations by breeding pair.
  Future<List<Incubation>> getByBreedingPair(String pairId) =>
      _localDao.getByBreedingPair(pairId);

  /// Incubations by multiple breeding pair IDs (batch query).
  Future<List<Incubation>> getByBreedingPairIds(List<String> pairIds) =>
      _localDao.getByBreedingPairIds(pairIds);
}
