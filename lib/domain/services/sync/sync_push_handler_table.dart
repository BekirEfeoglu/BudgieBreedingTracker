part of 'sync_push_handler.dart';

/// Pushes pending records for a specific table via the matching repository.
Future<void> _pushSingleTable(Ref ref, String userId, String table) async {
  try {
    switch (table) {
      case SupabaseConstants.birdsTable:
        await ref.read(birdRepositoryProvider).pushAll(userId);
      case SupabaseConstants.eggsTable:
        await ref.read(eggRepositoryProvider).pushAll(userId);
      case SupabaseConstants.chicksTable:
        await ref.read(chickRepositoryProvider).pushAll(userId);
      case SupabaseConstants.breedingPairsTable:
        await ref.read(breedingPairRepositoryProvider).pushAll(userId);
      case SupabaseConstants.incubationsTable:
        await ref.read(incubationRepositoryProvider).pushAll(userId);
      case SupabaseConstants.healthRecordsTable:
        await ref.read(healthRecordRepositoryProvider).pushAll(userId);
      case SupabaseConstants.growthMeasurementsTable:
        await ref.read(growthMeasurementRepositoryProvider).pushAll(userId);
      case SupabaseConstants.eventsTable:
        await ref.read(eventRepositoryProvider).pushAll(userId);
      case SupabaseConstants.notificationsTable:
        await ref.read(notificationRepositoryProvider).pushAll(userId);
      case SupabaseConstants.clutchesTable:
        await ref.read(clutchRepositoryProvider).pushAll(userId);
      case SupabaseConstants.nestsTable:
        await ref.read(nestRepositoryProvider).pushAll(userId);
      case SupabaseConstants.photosTable:
        await ref.read(photoRepositoryProvider).pushAll(userId);
      case SupabaseConstants.eventRemindersTable:
        await ref.read(eventReminderRepositoryProvider).pushAll(userId);
      case SupabaseConstants.notificationSchedulesTable:
        await ref
            .read(notificationScheduleRepositoryProvider)
            .pushAll(userId);
      case SupabaseConstants.profilesTable:
        await ref.read(profileRepositoryProvider).pushPending(userId);
      default:
        AppLogger.warning(
          '[SyncOrchestrator] Unknown table for retry: $table',
        );
    }
  } catch (e, st) {
    AppLogger.error('[SyncOrchestrator] Retry push failed for $table', e, st);
  }
}

/// Runs push operations in parallel with individual error isolation.
Future<List<PushStats>> _safeParallelPush(
  List<Future<PushStats> Function()> tasks,
  String layerLabel,
) async {
  final results = <PushStats>[];
  final futures = tasks.map((task) async {
    try {
      return await task();
    } catch (e, st) {
      AppLogger.error(
        '[SyncOrchestrator] Push $layerLabel partial failure',
        e,
        st,
      );
      return null;
    }
  });
  final outcomes = await Future.wait(futures);
  for (final r in outcomes) {
    if (r != null) results.add(r);
  }
  return results;
}

/// Checks if any of the given [tables] has pending sync records.
bool _anyPending(Set<String> pendingTables, List<String> tables) {
  return tables.any(pendingTables.contains);
}
