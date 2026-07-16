import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/birds_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/bird_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:uuid/uuid.dart';

/// Repository for [Bird] entities with offline-first sync support.
///
/// Includes pilot conflict detection during [pull]: records overwritten
/// by server data are stored in [lastPullConflicts] for the
/// [SyncOrchestrator] to report.
class BirdRepository extends BaseRepository<Bird>
    with SyncableRepository<Bird> {
  final BirdsDao _localDao;
  final BirdRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;
  final PullConflictSink? _conflictSink;

  static const _uuid = Uuid();

  BirdRepository({
    required BirdsDao localDao,
    required BirdRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
    PullConflictSink? conflictSink,
  }) : _localDao = localDao,
       _remoteSource = remoteSource,
       _syncDao = syncDao,
       _conflictSink = conflictSink;

  static const _table = SupabaseConstants.birdsTable;

  /// Conflicts detected during the last [pull] operation.
  /// Each entry has the overwritten record's id and the bird name for display.
  /// Cleared at the start of every pull.
  final List<PullConflict> lastPullConflicts = [];

  // ── SyncableRepository overrides ─────────────────────────────────────
  @override
  SyncMetadataDao get syncDao => _syncDao;

  @override
  String get syncTableName => _table;

  @override
  Stream<List<Bird>> watchAll(String userId) => _localDao.watchAll(userId);

  /// SQL-filtered stream of alive birds matching the given gender and
  /// optional species. Power-user friendly path for parent-selector
  /// dropdowns — avoids loading every bird into memory just to discard
  /// most rows in Dart.
  Stream<List<Bird>> watchAliveByGenderAndSpecies({
    required String userId,
    required BirdGender gender,
    Species? species,
    String? excludeId,
  }) => _localDao.watchAliveByGenderAndSpecies(
    userId: userId,
    gender: gender,
    species: species,
    excludeId: excludeId,
  );

  @override
  Stream<Bird?> watchById(String id) => _localDao.watchById(id);

  @override
  Future<List<Bird>> getAll(String userId) => _localDao.getAll(userId);

  @override
  Future<Bird?> getById(String id) => _localDao.getById(id);

  @override
  Future<void> save(Bird item) async {
    await _localDao.insertItem(item);
    await markPending(item.id, item.userId);
    await tryImmediatePush(item);
  }

  @override
  Future<void> saveAll(List<Bird> items) async {
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

        // Detect real conflicts: a conflict is when a local record has
        // PENDING sync metadata AND the remote record overwrites it.
        // Normal server updates (no pending local changes) are not conflicts.
        lastPullConflicts.addAll(
          detectPullConflicts(
            remote: remote,
            localMap: localMap,
            pendingIds: pendingIds,
            idOf: (b) => b.id,
            detailOf: (b) => b.name,
            payloadOf: (b) => b.toJson(),
          ),
        );

        await persistPullConflicts(
          sink: _conflictSink,
          userId: userId,
          tableName: _table,
          conflicts: lastPullConflicts,
        );

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
      reportPullFailure('BirdRepository', e, st);
    }
  }

  @override
  Future<void> push(Bird item) async {
    try {
      await _remoteSource.upsert(item);
      await _syncDao.deleteByRecord(_table, item.id);
    } on AppException catch (e) {
      await markError(item.id, item.userId, e.message);
    }
  }

  @override
  Future<PushStats> pushAll(String userId) async {
    var orphansCleaned = 0;
    final pushed = await pushPendingBatched(
      userId: userId,
      resolveItem: (id) async {
        final item = await _localDao.getByIdIncludingDeleted(id);
        if (item == null) {
          AppLogger.warning('[BirdRepo] Orphan sync_metadata cleaned: $id');
          await _syncDao.deleteByRecord(_table, id);
          orphansCleaned++;
        }
        return item;
      },
      upsertChunk: _remoteSource.upsertAll,
      deleteRemote: (id) => _remoteSource.deleteById(id, userId: userId),
      idOf: (bird) => bird.id,
    );
    return (pushed: pushed, orphansCleaned: orphansCleaned);
  }

  /// Birds filtered by gender.
  Future<List<Bird>> getByGender(String userId, BirdGender gender) =>
      _localDao.getByGender(userId, gender);

  /// Lightweight count of non-deleted birds (no row mapping).
  Future<int> getCount(String userId) => _localDao.getCount(userId);

  /// Soft-deleted birds.
  Future<List<Bird>> getDeleted(String userId) => _localDao.getDeleted(userId);

  /// Checks if [ringNumber] is already in use by another bird.
  ///
  /// Pass [excludeId] to skip the bird being edited.
  Future<bool> hasRingNumber(
    String userId,
    String ringNumber, {
    String? excludeId,
  }) => _localDao.hasRingNumber(userId, ringNumber, excludeId: excludeId);
}
