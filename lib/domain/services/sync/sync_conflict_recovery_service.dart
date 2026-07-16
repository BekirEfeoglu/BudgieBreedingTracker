import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/database_provider.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/conflict_history_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/models/event_reminder_model.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/models/nest_model.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/data/models/notification_schedule_model.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/sync_conflict_payload_codec.dart';

/// Non-payload identity used to verify that a restored record left the sync
/// queue. Record values never cross this boundary.
typedef RestoredSyncRecordKey = ({String tableName, String recordId});

/// Aggregate outcome for a bulk "retry local" request.
class SyncConflictRetryResult {
  SyncConflictRetryResult({
    this.restored = 0,
    this.unavailable = 0,
    this.failed = 0,
    this.alreadyResolved = 0,
    List<RestoredSyncRecordKey> restoredRecords = const [],
  }) : restoredRecords = List.unmodifiable(restoredRecords);

  final int restored;
  final int unavailable;
  final int failed;
  final int alreadyResolved;
  final List<RestoredSyncRecordKey> restoredRecords;

  bool get hasWarnings => unavailable > 0 || failed > 0;
}

enum _RestoreOutcome { restored, unavailable, failed, alreadyResolved }

/// Restores encrypted local snapshots and re-queues them for push.
///
/// Each record is restored with its `sync_metadata` marker and resolution
/// timestamp in one Drift transaction. The active-future guard coalesces
/// duplicate/racing UI retries into one operation.
class SyncConflictRecoveryService {
  SyncConflictRecoveryService(this._ref);

  final Ref _ref;
  Future<SyncConflictRetryResult>? _activeRetry;

  Future<SyncConflictRetryResult> retryLocal(String userId) {
    final active = _activeRetry;
    if (active != null) return active;
    final future = _retryLocal(userId).whenComplete(() => _activeRetry = null);
    _activeRetry = future;
    return future;
  }

  /// Returns true only when every restored record's metadata marker has been
  /// removed by sync. A read failure is treated as not synced (fail closed).
  Future<bool> areRestoredRecordsSynced(
    Iterable<RestoredSyncRecordKey> restoredRecords,
  ) async {
    final recordsByTable = <String, Set<String>>{};
    for (final key in restoredRecords) {
      recordsByTable
          .putIfAbsent(key.tableName, () => <String>{})
          .add(key.recordId);
    }
    if (recordsByTable.isEmpty) return false;

    try {
      final dao = _ref.read(appDatabaseProvider).syncMetadataDao;
      for (final entry in recordsByTable.entries) {
        final remaining = await dao.getByRecords(
          entry.key,
          entry.value.toList(),
        );
        if (remaining.isNotEmpty) return false;
      }
      return true;
    } catch (_) {
      AppLogger.warning(
        '[ConflictRecovery] Restored-record sync verification failed',
      );
      return false;
    }
  }

  Future<SyncConflictRetryResult> _retryLocal(String userId) async {
    final database = _ref.read(appDatabaseProvider);
    final conflicts = await database.conflictHistoryDao.getUnresolved(userId);
    var restored = 0;
    var unavailable = 0;
    var failed = 0;
    var alreadyResolved = 0;
    final restoredRecords = <RestoredSyncRecordKey>[];

    for (final conflict in conflicts) {
      final outcome = await _restore(conflict, userId, database);
      switch (outcome) {
        case _RestoreOutcome.restored:
          restored++;
          restoredRecords.add((
            tableName: conflict.tableName,
            recordId: conflict.recordId,
          ));
        case _RestoreOutcome.unavailable:
          unavailable++;
        case _RestoreOutcome.failed:
          failed++;
        case _RestoreOutcome.alreadyResolved:
          alreadyResolved++;
      }
    }

    return SyncConflictRetryResult(
      restored: restored,
      unavailable: unavailable,
      failed: failed,
      alreadyResolved: alreadyResolved,
      restoredRecords: restoredRecords,
    );
  }

