import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/birds_dao.dart';
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
/// Uses [ValidatedSyncMixin] to validate FK references (egg, clutch, bird)
/// before pushing to Supabase, preventing FK constraint violations. Without
/// the bird check, chicks linked to an as-yet-unsynced bird would push,
/// the server would reject with a 23503, and the chick would be stuck in
/// error state until manually edited.
class ChickRepository extends BaseRepository<Chick>
    with SyncableRepository<Chick>, ValidatedSyncMixin<Chick> {
  final ChicksDao _localDao;
  final ChickRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;
  final EggsDao _eggsDao;
  final ClutchesDao _clutchesDao;
  final BirdsDao _birdsDao;

  static const _uuid = Uuid();

  ChickRepository({
    required ChicksDao localDao,
    required ChickRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
    required EggsDao eggsDao,
    required ClutchesDao clutchesDao,
    required BirdsDao birdsDao,
  }) : _localDao = localDao,
       _remoteSource = remoteSource,
       _syncDao = syncDao,
       _eggsDao = eggsDao,
       _clutchesDao = clutchesDao,
       _birdsDao = birdsDao;

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
  Future<Chick?> getLocalByIdForSync(String id) =>
      _localDao.getByIdIncludingDeleted(id);

  @override
  bool shouldValidateForeignKeys(Chick item) => !item.isDeleted;

  @override
  String getEntityId(Chick item) => item.id;

  @override
  String getEntityUserId(Chick item) => item.userId;

  @override
  Future<String?> validateForeignKeys(Chick chick) async {
    if (chick.eggId != null) {
      final reason = await _validateParent(
        recordId: chick.eggId!,
        parentLookup: () => _eggsDao.getByIdIncludingDeleted(chick.eggId!),
        isDeleted: (egg) => egg.isDeleted,
        label: 'egg',
        syncTable: SupabaseConstants.eggsTable,
      );
      if (reason != null) return reason;
    }
    if (chick.clutchId != null) {
      final reason = await _validateParent(
        recordId: chick.clutchId!,
        parentLookup: () =>
            _clutchesDao.getByIdIncludingDeleted(chick.clutchId!),
        isDeleted: (clutch) => clutch.isDeleted,
        label: 'clutch',
        syncTable: SupabaseConstants.clutchesTable,
      );
      if (reason != null) return reason;
    }
    if (chick.birdId != null) {
      final reason = await _validateParent(
        recordId: chick.birdId!,
        parentLookup: () => _birdsDao.getByIdIncludingDeleted(chick.birdId!),
        isDeleted: (bird) => bird.isDeleted,
        label: 'bird',
        syncTable: SupabaseConstants.birdsTable,
      );
      if (reason != null) return reason;
    }
    return null;
  }

  /// Generic FK validator that distinguishes:
  /// - parent missing entirely → "not found locally" (orphan cleanup path)
  /// - parent soft-deleted locally → "pending tombstone sync" (NOT cleanup;
  ///   child should wait for the parent tombstone to push and only then
  ///   try again, which is what the mixin's continue-loop already does)
  /// - parent has pending/pendingDelete sync metadata → "not yet synced"
  ///   (waiting on parent push)
  ///
  /// Crucially, parent sync metadata in `error`/`success` state is NOT
  /// considered blocking — `error` will be stale-cleared by maxSyncRetries
  /// and at that point child sync should be allowed to attempt again
  /// rather than deadlocking on the parent's retry budget.
  Future<String?> _validateParent<P>({
    required String recordId,
    required Future<P?> Function() parentLookup,
    required bool Function(P) isDeleted,
    required String label,
    required String syncTable,
  }) async {
    final parent = await parentLookup();
    if (parent == null) {
      return 'Referenced $label $recordId not found locally';
    }
    if (isDeleted(parent)) {
      return 'Referenced $label $recordId pending tombstone sync';
    }
    final syncMeta = await _syncDao.getByRecord(syncTable, recordId);
    if (syncMeta != null &&
        (syncMeta.status == SyncStatus.pending ||
            syncMeta.status == SyncStatus.pendingDelete)) {
      return '$label $recordId not yet synced to server';
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
