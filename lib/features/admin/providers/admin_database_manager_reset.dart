part of 'admin_database_manager.dart';

/// FK-safe deletion order: children before parents.
const _deletionOrder = [
  SupabaseConstants.eventRemindersTable,
  SupabaseConstants.notificationSchedulesTable,
  SupabaseConstants.notificationsTable,
  SupabaseConstants.notificationSettingsTable,
  SupabaseConstants.photosTable,
  SupabaseConstants.growthMeasurementsTable,
  SupabaseConstants.healthRecordsTable,
  SupabaseConstants.eventsTable,
  SupabaseConstants.chicksTable,
  SupabaseConstants.eggsTable,
  SupabaseConstants.incubationsTable,
  SupabaseConstants.clutchesTable,
  SupabaseConstants.breedingPairsTable,
  SupabaseConstants.nestsTable,
  SupabaseConstants.birdsTable,
  SupabaseConstants.userPreferencesTable,
  SupabaseConstants.feedbackTable,
];

/// Fetches all rows for [tableName] in chunks to avoid query size limits.
Future<List<Map<String, dynamic>>> _exportTableChunked(
  Ref ref,
  String tableName,
) async {
  final client = ref.read(supabaseClientProvider);
  final allRows = <Map<String, dynamic>>[];
  var offset = 0;

  while (true) {
    final chunk = await client
        .from(tableName)
        .select()
        .range(offset, offset + AdminConstants.exportChunkSize - 1);

    final rows = List<Map<String, dynamic>>.from(chunk);
    allRows.addAll(rows);

    if (rows.length < AdminConstants.exportChunkSize) break;
    offset += AdminConstants.exportChunkSize;

    if (allRows.length >= AdminConstants.maxExportRows) {
      AppLogger.warning(
        'admin: Export truncated at ${AdminConstants.maxExportRows} rows for $tableName',
      );
      break;
    }
  }

  return allRows;
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
