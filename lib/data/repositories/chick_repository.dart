import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/chicks_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/clutches_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/eggs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/chick_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:uuid/uuid.dart';

/// Repository for [Chick] entities with offline-first sync support.
///
/// Uses [ValidatedSyncMixin] to validate FK references (egg, clutch)
/// before pushing to Supabase, preventing FK constraint violations.
class ChickRepository extends BaseRepository<Chick>
    with SyncableRepository<Chick>, ValidatedSyncMixin<Chick> {
  final ChicksDao _localDao;
  final ChickRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;
  final EggsDao _eggsDao;
  final ClutchesDao _clutchesDao;

  static const _uuid = Uuid();

  ChickRepository({
    required ChicksDao localDao,
    required ChickRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
    required EggsDao eggsDao,
    required ClutchesDao clutchesDao,
  }) : _localDao = localDao,
       _remoteSource = remoteSource,
       _syncDao = syncDao,
       _eggsDao = eggsDao,
       _clutchesDao = clutchesDao;

  static const _table = SupabaseConstants.chicksTable;

  /// Conflicts detected during the last [pull] operation.
  final List<({String recordId, String detail})> lastPullConflicts = [];

  // ── ValidatedSyncMixin overrides ──────────────────────────────────────

  @override
  SyncMetadataDao get syncDao => _syncDao;

  @override
  String get syncTableName => _table;

  @override
  String get syncLogTag => 'ChickRepository';

  @override
  Future<Chick?> getLocalById(String id) => _localDao.getById(id);

  @override
  String getEntityId(Chick item) => item.id;

  @override
  String getEntityUserId(Chick item) => item.userId;

  @override
  Future<String?> validateForeignKeys(Chick chick) async {
    if (chick.eggId != null) {
      final egg = await _eggsDao.getById(chick.eggId!);
      if (egg == null) {
        return 'Referenced egg ${chick.eggId} not found locally';
      }
      // Check if egg has pending/error sync metadata (not yet on server)
      final syncMeta = await _syncDao.getByRecord(
        SupabaseConstants.eggsTable,
        chick.eggId!,
      );
      if (syncMeta != null) {
        return 'Egg ${chick.eggId} not yet synced to server';
      }
    }
    if (chick.clutchId != null) {
      final clutch = await _clutchesDao.getById(chick.clutchId!);
      if (clutch == null) {
        return 'Referenced clutch ${chick.clutchId} not found locally';
      }
      final syncMeta = await _syncDao.getByRecord(
        SupabaseConstants.clutchesTable,
        chick.clutchId!,
      );
      if (syncMeta != null) {
        return 'Clutch ${chick.clutchId} not yet synced to server';
      }
    }
    return null;
  }

  // ── BaseRepository overrides ──────────────────────────────────────────

  @override
  Stream<List<Chick>> watchAll(String userId) => _localDao.watchAll(userId);

  @override
  Stream<Chick?> watchById(String id) => _localDao.watchById(id);

  @override
  Future<List<Chick>> getAll(String userId) => _localDao.getAll(userId);

  @override
  Future<Chick?> getById(String id) => _localDao.getById(id);

  @override
  Future<void> save(Chick item) async {
    await _localDao.insertItem(item);
    await markPending(item.id, item.userId);
    await tryImmediatePush(item);
  }

  @override
  Future<void> saveAll(List<Chick> items) async {
    await _localDao.insertAll(items);
    if (items.isNotEmpty) {
      final syncEntries = items
          .map(
            (item) => SyncMetadata(
              id: _uuid.v4(),
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

  // ── SyncableRepository overrides ──────────────────────────────────────

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
              detail: remoteItem.name ?? remoteItem.ringNumber ?? remoteItem.id,
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
      AppLogger.error('[ChickRepository] Pull failed', e, st);
    }
  }

  @override
  Future<void> push(Chick item) async {
    try {
      await _remoteSource.upsert(item);
      await _syncDao.deleteByRecord(_table, item.id);
    } on AppException catch (e) {
      await markSyncError(item.id, item.userId, e.message);
    }
  }

  // pushAll() is provided by ValidatedSyncMixin

  // ── Domain-specific queries ───────────────────────────────────────────

  /// Chicks by clutch (live stream).
  Stream<List<Chick>> watchByClutch(String clutchId) =>
      _localDao.watchByClutch(clutchId);

  /// Find chick by egg ID (for duplicate check).
  Future<Chick?> getByEggId(String eggId) => _localDao.getByEggId(eggId);

  /// Chicks by multiple egg IDs (batch query).
  Future<List<Chick>> getByEggIds(List<String> eggIds) =>
      _localDao.getByEggIds(eggIds);

  /// Unweaned chicks.
  Future<List<Chick>> getUnweaned(String userId) =>
      _localDao.getUnweaned(userId);
}
