import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/birds_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/breeding_pairs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/breeding_pair_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:uuid/uuid.dart';

/// Repository for [BreedingPair] entities with offline-first sync support.
///
/// Uses [ValidatedSyncMixin] to validate FK references (male bird, female bird)
/// before pushing to Supabase, preventing FK constraint violations when a
/// parent bird is deleted before its pair is synced.
class BreedingPairRepository extends BaseRepository<BreedingPair>
    with SyncableRepository<BreedingPair>, ValidatedSyncMixin<BreedingPair> {
  final BreedingPairsDao _localDao;
  final BreedingPairRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;
  final BirdsDao _birdsDao;

  static const _uuid = Uuid();

  BreedingPairRepository({
    required BreedingPairsDao localDao,
    required BreedingPairRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
    required BirdsDao birdsDao,
  }) : _localDao = localDao,
       _remoteSource = remoteSource,
       _syncDao = syncDao,
       _birdsDao = birdsDao;

  static const _table = SupabaseConstants.breedingPairsTable;

  /// Conflicts detected during the last [pull] operation.
  final List<({String recordId, String detail})> lastPullConflicts = [];

  // ── ValidatedSyncMixin overrides ─────────────────────────────────────
  @override
  SyncMetadataDao get syncDao => _syncDao;

  @override
  String get syncTableName => _table;

  @override
  String get syncLogTag => 'BreedingPairRepository';

  @override
  Future<BreedingPair?> getLocalById(String id) => _localDao.getById(id);

  @override
  String getEntityId(BreedingPair item) => item.id;

  @override
  String getEntityUserId(BreedingPair item) => item.userId;

  @override
  Future<String?> validateForeignKeys(BreedingPair pair) async {
    final maleId = pair.maleId;
    if (maleId != null) {
      final male = await _birdsDao.getById(maleId);
      if (male == null) {
        return 'Referenced male bird $maleId not found locally';
      }
      final syncMeta = await _syncDao.getByRecord(
        SupabaseConstants.birdsTable,
        maleId,
      );
      if (syncMeta != null) {
        return 'Male bird $maleId not yet synced to server';
      }
    }
    final femaleId = pair.femaleId;
    if (femaleId != null) {
      final female = await _birdsDao.getById(femaleId);
      if (female == null) {
        return 'Referenced female bird $femaleId not found locally';
      }
      final syncMeta = await _syncDao.getByRecord(
        SupabaseConstants.birdsTable,
        femaleId,
      );
      if (syncMeta != null) {
        return 'Female bird $femaleId not yet synced to server';
      }
    }
    return null;
  }

  @override
  Stream<List<BreedingPair>> watchAll(String userId) =>
      _localDao.watchAll(userId);

  @override
  Stream<BreedingPair?> watchById(String id) => _localDao.watchById(id);

  @override
  Future<List<BreedingPair>> getAll(String userId) => _localDao.getAll(userId);

  /// Returns the count of active + ongoing breeding pairs (SQL COUNT).
  Future<int> getActiveCount(String userId) =>
      _localDao.getActiveCount(userId);

  @override
  Future<BreedingPair?> getById(String id) => _localDao.getById(id);

  @override
  Future<void> save(BreedingPair item) async {
    await _localDao.insertItem(item);
    await markPending(item.id, item.userId);
    await tryImmediatePush(item);
  }

  @override
  Future<void> saveAll(List<BreedingPair> items) async {
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
        for (final remoteItem in remote) {
          if (!pendingIds.contains(remoteItem.id)) continue;
          final localItem = localMap[remoteItem.id];
          if (localItem == null) continue;
          if (localItem.updatedAt != null &&
              remoteItem.updatedAt != null &&
              remoteItem.updatedAt!.isAfter(localItem.updatedAt!)) {
            lastPullConflicts.add((
              recordId: remoteItem.id,
              detail: remoteItem.cageNumber ?? remoteItem.id,
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
      AppLogger.error('[BreedingPairRepository] Pull failed', e, st);
    }
  }

  @override
  Future<void> push(BreedingPair item) async {
    try {
      await _remoteSource.upsert(item);
      await _syncDao.deleteByRecord(_table, item.id);
    } on AppException catch (e) {
      await markSyncError(item.id, item.userId, e.message);
    }
  }

  // pushAll() is provided by ValidatedSyncMixin

  /// Active breeding pairs (live stream).
  Stream<List<BreedingPair>> watchActive(String userId) =>
      _localDao.watchActive(userId);

  /// Breeding pairs containing a specific bird.
  Future<List<BreedingPair>> getByBirdId(String birdId) =>
      _localDao.getByBirdId(birdId);
}
