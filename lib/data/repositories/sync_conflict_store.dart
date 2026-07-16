import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/conflict_history_dao.dart';
import 'package:budgie_breeding_tracker/data/models/conflict_history_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/sync_conflict_payload_codec.dart';
import 'package:uuid/uuid.dart';

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

    try {
      final rows = <ConflictHistory>[];
      for (final conflict in conflicts) {
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
      await _dao.insertAllPreservingOldestRecoverable(rows);
    } on SyncConflictPayloadException catch (e) {
      throw DatabaseException(
        'Sync conflict snapshot could not be stored',
        code: e.code,
      );
    } catch (_) {
      // Do not attach the raw database/codec error: serialization errors may
      // retain user payload fragments in their message.
      AppLogger.warning(
        '[SyncConflictStore] Snapshot persistence failed for $tableName',
      );
      throw const DatabaseException(
        'Sync conflict snapshot could not be stored',
        code: 'conflict_snapshot_persistence_failed',
      );
    }
  }
}
