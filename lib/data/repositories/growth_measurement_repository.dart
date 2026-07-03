import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/chicks_dao.dart';
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
/// hard delete. Uses [ValidatedSyncMixin] to validate the FK to its
/// parent chick before pushing — without this, an offline chick delete
/// followed by a sync would push the orphan growth row indefinitely.
class GrowthMeasurementRepository extends BaseRepository<GrowthMeasurement>
    with
        SyncableRepository<GrowthMeasurement>,
        ValidatedSyncMixin<GrowthMeasurement> {
  final GrowthMeasurementsDao _localDao;
  final GrowthMeasurementRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;
  final ChicksDao _chicksDao;

  static const _uuid = Uuid();

  GrowthMeasurementRepository({
    required GrowthMeasurementsDao localDao,
    required GrowthMeasurementRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
    required ChicksDao chicksDao,
  }) : _localDao = localDao,
       _remoteSource = remoteSource,
       _syncDao = syncDao,
       _chicksDao = chicksDao;

  static const _table = SupabaseConstants.growthMeasurementsTable;

  // ── SyncableRepository overrides ─────────────────────────────────────
  @override
  SyncMetadataDao get syncDao => _syncDao;

  @override
  String get syncTableName => _table;

  // ── ValidatedSyncMixin overrides ─────────────────────────────────────

  @override
  String get syncLogTag => 'GrowthMeasurementRepository';

  @override
  Future<GrowthMeasurement?> getLocalById(String id) => _localDao.getById(id);

  @override
  String getEntityId(GrowthMeasurement item) => item.id;

  @override
  String getEntityUserId(GrowthMeasurement item) => item.userId;

  @override
  Future<String?> validateForeignKeys(GrowthMeasurement measurement) async {
    // Use IncludingDeleted so a chick awaiting tombstone push is reported
    // as "pending tombstone sync" instead of triggering the orphan-cleanup
    // path that would permanently strand the measurement.
    final chick = await _chicksDao.getByIdIncludingDeleted(measurement.chickId);
    if (chick == null) {
      return 'Referenced chick ${measurement.chickId} not found locally';
    }
    if (chick.isDeleted) {
      return 'Referenced chick ${measurement.chickId} pending tombstone sync';
    }
    final syncMeta = await _syncDao.getByRecord(
      SupabaseConstants.chicksTable,
      measurement.chickId,
    );
    if (syncMeta != null &&
        (syncMeta.status == SyncStatus.pending ||
            syncMeta.status == SyncStatus.pendingDelete)) {
      return 'Chick ${measurement.chickId} not yet synced to server';
    }
    return null;
  }

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

  /// Conflicts detected during the last [pull] operation. The sync
  /// orchestrator consumes this so the user can be told about local
  /// pending edits that were silently overwritten by a fresher remote
  /// row.
  final List<({String recordId, String detail})> lastPullConflicts = [];

  @override
  Future<void> pull(String userId, {DateTime? lastSyncedAt}) async {
    lastPullConflicts.clear();
    try {
      final remote = lastSyncedAt != null
          ? await _remoteSource.fetchUpdatedSince(userId, lastSyncedAt)
          : await _remoteSource.fetchAll(userId);

      if (remote.isNotEmpty) {
        // Detect conflicts: a local row with PENDING sync metadata
        // whose remote counterpart has a NEWER updatedAt is about to
        // be overwritten. Surface that as a conflict instead of
        // silently dropping the user's local edits.
        final localItems = await _localDao.getAll(userId);
        final localMap = {for (final item in localItems) item.id: item};
        final pendingIds = await _syncDao.getPendingRecordIds(userId);
        for (final remoteItem in remote) {
          if (!pendingIds.contains(remoteItem.id)) continue;
          final localItem = localMap[remoteItem.id];
          if (localItem == null) continue;
          if (localItem.updatedAt != null &&
              remoteItem.updatedAt != null &&
              remoteItem.updatedAt!.isAfter(localItem.updatedAt!)) {
            lastPullConflicts.add((
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

  // pushAll() is provided by ValidatedSyncMixin — handles pendingDelete
  // tombstones via [deleteRemoteForSync] and runs FK validation on regular
  // pending items via [validateForeignKeys] before batching the upsert.

  @override
  Future<void> upsertChunkForSync(List<GrowthMeasurement> chunk) =>
      _remoteSource.upsertAll(chunk);

  @override
  Future<void> deleteRemoteForSync(String recordId, String userId) =>
      _remoteSource.deleteById(recordId, userId: userId);

  /// Growth measurements for a specific chick (live stream).
  Stream<List<GrowthMeasurement>> watchByChick(String chickId) =>
      _localDao.watchByChick(chickId);

  /// Latest measurement for a chick.
  Future<GrowthMeasurement?> getLatest(String chickId) =>
      _localDao.getLatest(chickId);

  /// Cascade-removes every measurement linked to any of [chickIds] with
  /// batch statements: one local DELETE, one metadata batch, one remote
  /// DELETE. growth_measurements has no isDeleted column so soft-delete
  /// isn't an option (see class docs).
  Future<int> removeByChickIds(List<String> chickIds) async {
    if (chickIds.isEmpty) return 0;
    final measurements = await _localDao.getByChickIds(chickIds);
    if (measurements.isEmpty) return 0;
    final ids = measurements.map((m) => m.id).toList();
    final userId = measurements.first.userId;

    await _localDao.hardDeleteByIds(ids);
    await _syncDao.insertAll([
      for (final m in measurements)
        SyncMetadata(
          id: _uuid.v7(),
          table: _table,
          userId: m.userId,
          status: SyncStatus.pendingDelete,
          recordId: m.id,
        ),
    ]);
    // Best-effort immediate remote cleanup — one request for all rows.
    try {
      await _remoteSource.deleteByIds(ids, userId: userId);
      await _syncDao.deleteByRecords(_table, ids);
    } catch (e) {
      AppLogger.debug(
        '[GrowthMeasurementRepo] Batch remote delete failed, will retry on next sync: $e',
      );
    }
    return ids.length;
  }
}