  Future<_RestoreOutcome> _restore(
    ConflictHistory conflict,
    String userId,
    AppDatabase database,
  ) async {
    final encryptedPayload = conflict.localPayload;
    final payloadVersion = conflict.payloadVersion;
    if (encryptedPayload == null || payloadVersion == null) {
      return _RestoreOutcome.unavailable;
    }

    final Map<String, dynamic> payload;
    try {
      payload = await _ref
          .read(syncConflictPayloadCodecProvider)
          .decode(
            encryptedPayload: encryptedPayload,
            payloadVersion: payloadVersion,
            tableName: conflict.tableName,
            recordId: conflict.recordId,
            userId: userId,
          );
    } on SyncConflictPayloadException catch (e) {
      AppLogger.warning(
        '[ConflictRecovery] Snapshot rejected (${e.code}) for '
        '${conflict.tableName}/${AppLogger.obfuscate(conflict.recordId)}',
      );
      return _RestoreOutcome.failed;
    }

    try {
      return await database.transaction(() async {
        final dao = database.conflictHistoryDao;
        final latest = await dao.getById(conflict.id);
        if (latest == null || latest.resolvedAt != null) {
          return _RestoreOutcome.alreadyResolved;
        }
        if (latest.userId != userId ||
            latest.tableName != conflict.tableName ||
            latest.recordId != conflict.recordId) {
          return _RestoreOutcome.failed;
        }

        await _saveLocal(
          database: database,
          tableName: conflict.tableName,
          recordId: conflict.recordId,
          userId: userId,
          payload: payload,
        );
        final updated = await dao.markResolvedIfUnresolved(
          conflict.id,
          DateTime.now(),
        );
        if (updated != 1) return _RestoreOutcome.alreadyResolved;
        return _RestoreOutcome.restored;
      });
    } catch (_) {
      // Never attach the raw exception: model parsing/database messages can
      // contain values from the decrypted payload.
      AppLogger.warning(
        '[ConflictRecovery] Restore failed for '
        '${conflict.tableName}/${AppLogger.obfuscate(conflict.recordId)}',
      );
      return _RestoreOutcome.failed;
    }
  }

  Future<void> _saveLocal({
    required AppDatabase database,
    required String tableName,
    required String recordId,
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    if (payload[SupabaseConstants.colId] != recordId ||
        payload[SupabaseConstants.colUserId] != userId) {
      throw const SyncConflictPayloadException('payload_identity_mismatch');
    }

    switch (tableName) {
      case SupabaseConstants.birdsTable:
        await database.birdsDao.insertItem(Bird.fromJson(payload));
      case SupabaseConstants.nestsTable:
        await database.nestsDao.insertItem(Nest.fromJson(payload));
      case SupabaseConstants.breedingPairsTable:
        await database.breedingPairsDao.insertItem(
          BreedingPair.fromJson(payload),
        );
      case SupabaseConstants.clutchesTable:
        await database.clutchesDao.insertItem(Clutch.fromJson(payload));
      case SupabaseConstants.incubationsTable:
        await database.incubationsDao.insertItem(Incubation.fromJson(payload));
      case SupabaseConstants.eggsTable:
        await database.eggsDao.insertItem(Egg.fromJson(payload));
      case SupabaseConstants.chicksTable:
        await database.chicksDao.insertItem(Chick.fromJson(payload));
      case SupabaseConstants.healthRecordsTable:
        await database.healthRecordsDao.insertItem(
          HealthRecord.fromJson(payload),
        );
      case SupabaseConstants.growthMeasurementsTable:
        await database.growthMeasurementsDao.insertItem(
          GrowthMeasurement.fromJson(payload),
        );
      case SupabaseConstants.eventsTable:
        await database.eventsDao.insertItem(Event.fromJson(payload));
      case SupabaseConstants.eventRemindersTable:
        await database.eventRemindersDao.insertItem(
          EventReminder.fromJson(payload),
        );
      case SupabaseConstants.notificationsTable:
        await database.notificationsDao.insertItem(
          AppNotification.fromJson(payload),
        );
      case SupabaseConstants.notificationSchedulesTable:
        await database.notificationSchedulesDao.insertItem(
          NotificationSchedule.fromJson(payload),
        );
      case SupabaseConstants.photosTable:
        await database.photosDao.insertItem(Photo.fromJson(payload));
      default:
        throw const SyncConflictPayloadException('unsupported_table');
    }
    await database.syncMetadataDao.markPendingByRecords(tableName, {
      recordId: userId,
    });
  }
}

final syncConflictRecoveryServiceProvider =
    Provider<SyncConflictRecoveryService>(SyncConflictRecoveryService.new);
