import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/conflict_history_dao.dart';
import 'package:budgie_breeding_tracker/data/models/conflict_history_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/sync_conflict_payload_codec.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

/// Payload-free marker exception used to surface snapshot persistence failures
/// to Sentry.
///
/// The raw codec/Drift error is deliberately NOT reported: serialization and
/// database messages can retain fragments of the user's entity payload, and
/// background-sync.md allows only "tablo, obfuscated record ID, sonuç kodu ve
/// aggregate sayılar" to leave this boundary.
class SyncConflictSnapshotFailure implements Exception {
  const SyncConflictSnapshotFailure(this.code);

  final String code;

  @override
  String toString() => 'SyncConflictSnapshotFailure($code)';
}

/// Encrypts and persists conflict snapshots before server-wins overwrite.
class SyncConflictStore implements PullConflictSink {
  SyncConflictStore({
    required ConflictHistoryDao dao,
    required SyncConflictPayloadCodec codec,
    DateTime Function()? now,
  }) : _dao = dao,
       _codec = codec,
       _now = now ?? DateTime.now;

  final ConflictHistoryDao _dao;
  final SyncConflictPayloadCodec _codec;
  final DateTime Function() _now;

  static const _uuid = Uuid();

  @override
  Future<void> persist({
    required String userId,
    required String tableName,
    required List<PullConflict> conflicts,
  }) async {
    if (conflicts.isEmpty) return;

    // Tracks which record is mid-encode so a failure can name it. Cleared
    // before the batch insert, where no single record is the culprit.
    String? encodingRecordId;
    try {
      final rows = <ConflictHistory>[];
      for (final conflict in conflicts) {
        encodingRecordId = conflict.recordId;
        final localPayload = await _codec.encode(
          tableName: tableName,
          recordId: conflict.recordId,
          userId: userId,
          payload: conflict.localPayload,
        );
        final serverPayload = await _codec.encode(
          tableName: tableName,
          recordId: conflict.recordId,
          userId: userId,
          payload: conflict.serverPayload,
        );
        rows.add(
          ConflictHistory(
            id: _uuid.v7(),
            userId: userId,
            tableName: tableName,
            recordId: conflict.recordId,
            description: conflict.detail,
            conflictType: ConflictType.serverWins,
            localPayload: localPayload,
            serverPayload: serverPayload,
            payloadVersion: SyncConflictPayloadCodec.currentVersion,
            createdAt: _now().toUtc(),
          ),
        );
      }
      encodingRecordId = null;
      await _dao.insertAllPreservingOldestRecoverable(rows);
    } on SyncConflictPayloadException catch (e, st) {
      _reportSnapshotFailure(
        code: e.code,
        tableName: tableName,
        recordId: encodingRecordId,
        conflictCount: conflicts.length,
        stackTrace: st,
      );
      throw DatabaseException(
        'Sync conflict snapshot could not be stored',
        code: e.code,
      );
    } catch (_, st) {
      // Do not attach the raw database/codec error: serialization errors may
      // retain user payload fragments in their message.
      AppLogger.warning(
        '[SyncConflictStore] Snapshot persistence failed for $tableName',
      );
      _reportSnapshotFailure(
        code: 'conflict_snapshot_persistence_failed',
        tableName: tableName,
        recordId: encodingRecordId,
        conflictCount: conflicts.length,
        stackTrace: st,
      );
      throw const DatabaseException(
        'Sync conflict snapshot could not be stored',
        code: 'conflict_snapshot_persistence_failed',
      );
    }
  }

  /// Reports a snapshot persistence failure — a data-loss class event.
  ///
  /// The [DatabaseException] this method accompanies aborts the repository's
  /// pull, but it IS an `AppException`, so `reportPullFailure` deliberately
  /// keeps it out of Sentry and the abort's cause would otherwise never
  /// surface. The failure means a locally pending edit is about to be
  /// overwritten by server-wins with NO recoverable snapshot behind it.
  ///
  /// Only non-payload identity crosses this boundary: table name, obfuscated
  /// record id, outcome code and an aggregate count.
  void _reportSnapshotFailure({
    required String code,
    required String tableName,
    required String? recordId,
    required int conflictCount,
    required StackTrace stackTrace,
  }) {
    Sentry.captureException(
      SyncConflictSnapshotFailure(code),
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('feature', 'sync');
        scope.setTag('sync_phase', 'pull');
        scope.setContexts('sync_conflict', {
          'table': tableName,
          'recordId': AppLogger.obfuscate(recordId),
          'code': code,
          'conflictCount': conflictCount,
        });
      },
    );
  }
}
