import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/clutches_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/eggs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/incubations_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/egg_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:uuid/uuid.dart';

/// Repository for [Egg] entities with offline-first sync support.
///
/// Uses [ValidatedSyncMixin] to validate FK references (incubation, clutch)
/// before pushing to Supabase, preventing FK constraint violations.
class EggRepository extends BaseRepository<Egg>
    with SyncableRepository<Egg>, ValidatedSyncMixin<Egg> {
  final EggsDao _localDao;
  final EggRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;
  final IncubationsDao _incubationsDao;
  final ClutchesDao _clutchesDao;

  static const _uuid = Uuid();

  EggRepository({
    required EggsDao localDao,
    required EggRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
    required IncubationsDao incubationsDao,
    required ClutchesDao clutchesDao,
  }) : _localDao = localDao,
       _remoteSource = remoteSource,
       _syncDao = syncDao,
       _incubationsDao = incubationsDao,
       _clutchesDao = clutchesDao;

  static const _table = SupabaseConstants.eggsTable;

  /// Conflicts detected during the last [pull] operation.
  final List<({String recordId, String detail})> lastPullConflicts = [];

  // ── ValidatedSyncMixin overrides ──────────────────────────────────────

  @override
  SyncMetadataDao get syncDao => _syncDao;

  @override
  String get syncTableName => _table;

  @override
  String get syncLogTag => 'EggRepository';

  @override
  Future<Egg?> getLocalById(String id) => _localDao.getById(id);

  @override
  String getEntityId(Egg item) => item.id;

  @override
  String getEntityUserId(Egg item) => item.userId;

  @override
  Future<String?> validateForeignKeys(Egg egg) async {
    if (egg.incubationId != null) {
      final incubation = await _incubationsDao.getById(egg.incubationId!);
      if (incubation == null) {
        return 'Referenced incubation ${egg.incubationId} not found locally';
      }
      // Check if incubation has pending/error sync metadata (not yet on server)
      final syncMeta = await _syncDao.getByRecord(
        SupabaseConstants.incubationsTable,
        egg.incubationId!,
      );
      if (syncMeta != null) {
        return 'Incubation ${egg.incubationId} not yet synced to server';
      }
    }
    if (egg.clutchId != null) {
      final clutch = await _clutchesDao.getById(egg.clutchId!);
      if (clutch == null) {
        return 'Referenced clutch ${egg.clutchId} not found locally';
      }
      final syncMeta = await _syncDao.getByRecord(
        SupabaseConstants.clutchesTable,
        egg.clutchId!,
      );
      if (syncMeta != null) {
        return 'Clutch ${egg.clutchId} not yet synced to server';
      }
    }
    return null;
  }

  // ── BaseRepository overrides ──────────────────────────────────────────

  @override
  Stream<List<Egg>> watchAll(String userId) => _localDao.watchAll(userId);

  @override
  Stream<Egg?> watchById(String id) => _localDao.watchById(id);

  @override
  Future<List<Egg>> getAll(String userId) => _localDao.getAll(userId);

  @override
  Future<Egg?> getById(String id) => _localDao.getById(id);

  @override
  Future<void> save(Egg item) async {
    await _localDao.insertItem(item);
    await markPending(item.id, item.userId);
    await tryImmediatePush(item);
  }

  @override
  Future<void> saveAll(List<Egg> items) async {
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
              detail: remoteItem.eggNumber?.toString() ?? remoteItem.id,
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
      AppLogger.error('[EggRepository] Pull failed', e, st);
    }
  }

  @override
  Future<void> push(Egg item) async {
    try {
      await _remoteSource.upsert(item);
      await _syncDao.deleteByRecord(_table, item.id);
    } on AppException catch (e) {
      await markSyncError(item.id, item.userId, e.message);
    }
  }

  // pushAll() is provided by ValidatedSyncMixin

  // ── Domain-specific queries ───────────────────────────────────────────

  /// Eggs by clutch (live stream).
  Stream<List<Egg>> watchByClutch(String clutchId) =>
      _localDao.watchByClutch(clutchId);

  /// Eggs by incubation (live stream).
  Stream<List<Egg>> watchByIncubation(String incubationId) =>
      _localDao.watchByIncubation(incubationId);

  /// Eggs by incubation (one-shot query).
  Future<List<Egg>> getByIncubation(String incubationId) =>
      _localDao.getByIncubation(incubationId);

  /// Eggs by multiple incubation IDs (batch query).
  Future<List<Egg>> getByIncubationIds(List<String> incubationIds) =>
      _localDao.getByIncubationIds(incubationIds);

  /// Currently incubating eggs.
  Future<List<Egg>> getIncubating(String userId) =>
      _localDao.getIncubating(userId);
}
