import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/retry_scheduler.dart';
import 'package:uuid/uuid.dart';

/// Statistics returned by [SyncableRepository.pushAll].
typedef PushStats = ({int pushed, int orphansCleaned});

/// Immutable local/server snapshots captured immediately before a pull would
/// overwrite a locally pending row.
typedef PullConflict = ({
  String recordId,
  String detail,
  Map<String, dynamic> localPayload,
  Map<String, dynamic> serverPayload,
});

/// Persists pull conflicts before server-wins data is written to Drift.
///
/// Production repositories receive the encrypted implementation from
/// `repository_providers.dart`. The nullable repository constructor seam is
/// retained for narrow unit tests that do not exercise conflict persistence.
abstract interface class PullConflictSink {
  Future<void> persist({
    required String userId,
    required String tableName,
    required List<PullConflict> conflicts,
  });
}

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
/// Detects pull conflicts: every locally-PENDING record that the incoming
/// remote batch is about to overwrite. Server-wins still applies (the caller
/// writes remote over local); this only surfaces the discarded local edit so it
/// is never silently lost (data-layer.md § Conflict Resolution).
///
/// A pending local row is a conflict on ANY overwrite — remote newer, equal, OR
/// older — because an unpushed local edit is discarded regardless of clock
/// order. An earlier "remote strictly newer" gate silently dropped conflicts on
/// equal/older remote (e.g. under device-vs-server clock skew), which is exactly
/// the silent-overwrite the rulebook forbids. Shared by every syncable repo
/// (and the custom [PhotoRepository]) so the rule can't drift per-entity again.
List<PullConflict> detectPullConflicts<T>({
  required List<T> remote,
  required Map<String, T> localMap,
  required Set<String> pendingIds,
  required String Function(T item) idOf,
  required String Function(T item) detailOf,
  required Map<String, dynamic> Function(T item) payloadOf,
}) {
  final conflicts = <PullConflict>[];
  for (final item in remote) {
    final id = idOf(item);
    if (!pendingIds.contains(id)) continue;
    final local = localMap[id];
    if (local == null) continue;
    conflicts.add((
      recordId: id,
      detail: detailOf(item),
      localPayload: Map<String, dynamic>.unmodifiable(payloadOf(local)),
      serverPayload: Map<String, dynamic>.unmodifiable(payloadOf(item)),
    ));
  }
  return conflicts;
}

/// Persists detected conflicts before the caller applies server-wins rows.
///
/// A missing sink or any codec/database failure is surfaced as an
/// [AppException] and the caller must not continue to its local overwrite.
Future<void> persistPullConflicts({
  required PullConflictSink? sink,
  required String userId,
  required String tableName,
  required List<PullConflict> conflicts,
}) async {
  if (conflicts.isEmpty) return;
  if (sink == null) {
    throw const DatabaseException(
      'Sync conflict snapshot sink is unavailable',
      code: 'conflict_snapshot_sink_unavailable',
    );
  }
  await sink.persist(
    userId: userId,
    tableName: tableName,
    conflicts: conflicts,
  );
}

/// Logs a repository `pull()` failure and reports UNEXPECTED errors to Sentry.
///
/// Typed [AppException]s (offline `NetworkException`, validation, etc.) are
/// expected sync noise and are only logged. Everything else — serialization,
/// `TypeError`, Drift corruption, a malformed remote payload — is the
/// sync/corruption class that observability.md routes to Sentry as an issue,
/// not just a breadcrumb. Callers that already `rethrow` AppException pass
/// through safely (the filter is then a no-op); the one caller that swallows
/// AppException (profile) is correctly kept out of Sentry. Top-level like
/// [detectPullConflicts] so the custom PhotoRepository / ProfileRepository
/// (which do not mix in [SyncableRepository]) share the one implementation.
void reportPullFailure(String logTag, Object error, StackTrace stackTrace) {
  AppLogger.error('[$logTag] Pull failed', error, stackTrace);
  if (error is AppException) return;
  Sentry.captureException(
    error,
    stackTrace: stackTrace,
    withScope: (scope) => scope.setTag('sync_phase', 'pull'),
  );
}

