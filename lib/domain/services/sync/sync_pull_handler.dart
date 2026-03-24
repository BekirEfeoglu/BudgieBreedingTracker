import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart'
    show conflictHistoryDaoProvider;
import 'package:budgie_breeding_tracker/data/models/conflict_history_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';

/// Handles pulling remote changes from Supabase into local DB.
///
/// Uses incremental sync (only fetch records updated after last successful
/// sync). Independent entities within the same FK dependency layer are
/// pulled in parallel via [Future.wait].
class SyncPullHandler {
  SyncPullHandler(this._ref);

  final Ref _ref;

  /// Pulls remote changes from Supabase into local DB.
  ///
  /// Uses [since] for incremental sync. Pass `null` for full reconciliation.
  Future<bool> pullChanges(String userId, {DateTime? since}) async {
    // Clock skew protection: if since is in the future, force full reconciliation
    if (since != null && since.isAfter(DateTime.now())) {
      AppLogger.warning(
        '[SyncOrchestrator] Clock skew detected: since ($since) is in the future. '
        'Forcing full reconciliation.',
      );
      since = null;
    }

    AppLogger.info('[SyncOrchestrator] Pulling changes for $userId');
    int layerErrors = 0;

    // Layer 0: no FK deps
    try {
      await _ref.read(profileRepositoryProvider).pull(userId);
    } catch (e, st) {
      layerErrors++;
      AppLogger.error('[SyncOrchestrator] Pull L0 (profile) failed', e, st);
    }

    // Layer 1: birds, nests (independent root entities)
    {
      final birdRepo = _ref.read(birdRepositoryProvider);
      final nestRepo = _ref.read(nestRepositoryProvider);
      final errors = await _safeParallelPull([
        () async {
          await birdRepo.pull(userId, lastSyncedAt: since);
          _reportPullConflicts(
            birdRepo.lastPullConflicts,
            SupabaseConstants.birdsTable,
          );
        },
        () async {
          await nestRepo.pull(userId, lastSyncedAt: since);
          _reportPullConflicts(
            nestRepo.lastPullConflicts,
            SupabaseConstants.nestsTable,
          );
        },
      ], 'L1 (birds/nests)');
      layerErrors += errors;
    }

    // Layer 2: breeding_pairs (depends on birds)
    try {
      final bpRepo = _ref.read(breedingPairRepositoryProvider);
      await bpRepo.pull(userId, lastSyncedAt: since);
      _reportPullConflicts(
        bpRepo.lastPullConflicts,
        SupabaseConstants.breedingPairsTable,
      );
    } catch (e, st) {
      layerErrors++;
      AppLogger.error(
        '[SyncOrchestrator] Pull L2 (breeding_pairs) failed',
        e,
        st,
      );
    }

    // Layer 3: clutches, incubations (depend on breeding_pairs)
    {
      final clutchRepo = _ref.read(clutchRepositoryProvider);
      final errors = await _safeParallelPull([
        () async {
          await clutchRepo.pull(userId, lastSyncedAt: since);
          _reportPullConflicts(
            clutchRepo.lastPullConflicts,
            SupabaseConstants.clutchesTable,
          );
        },
        () => _ref
            .read(incubationRepositoryProvider)
            .pull(userId, lastSyncedAt: since),
      ], 'L3 (clutches/incubations)');
      layerErrors += errors;
    }

    // Layer 4: eggs (depends on clutches + incubations)
    try {
      final eggRepo = _ref.read(eggRepositoryProvider);
      await eggRepo.pull(userId, lastSyncedAt: since);
      _reportPullConflicts(
        eggRepo.lastPullConflicts,
        SupabaseConstants.eggsTable,
      );
    } catch (e, st) {
      layerErrors++;
      AppLogger.error('[SyncOrchestrator] Pull L4 (eggs) failed', e, st);
    }

    // Layer 5: chicks (depends on eggs)
    try {
      final chickRepo = _ref.read(chickRepositoryProvider);
      await chickRepo.pull(userId, lastSyncedAt: since);
      _reportPullConflicts(
        chickRepo.lastPullConflicts,
        SupabaseConstants.chicksTable,
      );
    } catch (e, st) {
      layerErrors++;
      AppLogger.error('[SyncOrchestrator] Pull L5 (chicks) failed', e, st);
    }

    // Layer 6: leaf entities (all independent of each other)
    {
      final hrRepo = _ref.read(healthRecordRepositoryProvider);
      final eventRepo = _ref.read(eventRepositoryProvider);
      final nsRepo = _ref.read(notificationScheduleRepositoryProvider);
      final errors = await _safeParallelPull([
        () async {
          await hrRepo.pull(userId, lastSyncedAt: since);
          _reportPullConflicts(
            hrRepo.lastPullConflicts,
            SupabaseConstants.healthRecordsTable,
          );
        },
        () => _ref
            .read(growthMeasurementRepositoryProvider)
            .pull(userId, lastSyncedAt: since),
        () async {
          await eventRepo.pull(userId, lastSyncedAt: since);
          _reportPullConflicts(
            eventRepo.lastPullConflicts,
            SupabaseConstants.eventsTable,
          );
        },
        () => _ref
            .read(notificationRepositoryProvider)
            .pull(userId, lastSyncedAt: since),
        () async {
          await nsRepo.pull(userId, lastSyncedAt: since);
          _reportPullConflicts(
            nsRepo.lastPullConflicts,
            SupabaseConstants.notificationSchedulesTable,
          );
        },
        () => _ref
            .read(photoRepositoryProvider)
            .pull(userId, lastSyncedAt: since),
      ], 'L6 (leaf entities)');
      layerErrors += errors;
    }

    // Layer 7: event_reminders (depends on events)
    try {
      final erRepo = _ref.read(eventReminderRepositoryProvider);
      await erRepo.pull(userId, lastSyncedAt: since);
      _reportPullConflicts(
        erRepo.lastPullConflicts,
        SupabaseConstants.eventRemindersTable,
      );
    } catch (e, st) {
      layerErrors++;
      AppLogger.error(
        '[SyncOrchestrator] Pull L7 (event_reminders) failed',
        e,
        st,
      );
    }

    if (layerErrors > 0) {
      AppLogger.warning(
        '[SyncOrchestrator] Pull completed with $layerErrors layer error(s). '
        'Check logs above for "[SyncOrchestrator] Pull L*" entries.',
      );
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'SyncPull completed with errors',
        data: {'layerErrors': layerErrors, 'incremental': since != null},
        category: 'sync.pull',
        level: SentryLevel.warning,
      ));
      return false;
    } else {
      AppLogger.info('[SyncOrchestrator] Pull complete');
      return true;
    }
  }

  /// Reports detected pull conflicts to [conflictHistoryProvider] and persists
  /// them to the local [ConflictHistoryDao] for offline history.
  void _reportPullConflicts(
    List<({String recordId, String detail})> conflicts,
    String tableName,
  ) {
    if (conflicts.isEmpty) return;

    final notifier = _ref.read(conflictHistoryProvider.notifier);
    final dao = _ref.read(conflictHistoryDaoProvider);
    final userId = _ref.read(currentUserIdProvider);
    const uuid = Uuid();

    for (final c in conflicts) {
      // In-memory (existing behavior)
      notifier.addConflict(
        SyncConflict(
          table: tableName,
          recordId: c.recordId,
          detectedAt: DateTime.now(),
          description: c.detail,
        ),
      );

      // Persist to DB
      dao.insert(ConflictHistory(
        id: uuid.v4(),
        userId: userId,
        tableName: tableName,
        recordId: c.recordId,
        description: c.detail,
        conflictType: ConflictType.serverWins,
        createdAt: DateTime.now(),
      ));
    }

    AppLogger.info(
      '[SyncOrchestrator] ${conflicts.length} conflict(s) detected in $tableName',
    );
  }

  /// Runs pull operations in parallel with individual error isolation.
  Future<int> _safeParallelPull(
    List<Future<void> Function()> tasks,
    String layerLabel,
  ) async {
    int failures = 0;
    final futures = tasks.map((task) async {
      try {
        await task();
        return true;
      } catch (e, st) {
        AppLogger.error(
          '[SyncOrchestrator] Pull $layerLabel partial failure',
          e,
          st,
        );
        return false;
      }
    });
    final outcomes = await Future.wait(futures);
    for (final ok in outcomes) {
      if (!ok) failures++;
    }
    return failures;
  }
}
