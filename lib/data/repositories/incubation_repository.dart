import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/breeding_pairs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/clutches_dao.dart';
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
/// Uses [ValidatedSyncMixin] for stale-error cleanup + FK validation. The
/// mixin's default `pushAll` would treat hard-deleted tombstones as
/// orphans because [getLocalByIdForSync] returns null, so [pushAll] is
/// overridden to handle [SyncStatus.pendingDelete] explicitly first.
class IncubationRepository extends BaseRepository<Incubation>
    with SyncableRepository<Incubation>, ValidatedSyncMixin<Incubation> {
  final IncubationsDao _localDao;
  final IncubationRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;
  final BreedingPairsDao _breedingPairsDao;
  final ClutchesDao _clutchesDao;

  static const _uuid = Uuid();

  IncubationRepository({
    required IncubationsDao localDao,
    required IncubationRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
    required BreedingPairsDao breedingPairsDao,
    required ClutchesDao clutchesDao,
  }) : _localDao = localDao,
       _remoteSource = remoteSource,
       _syncDao = syncDao,
       _breedingPairsDao = breedingPairsDao,
       _clutchesDao = clutchesDao;

  static const _table = SupabaseConstants.incubationsTable;

  /// Conflicts detected during the last [pull] operation.
  final List<({String recordId, String detail})> _lastPullConflicts = [];
  List<({String recordId, String detail})> get lastPullConflicts =>
      List.unmodifiable(_lastPullConflicts);

  // ── SyncableRepository / ValidatedSyncMixin overrides ────────────────
  @override
  SyncMetadataDao get syncDao => _syncDao;

  @override
  String get syncTableName => _table;

  @override
  String get syncLogTag => 'IncubationRepository';

  @override
  Future<Incubation?> getLocalById(String id) => _localDao.getById(id);

  @override
  String getEntityId(Incubation item) => item.id;

  @override
  String getEntityUserId(Incubation item) => item.userId;

  @override
  Stream<List<Incubation>> watchAll(String userId) =>
      _localDao.watchAll(userId);

  @override
  Stream<Incubation?> watchById(String id) => _localDao.watchById(id);

  @override
  Future<List<Incubation>> getAll(String userId) => _localDao.getAll(userId);

  /// Returns the count of active incubations (SQL COUNT).
  Future<int> getActiveCount(String userId) => _localDao.getActiveCount(userId);

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
  Future<String?> validateForeignKeys(Incubation incubation) async {
    if (incubation.breedingPairId != null) {
      // Soft-delete-aware lookup: a pair waiting for tombstone push
      // should report as "pending tombstone sync" so the mixin's
      // continue-loop retries on the next push rather than treating
      // the child as a true orphan and stranding it forever.
      final pair = await _breedingPairsDao
          .getByIdIncludingDeleted(incubation.breedingPairId!);
      if (pair == null) {
        return 'Referenced breeding pair ${incubation.breedingPairId} not found locally';
      }
      if (pair.isDeleted) {
        return 'Referenced breeding pair ${incubation.breedingPairId} pending tombstone sync';
      }
      final syncMeta = await _syncDao.getByRecord(
        SupabaseConstants.breedingPairsTable,
        incubation.breedingPairId!,
      );
      if (syncMeta != null &&
          (syncMeta.status == SyncStatus.pending ||
              syncMeta.status == SyncStatus.pendingDelete)) {
        return 'Breeding pair ${incubation.breedingPairId} not yet synced to server';
      }
    }
    if (incubation.clutchId != null) {
      final clutch =
          await _clutchesDao.getByIdIncludingDeleted(incubation.clutchId!);
      if (clutch == null) {
        return 'Referenced clutch ${incubation.clutchId} not found locally';
      }
      if (clutch.isDeleted) {
        return 'Referenced clutch ${incubation.clutchId} pending tombstone sync';
      }
      final syncMeta = await _syncDao.getByRecord(
        SupabaseConstants.clutchesTable,
        incubation.clutchId!,
      );
      if (syncMeta != null &&
          (syncMeta.status == SyncStatus.pending ||
              syncMeta.status == SyncStatus.pendingDelete)) {
        return 'Clutch ${incubation.clutchId} not yet synced to server';
      }
    }
    return null;
  }

  /// Hard-delete pushAll: handles [SyncStatus.pendingDelete] explicitly,
  /// then delegates the normal path to the mixin's FK-validated loop.
  /// Without the explicit branch, the mixin would treat hard-deleted
  /// tombstones as orphans (because `getLocalById` returns null) and
  /// silently clean them up — the remote row would never be deleted.
  @override
  Future<PushStats> pushAll(String userId) async {
    int pushed = 0;
    int orphansCleaned = 0;
    await clearStaleErrors(userId);

    final tablePending = await _syncDao.getPendingByTable(userId, _table);
    for (final meta in tablePending) {
      final recordId = meta.recordId ?? '';
      if (recordId.isEmpty) {
        await _syncDao.deleteByRecord(_table, recordId);
        orphansCleaned++;
        continue;
      }

      if (meta.status == SyncStatus.pendingDelete) {
        try {
          await _remoteSource.deleteById(recordId, userId: userId);
          await _syncDao.deleteByRecord(_table, recordId);
          pushed++;
        } on AppException catch (e) {
          await markError(recordId, userId, e.message);
        }
        continue;
      }

      final item = await _localDao.getById(recordId);
      if (item == null) {
        AppLogger.warning(
          '[$syncLogTag] Orphan sync_metadata cleaned: $recordId',
        );
        await _syncDao.deleteByRecord(_table, recordId);
        orphansCleaned++;
        continue;
      }

      final orphanReason = await validateForeignKeys(item);
      if (orphanReason != null) {
        if (orphanReason.contains('not found locally')) {
          AppLogger.warning(
            '[$syncLogTag] True orphan ${item.id}: $orphanReason',
          );
          await markSyncError(item.id, item.userId, orphanReason);
          orphansCleaned++;
        }
        continue;
      }

      await push(item);
      pushed++;
    }
    return (pushed: pushed, orphansCleaned: orphansCleaned);
  }

  /// Active incubations (live stream).
  Stream<List<Incubation>> watchActive(String userId) =>
      _localDao.watchActive(userId);

  /// Incubations by breeding pair.
  Future<List<Incubation>> getByBreedingPair(String pairId) =>
      _localDao.getByBreedingPair(pairId);

  /// Incubations by breeding pair (live stream).
  Stream<List<Incubation>> watchByBreedingPair(String pairId) =>
      _localDao.watchByBreedingPair(pairId);

  /// Incubations by multiple breeding pair IDs (batch query).
  Future<List<Incubation>> getByBreedingPairIds(List<String> pairIds) =>
      _localDao.getByBreedingPairIds(pairIds);
}
