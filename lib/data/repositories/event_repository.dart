import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/birds_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/breeding_pairs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/chicks_dao.dart';
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
///
/// Uses [ValidatedSyncMixin] to validate FK references (bird, breeding
/// pair, chick) before pushing to Supabase. Without this, orphan child
/// pushes would 23503 on the server and accumulate as sync errors with
/// no monitoring visibility.
class EventRepository extends BaseRepository<Event>
    with SyncableRepository<Event>, ValidatedSyncMixin<Event> {
  final EventsDao _localDao;
  final EventRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;
  final BirdsDao _birdsDao;
  final BreedingPairsDao _breedingPairsDao;
  final ChicksDao _chicksDao;

  static const _uuid = Uuid();

  EventRepository({
    required EventsDao localDao,
    required EventRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
    required BirdsDao birdsDao,
    required BreedingPairsDao breedingPairsDao,
    required ChicksDao chicksDao,
  }) : _localDao = localDao,
       _remoteSource = remoteSource,
       _syncDao = syncDao,
       _birdsDao = birdsDao,
       _breedingPairsDao = breedingPairsDao,
       _chicksDao = chicksDao;

  static const _table = SupabaseConstants.eventsTable;

  /// Conflicts detected during the last [pull] operation.
  final List<({String recordId, String detail})> lastPullConflicts = [];

  // ── SyncableRepository / ValidatedSyncMixin overrides ────────────────
  @override
  SyncMetadataDao get syncDao => _syncDao;

  @override
  String get syncTableName => _table;

  @override
  String get syncLogTag => 'EventRepository';

  @override
  Future<Event?> getLocalById(String id) => _localDao.getById(id);

  @override
  Future<Event?> getLocalByIdForSync(String id) =>
      _localDao.getByIdIncludingDeleted(id);

  @override
  bool shouldValidateForeignKeys(Event item) => !item.isDeleted;

  @override
  String getEntityId(Event item) => item.id;

  @override
  String getEntityUserId(Event item) => item.userId;

  @override
  Future<String?> validateForeignKeys(Event event) async {
    if (event.birdId != null) {
      final reason = await _validateParent(
        recordId: event.birdId!,
        parentLookup: () => _birdsDao.getByIdIncludingDeleted(event.birdId!),
        isDeleted: (bird) => bird.isDeleted,
        label: 'bird',
        syncTable: SupabaseConstants.birdsTable,
      );
      if (reason != null) return reason;
    }
    if (event.breedingPairId != null) {
      final reason = await _validateParent(
        recordId: event.breedingPairId!,
        parentLookup: () =>
            _breedingPairsDao.getByIdIncludingDeleted(event.breedingPairId!),
        isDeleted: (pair) => pair.isDeleted,
        label: 'breeding pair',
        syncTable: SupabaseConstants.breedingPairsTable,
      );
      if (reason != null) return reason;
    }
    if (event.chickId != null) {
      final reason = await _validateParent(
        recordId: event.chickId!,
        parentLookup: () => _chicksDao.getByIdIncludingDeleted(event.chickId!),
        isDeleted: (chick) => chick.isDeleted,
        label: 'chick',
        syncTable: SupabaseConstants.chicksTable,
      );
      if (reason != null) return reason;
    }
    return null;
  }

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

  /// Soft-deletes every event linked to any of [breedingPairIds] and
  /// queues each for sync. Used by the breeding-deletion flow to keep
  /// calendar entries in step with their parent pair.
  Future<int> removeByBreedingPairIds(List<String> breedingPairIds) async {
    if (breedingPairIds.isEmpty) return 0;
    final events = await _localDao.getByBreedingPairIds(breedingPairIds);
    await Future.wait(events.map((e) => remove(e.id)));
    return events.length;
  }

  /// Soft-deletes every event linked to any of [chickIds] and queues each
  /// for sync. Used by the chick-deletion flow.
  Future<int> removeByChickIds(List<String> chickIds) async {
    if (chickIds.isEmpty) return 0;
    final events = await _localDao.getByChickIds(chickIds);
    await Future.wait(events.map((e) => remove(e.id)));
    return events.length;
  }

  /// Soft-deletes every event linked to any of [eggIds] and queues each
  /// for sync. Used by the egg-deletion flow.
  Future<int> removeByEggIds(List<String> eggIds) async {
    if (eggIds.isEmpty) return 0;
    final events = await _localDao.getByEggIds(eggIds);
    await Future.wait(events.map((e) => remove(e.id)));
    return events.length;
  }

  /// Soft-deletes every event linked to any of [incubationIds] and queues
  /// each for sync. Used by incubation completion/cancellation flows.
  Future<int> removeByIncubationIds(List<String> incubationIds) async {
    if (incubationIds.isEmpty) return 0;
    final events = await _localDao.getByIncubationIds(incubationIds);
    await Future.wait(events.map((e) => remove(e.id)));
    return events.length;
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
  Future<List<Event>> getActiveByChickAndType(String chickId, EventType type) =>
      _localDao.getActiveByChickAndType(chickId, type);
}
