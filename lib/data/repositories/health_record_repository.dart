import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/birds_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/health_records_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/health_record_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:uuid/uuid.dart';

/// Repository for [HealthRecord] entities with offline-first sync support.
///
/// Uses [ValidatedSyncMixin] to validate the optional `birdId` FK before
/// pushing to Supabase. This matches the discipline applied to sibling
/// repositories (chick, egg, event_reminder) and prevents FK constraint
/// violations when a parent bird is deleted locally between record creation
/// and the next sync cycle.
class HealthRecordRepository extends BaseRepository<HealthRecord>
    with SyncableRepository<HealthRecord>, ValidatedSyncMixin<HealthRecord> {
  final HealthRecordsDao _localDao;
  final HealthRecordRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;
  final BirdsDao _birdsDao;

  static const _uuid = Uuid();

  HealthRecordRepository({
    required HealthRecordsDao localDao,
    required HealthRecordRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
    required BirdsDao birdsDao,
  }) : _localDao = localDao,
       _remoteSource = remoteSource,
       _syncDao = syncDao,
       _birdsDao = birdsDao;

  static const _table = SupabaseConstants.healthRecordsTable;

  /// Conflicts detected during the last [pull] operation.
  final List<({String recordId, String detail})> lastPullConflicts = [];

  // ── ValidatedSyncMixin overrides ─────────────────────────────────────
  @override
  SyncMetadataDao get syncDao => _syncDao;

  @override
  String get syncTableName => _table;

  @override
  String get syncLogTag => 'HealthRecordRepository';

  @override
  Future<HealthRecord?> getLocalById(String id) => _localDao.getById(id);

  @override
  String getEntityId(HealthRecord item) => item.id;

  @override
  String getEntityUserId(HealthRecord item) => item.userId;

  @override
  Future<String?> validateForeignKeys(HealthRecord record) async {
    // birdId is optional (column is nullable, ON DELETE SET NULL). When
    // it's set we verify the parent bird exists, is not soft-deleted, and
    // is already synced to the server — otherwise the insert would FK-fail.
    if (record.birdId != null) {
      final bird = await _birdsDao.getById(record.birdId!);
      if (bird == null) {
        return 'Referenced bird ${record.birdId} not found locally';
      }
      if (bird.isDeleted) {
        return 'Referenced bird ${record.birdId} is deleted';
      }
      final syncMeta = await _syncDao.getByRecord(
        SupabaseConstants.birdsTable,
        record.birdId!,
      );
      if (syncMeta != null) {
        return 'Bird ${record.birdId} not yet synced to server';
      }
    }
    return null;
  }

  // ── BaseRepository overrides ─────────────────────────────────────────
  @override
  Stream<List<HealthRecord>> watchAll(String userId) =>
      _localDao.watchAll(userId);

  @override
  Stream<HealthRecord?> watchById(String id) => _localDao.watchById(id);

  @override
  Future<List<HealthRecord>> getAll(String userId) => _localDao.getAll(userId);

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

  // pushAll() is provided by ValidatedSyncMixin — validates birdId FK
  // before pushing and cleans up orphaned sync metadata.

  /// Health records for a specific bird (live stream).
  Stream<List<HealthRecord>> watchByBird(String birdId) =>
      _localDao.watchByBird(birdId);

  /// Latest health records for a bird.
  Future<List<HealthRecord>> getLatest(String birdId, {int limit = 5}) =>
      _localDao.getLatest(birdId, limit: limit);
}
