import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

part 'sync_push_handler_table.dart';

/// Handles pushing local pending changes to Supabase.
///
/// Follows FK dependency chain: parent tables are pushed first.
/// Independent entities at the same FK level are pushed in parallel.
class SyncPushHandler {
  SyncPushHandler(this._ref);

  final Ref _ref;

  /// Pushes all pending local changes to Supabase.
  ///
  /// Returns `true` if all layers pushed successfully, `false` if any
  /// layer had errors.
  Future<bool> pushChanges(String userId) async {
    AppLogger.info('[SyncOrchestrator] Pushing changes for $userId');
    int layerErrors = 0;
    int totalPushed = 0;
    int totalOrphans = 0;

    // FK layer dependency flags — downstream layers skip when parent fails
    bool l1Failed = false;
    bool l2Failed = false;
    bool l3Failed = false;
    bool l4Failed = false;
    bool l6Failed = false;

    // Single DB query to determine which tables have pending changes
    final syncDao = _ref.read(syncMetadataDaoProvider);
    final pending = await syncDao.getPendingTableNames(userId);

    // Layer 0: profile (always — lightweight single-record check)
    try {
      await _ref.read(profileRepositoryProvider).pushPending(userId);
    } catch (e, st) {
      layerErrors++;
      AppLogger.error('[SyncOrchestrator] Push L0 (profile) failed', e, st);
    }

    // Layer 1: root entities (birds, nests)
    if (_anyPending(pending, [
      SupabaseConstants.birdsTable,
      SupabaseConstants.nestsTable,
    ])) {
      final results = await _safeParallelPush([
        if (pending.contains(SupabaseConstants.birdsTable))
          () => _ref.read(birdRepositoryProvider).pushAll(userId),
        if (pending.contains(SupabaseConstants.nestsTable))
          () => _ref.read(nestRepositoryProvider).pushAll(userId),
      ], 'L1 (birds/nests)');
      for (final r in results) {
        totalPushed += r.pushed;
        totalOrphans += r.orphansCleaned;
      }
      if (results.isEmpty &&
          _anyPending(pending, [
            SupabaseConstants.birdsTable,
            SupabaseConstants.nestsTable,
          ])) {
        layerErrors++;
        l1Failed = true;
      }
    }

    // Layer 2: depends on birds
    if (l1Failed) {
      AppLogger.warning(
        '[SyncOrchestrator] Push L2 skipped: parent layer L1 failed',
      );
      l2Failed = true;
    } else if (pending.contains(SupabaseConstants.breedingPairsTable)) {
      try {
        final r = await _ref
            .read(breedingPairRepositoryProvider)
            .pushAll(userId);
        totalPushed += r.pushed;
        totalOrphans += r.orphansCleaned;
      } catch (e, st) {
        layerErrors++;
        l2Failed = true;
        AppLogger.error(
          '[SyncOrchestrator] Push L2 (breeding_pairs) failed',
          e,
          st,
        );
      }
    }

    // Layer 3: depends on breeding_pairs (independent of each other)
    if (l2Failed) {
      AppLogger.warning(
        '[SyncOrchestrator] Push L3 skipped: parent layer L2 failed',
      );
      l3Failed = true;
    } else if (_anyPending(pending, [
      SupabaseConstants.clutchesTable,
      SupabaseConstants.incubationsTable,
    ])) {
      final results = await _safeParallelPush([
        if (pending.contains(SupabaseConstants.clutchesTable))
          () => _ref.read(clutchRepositoryProvider).pushAll(userId),
        if (pending.contains(SupabaseConstants.incubationsTable))
          () => _ref.read(incubationRepositoryProvider).pushAll(userId),
      ], 'L3 (clutches/incubations)');
      for (final r in results) {
        totalPushed += r.pushed;
        totalOrphans += r.orphansCleaned;
      }
      if (results.isEmpty &&
          _anyPending(pending, [
            SupabaseConstants.clutchesTable,
            SupabaseConstants.incubationsTable,
          ])) {
        layerErrors++;
        l3Failed = true;
      }
    }

    // Layer 4: depends on clutches + incubations
    if (l3Failed) {
      AppLogger.warning(
        '[SyncOrchestrator] Push L4 skipped: parent layer L3 failed',
      );
      l4Failed = true;
    } else if (pending.contains(SupabaseConstants.eggsTable)) {
      try {
        final r = await _ref.read(eggRepositoryProvider).pushAll(userId);
        totalPushed += r.pushed;
        totalOrphans += r.orphansCleaned;
      } catch (e, st) {
        layerErrors++;
        l4Failed = true;
        AppLogger.error('[SyncOrchestrator] Push L4 (eggs) failed', e, st);
      }
    }

    // Layer 5: depends on eggs
    if (l4Failed) {
      AppLogger.warning(
        '[SyncOrchestrator] Push L5 skipped: parent layer L4 failed',
      );
    } else if (pending.contains(SupabaseConstants.chicksTable)) {
      try {
        final r = await _ref.read(chickRepositoryProvider).pushAll(userId);
        totalPushed += r.pushed;
        totalOrphans += r.orphansCleaned;
      } catch (e, st) {
        layerErrors++;
        AppLogger.error('[SyncOrchestrator] Push L5 (chicks) failed', e, st);
      }
    }

    // Layer 6: leaf entities (all independent — parallel push)
    if (_anyPending(pending, [
      SupabaseConstants.healthRecordsTable,
      SupabaseConstants.growthMeasurementsTable,
      SupabaseConstants.eventsTable,
      SupabaseConstants.notificationsTable,
      SupabaseConstants.notificationSchedulesTable,
      SupabaseConstants.photosTable,
    ])) {
      final results = await _safeParallelPush([
        if (pending.contains(SupabaseConstants.healthRecordsTable))
          () => _ref.read(healthRecordRepositoryProvider).pushAll(userId),
        if (pending.contains(SupabaseConstants.growthMeasurementsTable))
          () => _ref.read(growthMeasurementRepositoryProvider).pushAll(userId),
        if (pending.contains(SupabaseConstants.eventsTable))
          () => _ref.read(eventRepositoryProvider).pushAll(userId),
        if (pending.contains(SupabaseConstants.notificationsTable))
          () => _ref.read(notificationRepositoryProvider).pushAll(userId),
        if (pending.contains(SupabaseConstants.notificationSchedulesTable))
          () =>
              _ref.read(notificationScheduleRepositoryProvider).pushAll(userId),
        if (pending.contains(SupabaseConstants.photosTable))
          () => _ref.read(photoRepositoryProvider).pushAll(userId),
      ], 'L6 (leaf entities)');
      for (final r in results) {
        totalPushed += r.pushed;
        totalOrphans += r.orphansCleaned;
      }
      if (results.isEmpty) {
        layerErrors++;
        l6Failed = true;
      }
    }

    // Layer 7: depends on events
    if (l6Failed) {
      AppLogger.warning(
        '[SyncOrchestrator] Push L7 skipped: parent layer L6 failed',
      );
    } else if (pending.contains(SupabaseConstants.eventRemindersTable)) {
      try {
        final r = await _ref
            .read(eventReminderRepositoryProvider)
            .pushAll(userId);
        totalPushed += r.pushed;
        totalOrphans += r.orphansCleaned;
      } catch (e, st) {
        layerErrors++;
        AppLogger.error(
          '[SyncOrchestrator] Push L7 (event_reminders) failed',
          e,
          st,
        );
      }
    }

    final orphanInfo = totalOrphans > 0
        ? ', $totalOrphans orphans cleaned'
        : '';

    // Report sync metrics to Sentry for observability.
    Sentry.addBreadcrumb(Breadcrumb(
      message: 'SyncPush completed',
      data: {
        'pushed': totalPushed,
        'orphansCleaned': totalOrphans,
        'layerErrors': layerErrors,
        'success': layerErrors == 0,
      },
      category: 'sync.push',
      level: layerErrors > 0 ? SentryLevel.warning : SentryLevel.info,
    ));

    if (layerErrors > 0) {
      AppLogger.warning(
        '[SyncOrchestrator] Push completed with $layerErrors layer error(s): '
        '$totalPushed pushed$orphanInfo',
      );
      return false;
    } else {
      AppLogger.info(
        '[SyncOrchestrator] Push complete: $totalPushed pushed$orphanInfo',
      );
      return true;
    }
  }

  /// Pushes pending records for a specific table.
  Future<void> pushTable(String userId, String table) =>
      _pushSingleTable(_ref, userId, table);
}
