import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notifications_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/notification_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:uuid/uuid.dart';

/// Repository for [AppNotification] entities with offline-first sync support.
///
/// Also manages [NotificationSettings] via the same DAO and remote source.
class NotificationRepository extends BaseRepository<AppNotification>
    with SyncableRepository<AppNotification> {
  final NotificationsDao _localDao;
  final NotificationRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;

  static const _uuid = Uuid();

  NotificationRepository({
    required NotificationsDao localDao,
    required NotificationRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
  }) : _localDao = localDao,
       _remoteSource = remoteSource,
       _syncDao = syncDao;

  static const _table = SupabaseConstants.notificationsTable;
  static const _settingsTable = SupabaseConstants.notificationSettingsTable;

  // ── SyncableRepository overrides ─────────────────────────────────────
  @override
  SyncMetadataDao get syncDao => _syncDao;

  @override
  String get syncTableName => _table;

  @override
  Stream<List<AppNotification>> watchAll(String userId) =>
      _localDao.watchAll(userId);

  @override
  Stream<AppNotification?> watchById(String id) => _localDao.watchById(id);

  @override
  Future<List<AppNotification>> getAll(String userId) =>
      _localDao.getAll(userId);

  @override
  Future<AppNotification?> getById(String id) => _localDao.getById(id);

  @override
  Future<void> save(AppNotification item) async {
    await _localDao.insertItem(item);
    await markPending(item.id, item.userId);
    await tryImmediatePush(item);
  }

  @override
  Future<void> saveAll(List<AppNotification> items) async {
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

  /// Notifications use hard-delete (no isDeleted field).
  @override
  Future<void> remove(String id) async {
    final item = await _localDao.getById(id);
    await _localDao.hardDelete(id);
    if (item != null) {
      await _syncDao.insertItem(
        SyncMetadata(
          id: _uuid.v4(),
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
          '[NotificationRepo] Immediate remote delete failed, will retry on next sync: $e',
        );
      }
    }
  }

  @override
  Future<void> hardRemove(String id) => _localDao.hardDelete(id);

  @override
  Future<void> pull(String userId, {DateTime? lastSyncedAt}) async {
    try {
      final remote = lastSyncedAt != null
          ? await _remoteSource.fetchUpdatedSince(userId, lastSyncedAt)
          : await _remoteSource.fetchAll(userId);
      if (remote.isNotEmpty) {
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
      AppLogger.error('[NotificationRepository] Pull failed', e, st);
    }
  }

  @override
  Future<void> push(AppNotification item) async {
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
            '[NotificationRepo] Orphan sync_metadata cleaned: ${meta.recordId}',
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

  /// Unread notifications (live stream).
  Stream<List<AppNotification>> watchUnread(String userId) =>
      _localDao.watchUnread(userId);

  /// Marks a single notification as read locally and syncs.
  Future<void> markAsRead(String id) async {
    await _localDao.markAsRead(id);
    final item = await _localDao.getById(id);
    if (item != null) {
      await markPending(id, item.userId);
      await tryImmediatePush(item);
    }
  }

  /// Marks all notifications as read for a user and syncs.
  Future<void> markAllAsRead(String userId) async {
    await _localDao.markAllAsRead(userId);
    // Batch sync metadata for all read items
    final items = await _localDao.getAll(userId);
    final readItems = items.where((item) => item.read).toList();
    if (readItems.isNotEmpty) {
      final syncEntries = readItems
          .map(
            (item) => SyncMetadata(
              id: _uuid.v4(),
              table: _table,
              userId: userId,
              status: SyncStatus.pending,
              recordId: item.id,
            ),
          )
          .toList();
      await _syncDao.insertAll(syncEntries);
    }
  }

  /// Gets notification settings for a user.
  Future<NotificationSettings?> getSettings(String userId) =>
      _localDao.getSettings(userId);

  /// Upserts notification settings locally and syncs.
  ///
  /// Uses [_settingsTable] for sync metadata instead of [syncTableName]
  /// (which refers to the `notifications` table, not `notification_settings`).
  Future<void> upsertSettings(NotificationSettings settings) async {
    await _localDao.upsertSettings(settings);
    final existing = await _syncDao.getByRecord(_settingsTable, settings.id);
    if (existing == null) {
      await _syncDao.insertItem(
        SyncMetadata(
          id: _uuid.v4(),
          table: _settingsTable,
          userId: settings.userId,
          status: SyncStatus.pending,
          recordId: settings.id,
        ),
      );
    } else if (existing.status != SyncStatus.pending) {
      await _syncDao.updateStatus(existing.id, SyncStatus.pending);
    }
  }

  /// Pushes pending notification settings to Supabase.
  ///
  /// Reads sync metadata for [_settingsTable], then upserts the local
  /// settings to the remote and clears the sync entry on success.
  Future<void> pushSettings(String userId) async {
    final pendingEntries = await _syncDao.getPendingByTable(
      userId,
      _settingsTable,
    );
    for (final meta in pendingEntries) {
      final settings = await _localDao.getSettings(userId);
      if (settings == null) {
        await _syncDao.deleteByRecord(_settingsTable, meta.recordId ?? '');
        continue;
      }
      try {
        await _remoteSource.upsertSettings(settings);
        await _syncDao.deleteByRecord(_settingsTable, settings.id);
      } catch (e, st) {
        AppLogger.error('[NotificationRepository] Push settings failed', e, st);
        await _syncDao.updateStatus(meta.id, SyncStatus.error);
      }
    }
  }

  /// Pulls notification settings from remote.
  Future<void> pullSettings(String userId) async {
    try {
      final remote = await _remoteSource.fetchSettings(userId);
      if (remote != null) {
        await _localDao.upsertSettings(remote);
      }
    } catch (e, st) {
      AppLogger.error('[NotificationRepository] Pull settings failed', e, st);
    }
  }
}
