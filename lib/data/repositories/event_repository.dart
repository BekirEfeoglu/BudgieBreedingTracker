import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/events_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/event_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;
import 'package:uuid/uuid.dart';

/// Repository for [Event] entities with offline-first sync support.
class EventRepository extends BaseRepository<Event>
    with SyncableRepository<Event> {
  final EventsDao _localDao;
  final EventRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;

  static const _uuid = Uuid();

  EventRepository({
    required EventsDao localDao,
    required EventRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
  }) : _localDao = localDao,
       _remoteSource = remoteSource,
       _syncDao = syncDao;

  static const _table = SupabaseConstants.eventsTable;

  /// Conflicts detected during the last [pull] operation.
  final List<({String recordId, String detail})> lastPullConflicts = [];

  // ── SyncableRepository overrides ─────────────────────────────────────
  @override
  SyncMetadataDao get syncDao => _syncDao;

  @override
  String get syncTableName => _table;

  @override
  Stream<List<Event>> watchAll(String userId) => _localDao.watchAll(userId);

  @override
  Stream<Event?> watchById(String id) => _localDao.watchById(id);

  @override
  Future<List<Event>> getAll(String userId) => _localDao.getAll(userId);

  @override
  Future<Event?> getById(String id) => _localDao.getById(id);

  @override
  Future<void> save(Event item) async {
    await _localDao.insertItem(item);
    await markPending(item.id, item.userId);
    await tryImmediatePush(item);
  }

  @override
  Future<void> saveAll(List<Event> items) async {
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
      AppLogger.error('[EventRepository] Pull failed', e, st);
    }
  }

  @override
  Future<void> push(Event item) async {
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
      final item = await _localDao.getById(meta.recordId ?? '');
      if (item == null) {
        AppLogger.warning(
          '[EventRepo] Orphan sync_metadata cleaned: ${meta.recordId}',
        );
        await _syncDao.deleteByRecord(_table, meta.recordId ?? '');
        orphansCleaned++;
        continue;
      }
      await push(item);
      pushed++;
    }
    return (pushed: pushed, orphansCleaned: orphansCleaned);
  }

  // ── Realtime helpers ─────────────────────────────────────────────────
  // These bypass sync metadata so events received from Supabase realtime
  // are persisted locally without being re-pushed back to the server.

  /// Inserts/updates an event received from a realtime callback into the
  /// local DB only — no sync metadata is created because the record
  /// already lives on the server.
  Future<void> saveFromRemote(Event item) => _localDao.insertItem(item);

  /// Soft-deletes a record received via a realtime delete callback.
  /// Falls back to hard-delete when the record doesn't exist locally.
  Future<void> removeFromRemote(String id) async {
    final exists = await _localDao.getById(id);
    if (exists != null) {
      await _localDao.softDelete(id);
    }
  }

  /// Subscribes to realtime events for a user and routes changes through
  /// the local Drift DB. The existing [watchAll] stream automatically
  /// emits updated data when the DAO is modified.
  ///
  /// Returns the [RealtimeChannel] for cleanup via [_remoteSource.unsubscribe].
  RealtimeChannel subscribeToEvents(String userId) {
    return _remoteSource.subscribeToEvents(
      userId,
      (event) async {
        try {
          await saveFromRemote(event);
        } catch (e, st) {
          // Graceful degradation: log but don't crash — the event was
          // already received from the server, so the user won't lose data
          // permanently; it will arrive on the next full sync.
          AppLogger.error('[EventRepository] Realtime upsert failed', e, st);
        }
      },
      (deletedId) async {
        try {
          await removeFromRemote(deletedId);
        } catch (e, st) {
          AppLogger.error('[EventRepository] Realtime delete failed', e, st);
        }
      },
    );
  }

  /// Removes a realtime channel subscription.
  Future<void> unsubscribeFromEvents(RealtimeChannel channel) =>
      _remoteSource.unsubscribe(channel);

  /// Events in a date range (live stream).
  Stream<List<Event>> watchByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) => _localDao.watchByDateRange(userId, start, end);

  /// Upcoming events.
  Future<List<Event>> getUpcoming(String userId, {int limit = 10}) =>
      _localDao.getUpcoming(userId, limit: limit);

  /// Events for a specific bird (live stream).
  Stream<List<Event>> watchByBird(String birdId) =>
      _localDao.watchByBird(birdId);

  /// Active events for a specific chick filtered by event type (DB-level).
  Future<List<Event>> getActiveByChickAndType(
    String chickId,
    EventType type,
  ) => _localDao.getActiveByChickAndType(chickId, type);
}