/// Push-phase counterpart to [reportPullFailure]: logs the failure and reports
/// UNEXPECTED errors to Sentry with `sync_phase: 'push'`.
///
/// Same [AppException] filter — a transient `NetworkException` or a per-row
/// validation error is ordinary sync noise that the retry/backoff machinery
/// already owns. What this exists for is the class the filter lets through:
/// `TypeError`, serialization faults, Drift corruption. [pushPendingBatched]
/// catches only `on AppException`, so such an error escapes to the push
/// handler's layer catches, which used to swallow it into a bare
/// `AppLogger.error`. A deterministic corruption-class push failure then loops
/// silently for 24h/7 retries until [ValidatedSyncMixin.clearStaleErrors]
/// discards the rows — previously the DISCARD was the first and only Sentry
/// signal, long after the data was unrecoverable.
void reportPushFailure(String logTag, Object error, StackTrace stackTrace) {
  AppLogger.error('[$logTag] Push failed', error, stackTrace);
  if (error is AppException) return;
  Sentry.captureException(
    error,
    stackTrace: stackTrace,
    withScope: (scope) => scope.setTag('sync_phase', 'push'),
  );
}

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
      await syncDao.updateItem(
        existing.copyWith(
          status: SyncStatus.pending,
          errorMessage: null,
          retryCount: 0,
        ),
      );
    } else {
      await syncDao.insertItem(
        SyncMetadata(
          id: _uuid.v7(),
          table: syncTableName,
          userId: userId,
          status: SyncStatus.pending,
          recordId: recordId,
          // Stamp creation time so the post-pull unrecoverable-error cleanup
          // (retryCount exhausted AND createdAt aged > 24h) can actually act on
          // a row that later transitions to error — markError's UPDATE branch
          // preserves this timestamp. Without it every common-path error row
          // had a null createdAt, so the cleanup + Sentry monitoring were inert
          // and permanently-failing rows lingered as zombies forever. Safe now
          // that cleanup only runs post-pull (see pushAll note), never in the
          // push phase where it could strip reconcile protection.
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  /// Marks a record as sync error with incremented retry count.
  ///
  /// If no existing SyncMetadata is found, creates a new error entry
  /// instead of silently dropping the error.
  Future<void> markError(String recordId, String userId, String message) async {
    final existing = await syncDao.getByRecord(syncTableName, recordId);
    if (existing != null) {
      await syncDao.updateItem(
        existing.copyWith(
          status: SyncStatus.error,
          errorMessage: message,
          retryCount: (existing.retryCount ?? 0) + 1,
        ),
      );
    } else {
      await syncDao.insertItem(
        SyncMetadata(
          id: _uuid.v7(),
          table: syncTableName,
          userId: userId,
          status: SyncStatus.error,
          recordId: recordId,
          errorMessage: message,
          retryCount: 1,
          createdAt: DateTime.now(),
        ),
      );
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

  /// Push chunk size: Supabase upsert accepts a JSON array; 100 rows keeps
  /// each request well under payload limits while cutting round-trips 100x.
  static const int pushChunkSize = 100;

  /// Batched replacement for the per-row pushAll loop.
  ///
  /// Behavior contract (matches the legacy loop exactly):
  /// - orphan metadata (no local row / empty recordId) → cleaned + counted
  /// - [SyncStatus.pendingDelete] tombstones → [deleteRemote] one by one
  ///   (rare path; deletes cannot be batched into upsert payloads)
  /// - everything else → [upsertChunk] per [pushChunkSize]; on chunk-level
  ///   [AppException] falls back to per-item [push] so one poison row cannot
  ///   mask the rest (push() already does markError per item).
  ///
  /// Returns the count of successfully pushed records. Orphan cleanup and
  /// counting are the CALLER's job inside [resolveItem] (repos differ: some
  /// clean+count orphans, some markError FK orphans). A null return from
  /// [resolveItem] simply means "skip this record this round".
  Future<int> pushPendingBatched({
    required String userId,
    required Future<T?> Function(String recordId) resolveItem,
    required Future<void> Function(List<T> chunk) upsertChunk,
    required Future<void> Function(String recordId) deleteRemote,
    required String Function(T item) idOf,
    int chunkSize = pushChunkSize,
  }) async {
    var pushed = 0;
    final tablePending = await syncDao.getPendingByTable(userId, syncTableName);

    final toUpsert = <T>[];
    for (final meta in tablePending) {
      final recordId = meta.recordId ?? '';
      if (meta.status == SyncStatus.pendingDelete && recordId.isNotEmpty) {
        try {
          await deleteRemote(recordId);
          await syncDao.deleteByRecord(syncTableName, recordId);
          pushed++;
        } on AppException catch (e) {
          await markError(recordId, userId, e.message);
        }
        continue;
      }
      // Orphan detection/cleanup/counting is the CALLER's job inside
      // resolveItem (repos differ: clean+count vs markError for FK orphans).
      // A null return simply means "skip this record this round".
      final item = await resolveItem(recordId);
      if (item == null) continue;
      toUpsert.add(item);
    }

    for (var i = 0; i < toUpsert.length; i += chunkSize) {
      final chunk = toUpsert.sublist(
        i,
        i + chunkSize > toUpsert.length ? toUpsert.length : i + chunkSize,
      );
      try {
        await upsertChunk(chunk);
        await syncDao.deleteByRecords(syncTableName, chunk.map(idOf).toList());
        pushed += chunk.length;
      } on AppException {
        // Poison-row isolation: retry the chunk item-by-item via the legacy
        // path; push() marks per-item errors, successes clean their metadata.
        for (final item in chunk) {
          final before = await syncDao.getByRecord(syncTableName, idOf(item));
          await push(item);
          final after = await syncDao.getByRecord(syncTableName, idOf(item));
          if (before != null && after == null) pushed++;
        }
      }
    }
    return pushed;
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

  /// Gets the item used for sync.
  ///
  /// Soft-delete repositories override this to include deleted rows, because
  /// those tombstones still need to be pushed to Supabase.
  Future<T?> getLocalByIdForSync(String id) => getLocalById(id);

  /// Validates that an item's FK references exist locally.
  /// Returns null if valid, or a description of the broken FK.
  Future<String?> validateForeignKeys(T item);

  /// Whether FK validation should run for this sync payload.
  ///
  /// Soft-deleted tombstones can be pushed without waiting on parent FK
  /// metadata; if Supabase still rejects the payload, [push] records the error.
  bool shouldValidateForeignKeys(T item) => true;

  /// Extracts the entity ID from an item.
  String getEntityId(T item);

  /// Extracts the userId from an item.
  String getEntityUserId(T item);

  /// Maximum retry count before clearing stale error records. Kept equal to
  /// [RetryScheduler.maxRetries] so this cleanup fires exactly when retries are
  /// exhausted — it was 10 while retries capped at 7, so this path never ran.
  static const int maxSyncRetries = RetryScheduler.maxRetries;

  /// Pushes all pending items with orphan cleanup and FK validation.
  /// Valid items are batched into chunked upserts (see [pushPendingBatched]);
  /// FK validation stays per-item and local.
  @override
  Future<PushStats> pushAll(String userId) async {
    // Stale-error cleanup is deliberately NOT run here. It must happen AFTER
    // the pull/reconcile phase — SyncOrchestrator.cleanupUnrecoverableErrors
    // runs post-pull for exactly this reason. Deleting an error row during the
    // push phase drops the reconcile protection (getPendingRecordIds =
    // pending+error) for a record that only ever existed on-device, so the
    // subsequent full-reconcile pull would hardDelete it → permanent local data
    // loss. The orchestrator's post-pull cleanup is global (all tables), so the
    // per-table [clearStaleErrors] here is redundant as well as mistimed.
    var orphansCleaned = 0;

    final pushed = await pushPendingBatched(
      userId: userId,
      resolveItem: (recordId) async {
        final item = await getLocalByIdForSync(recordId);
        if (item == null) {
          AppLogger.warning(
            '[$syncLogTag] Orphan sync_metadata cleaned: $recordId',
          );
          await syncDao.deleteByRecord(syncTableName, recordId);
          orphansCleaned++;
          return null;
        }
        final orphanReason = shouldValidateForeignKeys(item)
            ? await validateForeignKeys(item)
            : null;
        if (orphanReason != null) {
          if (orphanReason.contains('not found locally')) {
            AppLogger.warning(
              '[$syncLogTag] True orphan ${getEntityId(item)}: $orphanReason',
            );
            await markSyncError(
              getEntityId(item),
              getEntityUserId(item),
              orphanReason,
            );
            orphansCleaned++;
          }
          return null; // FK not yet synced: skip this round (existing behavior)
        }
        return item;
      },
      upsertChunk: upsertChunkForSync,
      deleteRemote: (recordId) => deleteRemoteForSync(recordId, userId),
      idOf: getEntityId,
    );
    return (pushed: pushed, orphansCleaned: orphansCleaned);
  }

  /// Chunked upsert hook — implemented by each repo with its remote source.
  Future<void> upsertChunkForSync(List<T> chunk);

  /// Remote delete hook for pendingDelete tombstones. [userId] comes from
  /// the pushAll call because tombstones have no local row to read it from.
  Future<void> deleteRemoteForSync(String recordId, String userId);

  /// Clears error sync records that have exceeded max retries.
  ///
  /// Reports discarded records to Sentry before deletion so that data loss
  /// events are visible in production monitoring.
  Future<void> clearStaleErrors(String userId) async {
    final tableErrors = await syncDao.getErrorsByTable(userId, syncTableName);
    // Mirror SyncErrorHandler.cleanupUnrecoverableErrors: a record is only
    // unrecoverable once it has BOTH exhausted retries AND aged past the 24h
    // window. Without this age guard the two cleanup paths disagreed and this
    // one could discard a record the orchestrator's cleanup would still keep.
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final staleIds = <String>[];
    for (final meta in tableErrors) {
      final createdAt = meta.createdAt;
      if ((meta.retryCount ?? 0) >= maxSyncRetries &&
          createdAt != null &&
          !createdAt.isAfter(cutoff)) {
        staleIds.add(meta.recordId ?? 'unknown');
        AppLogger.warning(
          '[$syncLogTag] Cleared stale error after $maxSyncRetries retries: '
          '${meta.recordId}',
        );
        await syncDao.hardDelete(meta.id);
      }
    }
    if (staleIds.isNotEmpty) {
      Sentry.captureException(
        Exception(
          '[$syncLogTag] Discarding ${staleIds.length} unrecoverable sync '
          'records: ${staleIds.join(', ')}',
        ),
        stackTrace: StackTrace.current,
      );
    }
  }

  /// Delegates to [SyncableRepository.markError] for consistency.
  Future<void> markSyncError(String recordId, String userId, String message) =>
      markError(recordId, userId, message);
}
