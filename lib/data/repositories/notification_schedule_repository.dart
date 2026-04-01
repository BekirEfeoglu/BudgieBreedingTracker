import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notification_schedules_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/notification_schedule_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/notification_schedule_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:uuid/uuid.dart';

/// Repository for [NotificationSchedule] entities with offline-first sync support.
class NotificationScheduleRepository
    extends BaseRepository<NotificationSchedule>
    with SyncableRepository<NotificationSchedule> {
  final NotificationSchedulesDao _localDao;
  final NotificationScheduleRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;

  static const _uuid = Uuid();

  NotificationScheduleRepository({
    required NotificationSchedulesDao localDao,
    required NotificationScheduleRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
  }) : _localDao = localDao,
       _remoteSource = remoteSource,
       _syncDao = syncDao;

  static const _table = SupabaseConstants.notificationSchedulesTable;

  /// Conflicts detected during the last [pull] operation.
  final List<({String recordId, String detail})> lastPullConflicts = [];

  // ── SyncableRepository overrides ─────────────────────────────────────
  @override
  SyncMetadataDao get syncDao => _syncDao;

  @override
  String get syncTableName => _table;

  @override
  Stream<List<NotificationSchedule>> watchAll(String userId) =>
      _localDao.watchAll(userId);

  @override
  Stream<NotificationSchedule?> watchById(String id) => _localDao.watchById(id);

  @override
  Future<List<NotificationSchedule>> getAll(String userId) =>
      _localDao.getAll(userId);

  @override
  Future<NotificationSchedule?> getById(String id) => _localDao.getById(id);

  @override
  Future<void> save(NotificationSchedule item) async {
    await _localDao.insertItem(item);
    await markPending(item.id, item.userId);
    await tryImmediatePush(item);
  }

  @override
  Future<void> saveAll(List<NotificationSchedule> items) async {
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
      try {
        await _remoteSource.deleteById(id, userId: item.userId);
        await _syncDao.deleteByRecord(_table, id);
      } catch (e) {
        AppLogger.debug(
          '[NotificationScheduleRepo] Immediate remote delete failed, will retry on next sync: $e',
        );
      }
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
              detail: remoteItem.title,
            ));
          }
        }

        // Resolve conflicts: server-wins — remote data overwrites via insertAll
        if (lastPullConflicts.isNotEmpty) {
          AppLogger.warning(
            '[NotificationScheduleRepo] ${lastPullConflicts.length} conflicts '
            'detected — resolved with server-wins strategy',
          );
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
      AppLogger.error('[NotificationScheduleRepository] Pull failed', e, st);
    }
  }

  @override
  Future<void> push(NotificationSchedule item) async {
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
            '[NotificationScheduleRepo] Orphan sync_metadata cleaned: ${meta.recordId}',
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
}
