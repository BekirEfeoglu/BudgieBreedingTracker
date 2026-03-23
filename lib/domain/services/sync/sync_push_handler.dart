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
    final ctx = _PushContext();

    final syncDao = _ref.read(syncMetadataDaoProvider);
    final pending = await syncDao.getPendingTableNames(userId);

    await _pushLayer0Profile(userId, ctx);
    await _pushLayer1RootEntities(userId, pending, ctx);
    await _pushLayer2BreedingPairs(userId, pending, ctx);
    await _pushLayer3ClutchesIncubations(userId, pending, ctx);
    await _pushLayer4Eggs(userId, pending, ctx);
    await _pushLayer5Chicks(userId, pending, ctx);
    await _pushLayer6LeafEntities(userId, pending, ctx);
    await _pushLayer7EventReminders(userId, pending, ctx);

    return _reportPushResult(ctx);
  }

  Future<void> _pushLayer0Profile(String userId, _PushContext ctx) async {
    try {
      await _ref.read(profileRepositoryProvider).pushPending(userId);
    } catch (e, st) {
      ctx.layerErrors++;
      AppLogger.error('[SyncOrchestrator] Push L0 (profile) failed', e, st);
    }
  }

  Future<void> _pushLayer1RootEntities(
    String userId, Set<String> pending, _PushContext ctx,
  ) async {
    if (!_anyPending(pending, [
      SupabaseConstants.birdsTable,
      SupabaseConstants.nestsTable,
    ])) {
      return;
    }

    final results = await _safeParallelPush([
      if (pending.contains(SupabaseConstants.birdsTable))
        () => _ref.read(birdRepositoryProvider).pushAll(userId),
      if (pending.contains(SupabaseConstants.nestsTable))
        () => _ref.read(nestRepositoryProvider).pushAll(userId),
    ], 'L1 (birds/nests)');
    ctx.addResults(results);
    if (results.isEmpty &&
        _anyPending(pending, [
          SupabaseConstants.birdsTable,
          SupabaseConstants.nestsTable,
        ])) {
      ctx.layerErrors++;
      ctx.l1Failed = true;
    }
  }

  Future<void> _pushLayer2BreedingPairs(
    String userId, Set<String> pending, _PushContext ctx,
  ) async {
    if (ctx.l1Failed) {
      AppLogger.warning('[SyncOrchestrator] Push L2 skipped: parent layer L1 failed');
      ctx.l2Failed = true;
      return;
    }
    if (!pending.contains(SupabaseConstants.breedingPairsTable)) return;
    try {
      ctx.addResult(await _ref.read(breedingPairRepositoryProvider).pushAll(userId));
    } catch (e, st) {
      ctx.layerErrors++;
      ctx.l2Failed = true;
      AppLogger.error('[SyncOrchestrator] Push L2 (breeding_pairs) failed', e, st);
    }
  }

  Future<void> _pushLayer3ClutchesIncubations(
    String userId, Set<String> pending, _PushContext ctx,
  ) async {
    if (ctx.l2Failed) {
      AppLogger.warning('[SyncOrchestrator] Push L3 skipped: parent layer L2 failed');
      ctx.l3Failed = true;
      return;
    }
    if (!_anyPending(pending, [
      SupabaseConstants.clutchesTable,
      SupabaseConstants.incubationsTable,
    ])) {
      return;
    }

    final results = await _safeParallelPush([
      if (pending.contains(SupabaseConstants.clutchesTable))
        () => _ref.read(clutchRepositoryProvider).pushAll(userId),
      if (pending.contains(SupabaseConstants.incubationsTable))
        () => _ref.read(incubationRepositoryProvider).pushAll(userId),
    ], 'L3 (clutches/incubations)');
    ctx.addResults(results);
    if (results.isEmpty &&
        _anyPending(pending, [
          SupabaseConstants.clutchesTable,
          SupabaseConstants.incubationsTable,
        ])) {
      ctx.layerErrors++;
      ctx.l3Failed = true;
    }
  }

  Future<void> _pushLayer4Eggs(
    String userId, Set<String> pending, _PushContext ctx,
  ) async {
    if (ctx.l3Failed) {
      AppLogger.warning('[SyncOrchestrator] Push L4 skipped: parent layer L3 failed');
      ctx.l4Failed = true;
      return;
    }
    if (!pending.contains(SupabaseConstants.eggsTable)) return;
    try {
      ctx.addResult(await _ref.read(eggRepositoryProvider).pushAll(userId));
    } catch (e, st) {
      ctx.layerErrors++;
      ctx.l4Failed = true;
      AppLogger.error('[SyncOrchestrator] Push L4 (eggs) failed', e, st);
    }
  }

  Future<void> _pushLayer5Chicks(
    String userId, Set<String> pending, _PushContext ctx,
  ) async {
    if (ctx.l4Failed) {
      AppLogger.warning('[SyncOrchestrator] Push L5 skipped: parent layer L4 failed');
      return;
    }
    if (!pending.contains(SupabaseConstants.chicksTable)) return;
    try {
      ctx.addResult(await _ref.read(chickRepositoryProvider).pushAll(userId));
    } catch (e, st) {
      ctx.layerErrors++;
      AppLogger.error('[SyncOrchestrator] Push L5 (chicks) failed', e, st);
    }
  }

  Future<void> _pushLayer6LeafEntities(
    String userId, Set<String> pending, _PushContext ctx,
  ) async {
    final leafTables = [
      SupabaseConstants.healthRecordsTable,
      SupabaseConstants.growthMeasurementsTable,
      SupabaseConstants.eventsTable,
      SupabaseConstants.notificationsTable,
      SupabaseConstants.notificationSchedulesTable,
      SupabaseConstants.photosTable,
    ];
    if (!_anyPending(pending, leafTables)) return;

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
        () => _ref.read(notificationScheduleRepositoryProvider).pushAll(userId),
      if (pending.contains(SupabaseConstants.photosTable))
        () => _ref.read(photoRepositoryProvider).pushAll(userId),
    ], 'L6 (leaf entities)');
    ctx.addResults(results);
    if (results.isEmpty) {
      ctx.layerErrors++;
      ctx.l6Failed = true;
    }
  }

  Future<void> _pushLayer7EventReminders(
    String userId, Set<String> pending, _PushContext ctx,
  ) async {
    if (ctx.l6Failed) {
      AppLogger.warning('[SyncOrchestrator] Push L7 skipped: parent layer L6 failed');
      return;
    }
    if (!pending.contains(SupabaseConstants.eventRemindersTable)) return;
    try {
      ctx.addResult(await _ref.read(eventReminderRepositoryProvider).pushAll(userId));
    } catch (e, st) {
      ctx.layerErrors++;
      AppLogger.error('[SyncOrchestrator] Push L7 (event_reminders) failed', e, st);
    }
  }

  bool _reportPushResult(_PushContext ctx) {
    final orphanInfo = ctx.totalOrphans > 0
        ? ', ${ctx.totalOrphans} orphans cleaned'
        : '';

    Sentry.addBreadcrumb(Breadcrumb(
      message: 'SyncPush completed',
      data: {
        'pushed': ctx.totalPushed,
        'orphansCleaned': ctx.totalOrphans,
        'layerErrors': ctx.layerErrors,
        'success': ctx.layerErrors == 0,
      },
      category: 'sync.push',
      level: ctx.layerErrors > 0 ? SentryLevel.warning : SentryLevel.info,
    ));

    if (ctx.layerErrors > 0) {
      AppLogger.warning(
        '[SyncOrchestrator] Push completed with ${ctx.layerErrors} layer error(s): '
        '${ctx.totalPushed} pushed$orphanInfo',
      );
      return false;
    } else {
      AppLogger.info(
        '[SyncOrchestrator] Push complete: ${ctx.totalPushed} pushed$orphanInfo',
      );
      return true;
    }
  }

  /// Pushes pending records for a specific table.
  Future<void> pushTable(String userId, String table) =>
      _pushSingleTable(_ref, userId, table);
}

/// Accumulates push statistics and failure flags across layers.
class _PushContext {
  int layerErrors = 0;
  int totalPushed = 0;
  int totalOrphans = 0;

  bool l1Failed = false;
  bool l2Failed = false;
  bool l3Failed = false;
  bool l4Failed = false;
  bool l6Failed = false;

  void addResult(PushStats r) {
    totalPushed += r.pushed;
    totalOrphans += r.orphansCleaned;
  }

  void addResults(List<PushStats> results) {
    for (final r in results) {
      addResult(r);
    }
  }
}
