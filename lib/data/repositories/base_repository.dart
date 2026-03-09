import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:uuid/uuid.dart';

/// Statistics returned by [SyncableRepository.pushAll].
typedef PushStats = ({int pushed, int orphansCleaned});

/// Empty push stats constant for convenience.
const PushStats emptyPushStats = (pushed: 0, orphansCleaned: 0);

/// Base repository interface and syncable mixin for offline-first architecture.
///
/// All entity repositories extend [BaseRepository] and mix in
/// [SyncableRepository] for push/pull sync with Supabase.
abstract class BaseRepository<T> {
  /// Watches all non-deleted items for a user as a live stream.
  Stream<List<T>> watchAll(String userId);

  /// Watches a single item by id as a live stream.
  Stream<T?> watchById(String id);

  /// Gets all non-deleted items for a user.
  Future<List<T>> getAll(String userId);

  /// Gets a single item by id.
  Future<T?> getById(String id);

  /// Saves (insert or update) a single item locally and marks it for sync.
  Future<void> save(T item);

  /// Saves multiple items locally and marks them for sync.
  Future<void> saveAll(List<T> items);

  /// Soft-deletes an item locally and marks it for sync.
  Future<void> remove(String id);

  /// Permanently deletes an item from local database.
  Future<void> hardRemove(String id);
}

/// Mixin for repositories that sync with a remote Supabase source.
///
/// Implements pull (server → local) and push (local → server) operations.
/// Uses server-wins conflict resolution on pull.
mixin SyncableRepository<T> on BaseRepository<T> {
  static const _uuid = Uuid();

  /// The SyncMetadataDao for reading/writing sync metadata.
  SyncMetadataDao get syncDao;

  /// The Supabase table name for filtering sync_metadata records.
  String get syncTableName;

  /// Pulls all records updated since [lastSyncedAt] from remote and
  /// upserts them into the local database (server-wins).
  Future<void> pull(String userId, {DateTime? lastSyncedAt});

  /// Pushes a single pending record to the remote source.
  Future<void> push(T item);

  /// Pushes all pending records for a user to the remote source.
  /// Returns statistics about pushed items and cleaned orphans.
  Future<PushStats> pushAll(String userId);

  /// Marks a record as pending sync in sync_metadata.
  ///
  /// Uses upsert logic: if metadata already exists for this (table, recordId),
  /// resets it to pending status instead of creating a duplicate entry.
  Future<void> markPending(String recordId, String userId) async {
    final existing = await syncDao.getByRecord(syncTableName, recordId);
    if (existing != null) {
      await syncDao.updateItem(existing.copyWith(
        status: SyncStatus.pending,
        errorMessage: null,
        retryCount: 0,
      ));
    } else {
      await syncDao.insertItem(SyncMetadata(
        id: _uuid.v4(),
        table: syncTableName,
        userId: userId,
        status: SyncStatus.pending,
        recordId: recordId,
      ));
    }
  }

  /// Marks a record as sync error with incremented retry count.
  Future<void> markError(String recordId, String userId, String message) async {
    final existing = await syncDao.getByRecord(syncTableName, recordId);
    if (existing != null) {
      await syncDao.updateItem(existing.copyWith(
        status: SyncStatus.error,
        errorMessage: message,
        retryCount: (existing.retryCount ?? 0) + 1,
      ));
    }
  }

  /// Tries to immediately push an item to remote after local save.
  ///
  /// Silently catches errors — item stays pending for next [pushAll] cycle.
  /// This enables real-time sync while preserving offline-first resilience.
  Future<void> tryImmediatePush(T item) async {
    try {
      await push(item);
    } catch (e) {
      AppLogger.debug('[SyncableRepository] Immediate push deferred: $e');
    }
  }
}

/// Mixin that adds FK validation and stale error cleanup to [pushAll].
///
/// Repositories with FK dependencies (e.g. Egg→Incubation, Chick→Egg)
/// should use this mixin to validate references before pushing to Supabase.
/// This prevents FK constraint violations and cleans up orphan metadata.
///
/// Usage:
/// ```dart
/// class EggRepository extends BaseRepository<Egg>
///     with SyncableRepository<Egg>, ValidatedSyncMixin<Egg> {
///   @override
///   String get syncLogTag => 'EggRepository';
///   // ... implement other abstract members
/// }
/// ```
mixin ValidatedSyncMixin<T> on BaseRepository<T>, SyncableRepository<T> {
  /// Log tag prefix for warning/error messages.
  String get syncLogTag;

  /// Gets a local item by ID from the DAO.
  Future<T?> getLocalById(String id);

  /// Validates that an item's FK references exist locally.
  /// Returns null if valid, or a description of the broken FK.
  Future<String?> validateForeignKeys(T item);

  /// Extracts the entity ID from an item.
  String getEntityId(T item);

  /// Extracts the userId from an item.
  String getEntityUserId(T item);

  /// Maximum retry count before clearing stale error records.
  static const int maxSyncRetries = 10;

  /// Pushes all pending items with orphan cleanup and FK validation.
  @override
  Future<PushStats> pushAll(String userId) async {
    int pushed = 0;
    int orphansCleaned = 0;
    await clearStaleErrors(userId);

    final tablePending = await syncDao.getPendingByTable(userId, syncTableName);

    for (final meta in tablePending) {
      final item = await getLocalById(meta.recordId ?? '');
      if (item == null) {
        AppLogger.warning(
          '[$syncLogTag] Orphan sync_metadata cleaned: ${meta.recordId}',
        );
        await syncDao.deleteByRecord(syncTableName, meta.recordId ?? '');
        orphansCleaned++;
        continue;
      }

      final orphanReason = await validateForeignKeys(item);
      if (orphanReason != null) {
        if (orphanReason.contains('not found locally')) {
          AppLogger.warning(
            '[$syncLogTag] True orphan ${getEntityId(item)}: $orphanReason',
          );
          await markSyncError(
              getEntityId(item), getEntityUserId(item), orphanReason);
          orphansCleaned++;
        }
        continue;
      }

      await push(item);
      pushed++;
    }
    return (pushed: pushed, orphansCleaned: orphansCleaned);
  }

  /// Clears error sync records that have exceeded max retries.
  Future<void> clearStaleErrors(String userId) async {
    final tableErrors = await syncDao.getErrorsByTable(userId, syncTableName);
    for (final meta in tableErrors) {
      if ((meta.retryCount ?? 0) >= maxSyncRetries) {
        AppLogger.warning(
          '[$syncLogTag] Cleared stale error after $maxSyncRetries retries: '
          '${meta.recordId}',
        );
        await syncDao.hardDelete(meta.id);
      }
    }
  }

  /// Delegates to [SyncableRepository.markError] for consistency.
  Future<void> markSyncError(
    String recordId,
    String userId,
    String message,
  ) => markError(recordId, userId, message);
}
