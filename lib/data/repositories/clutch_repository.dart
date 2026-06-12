import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/birds_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/clutches_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/incubations_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/nests_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/clutch_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:uuid/uuid.dart';

/// Repository for [Clutch] entities with offline-first sync support.
///
/// Uses [ValidatedSyncMixin] to validate FK references (incubation, male
/// bird, female bird, nest) before pushing to Supabase. Without this,
/// orphan child pushes would 23503 on the server, get marked as sync
/// errors, and accumulate forever without monitoring visibility.
class ClutchRepository extends BaseRepository<Clutch>
    with SyncableRepository<Clutch>, ValidatedSyncMixin<Clutch> {
  final ClutchesDao _localDao;
  final ClutchRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;
  final IncubationsDao _incubationsDao;
  final BirdsDao _birdsDao;
  final NestsDao _nestsDao;

  static const _uuid = Uuid();

  ClutchRepository({
    required ClutchesDao localDao,
    required ClutchRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
    required IncubationsDao incubationsDao,
    required BirdsDao birdsDao,
    required NestsDao nestsDao,
  }) : _localDao = localDao,
       _remoteSource = remoteSource,
       _syncDao = syncDao,
       _incubationsDao = incubationsDao,
       _birdsDao = birdsDao,
       _nestsDao = nestsDao;

  static const _table = SupabaseConstants.clutchesTable;

  /// Conflicts detected during the last [pull] operation.
  final List<({String recordId, String detail})> lastPullConflicts = [];

  // ── SyncableRepository / ValidatedSyncMixin overrides ────────────────
  @override
  SyncMetadataDao get syncDao => _syncDao;

  @override
  String get syncTableName => _table;

  @override
  String get syncLogTag => 'ClutchRepository';

  @override
  Future<Clutch?> getLocalById(String id) => _localDao.getById(id);

  @override
  Future<Clutch?> getLocalByIdForSync(String id) =>
      _localDao.getByIdIncludingDeleted(id);

  @override
  bool shouldValidateForeignKeys(Clutch item) => !item.isDeleted;

  @override
  String getEntityId(Clutch item) => item.id;

  @override
  String getEntityUserId(Clutch item) => item.userId;

  @override
  Future<String?> validateForeignKeys(Clutch clutch) async {
    if (clutch.incubationId != null) {
      // Incubation hard-deletes — no isDeleted check needed.
      final incubation = await _incubationsDao.getById(clutch.incubationId!);
      if (incubation == null) {
        return 'Referenced incubation ${clutch.incubationId} not found locally';
      }
      final syncMeta = await _syncDao.getByRecord(
        SupabaseConstants.incubationsTable,
        clutch.incubationId!,
      );
      if (syncMeta != null &&
          (syncMeta.status == SyncStatus.pending ||
              syncMeta.status == SyncStatus.pendingDelete)) {
        return 'Incubation ${clutch.incubationId} not yet synced to server';
      }
    }
    if (clutch.maleBirdId != null) {
      final reason = await _validateBird(clutch.maleBirdId!, role: 'Male');
      if (reason != null) return reason;
    }
    if (clutch.femaleBirdId != null) {
      final reason = await _validateBird(clutch.femaleBirdId!, role: 'Female');
      if (reason != null) return reason;
    }
    if (clutch.nestId != null) {
      final nest = await _nestsDao.getByIdIncludingDeleted(clutch.nestId!);
      if (nest == null) {
        return 'Referenced nest ${clutch.nestId} not found locally';
      }
      if (nest.isDeleted) {
        return 'Referenced nest ${clutch.nestId} pending tombstone sync';
      }
      final syncMeta = await _syncDao.getByRecord(
        SupabaseConstants.nestsTable,
        clutch.nestId!,
      );
      if (syncMeta != null &&
          (syncMeta.status == SyncStatus.pending ||
              syncMeta.status == SyncStatus.pendingDelete)) {
        return 'Nest ${clutch.nestId} not yet synced to server';
      }
    }
    return null;
  }

  Future<String?> _validateBird(String birdId, {required String role}) async {
    final bird = await _birdsDao.getByIdIncludingDeleted(birdId);
    if (bird == null) {
      return 'Referenced $role bird $birdId not found locally';
    }
    if (bird.isDeleted) {
      return '$role bird $birdId pending tombstone sync';
    }
    final syncMeta = await _syncDao.getByRecord(
      SupabaseConstants.birdsTable,
      birdId,
    );
    if (syncMeta != null &&
        (syncMeta.status == SyncStatus.pending ||
            syncMeta.status == SyncStatus.pendingDelete)) {
      return '$role bird $birdId not yet synced to server';
    }
    return null;
  }

  @override
  Stream<List<Clutch>> watchAll(String userId) => _localDao.watchAll(userId);

  @override
  Stream<Clutch?> watchById(String id) => _localDao.watchById(id);

  @override
  Future<List<Clutch>> getAll(String userId) => _localDao.getAll(userId);

  @override
  Future<Clutch?> getById(String id) => _localDao.getById(id);

  @override
  Future<void> save(Clutch item) async {
    await _localDao.insertItem(item);
    await markPending(item.id, item.userId);
    await tryImmediatePush(item);
  }

  @override
  Future<void> saveAll(List<Clutch> items) async {
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
              detail: remoteItem.name ?? remoteItem.id,
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
      AppLogger.error('[ClutchRepository] Pull failed', e, st);
    }
  }

  @override
  Future<void> push(Clutch item) async {
    try {
      await _remoteSource.upsert(item);
      await _syncDao.deleteByRecord(_table, item.id);
    } on AppException catch (e) {
      await markError(item.id, item.userId, e.message);
    }
  }

  Future<List<Clutch>> getByBreeding(String breedingId) =>
      _localDao.getByBreeding(breedingId);
}
