import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/event_reminders_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/events_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/event_reminder_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/event_reminder_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:uuid/uuid.dart';

/// Repository for [EventReminder] entities with offline-first sync support.
///
/// Uses [ValidatedSyncMixin] to validate FK references (event)
/// before pushing to Supabase, preventing FK constraint violations.
class EventReminderRepository extends BaseRepository<EventReminder>
    with SyncableRepository<EventReminder>, ValidatedSyncMixin<EventReminder> {
  final EventRemindersDao _localDao;
  final EventReminderRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;
  final EventsDao _eventsDao;

  static const _uuid = Uuid();

  EventReminderRepository({
    required EventRemindersDao localDao,
    required EventReminderRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
    required EventsDao eventsDao,
  })  : _localDao = localDao,
        _remoteSource = remoteSource,
        _syncDao = syncDao,
        _eventsDao = eventsDao;

  static const _table = SupabaseConstants.eventRemindersTable;

  /// Conflicts detected during the last [pull] operation.
  final List<({String recordId, String detail})> lastPullConflicts = [];

  // ── ValidatedSyncMixin overrides ──────────────────────────────────────

  @override
  SyncMetadataDao get syncDao => _syncDao;

  @override
  String get syncTableName => _table;

  @override
  String get syncLogTag => 'EventReminderRepository';

  @override
  Future<EventReminder?> getLocalById(String id) => _localDao.getById(id);

  @override
  String getEntityId(EventReminder item) => item.id;

  @override
  String getEntityUserId(EventReminder item) => item.userId;

  @override
  Future<String?> validateForeignKeys(EventReminder reminder) async {
    final event = await _eventsDao.getById(reminder.eventId);
    if (event == null) {
      return 'Referenced event ${reminder.eventId} not found locally';
    }
    final syncMeta = await _syncDao.getByRecord(
      SupabaseConstants.eventsTable,
      reminder.eventId,
    );
    if (syncMeta != null) {
      return 'Event ${reminder.eventId} not yet synced to server';
    }
    return null;
  }

  // ── BaseRepository overrides ──────────────────────────────────────────

  @override
  Stream<List<EventReminder>> watchAll(String userId) =>
      _localDao.watchAll(userId);

  @override
  Stream<EventReminder?> watchById(String id) =>
      _localDao.watchById(id);

  @override
  Future<List<EventReminder>> getAll(String userId) =>
      _localDao.getAll(userId);

  @override
  Future<EventReminder?> getById(String id) => _localDao.getById(id);

  @override
  Future<void> save(EventReminder item) async {
    await _localDao.insertItem(item);
    await markPending(item.id, item.userId);
    await tryImmediatePush(item);
  }

  @override
  Future<void> saveAll(List<EventReminder> items) async {
    await _localDao.insertAll(items);
    if (items.isNotEmpty) {
      final syncEntries = items.map((item) => SyncMetadata(
        id: _uuid.v4(),
        table: _table,
        userId: item.userId,
        status: SyncStatus.pending,
        recordId: item.id,
      )).toList();
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
              detail: remoteItem.eventId,
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
      AppLogger.error('[EventReminderRepository] Pull failed', e, st);
    }
  }

  @override
  Future<void> push(EventReminder item) async {
    try {
      await _remoteSource.upsert(item);
      await _syncDao.deleteByRecord(_table, item.id);
    } on AppException catch (e) {
      await markSyncError(item.id, item.userId, e.message);
    }
  }

  // pushAll() is provided by ValidatedSyncMixin

  // ── Domain-specific queries ───────────────────────────────────────────

  /// Watch reminders for a specific event.
  Stream<List<EventReminder>> watchByEvent(String eventId) =>
      _localDao.watchByEvent(eventId);

}
