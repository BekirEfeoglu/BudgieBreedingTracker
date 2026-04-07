import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SearchOptions;

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import '../constants/admin_constants.dart';
import 'admin_auth_utils.dart';
import 'admin_models.dart';

/// Sync metadata summary (pending + error counts).
final syncStatusSummaryProvider = FutureProvider<SyncStatusSummary>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  try {
    final pendingResult = await client
        .from(SupabaseConstants.syncMetadataTable)
        .select('id, created_at')
        .eq('status', 'pending');
    final errorResult = await client
        .from(SupabaseConstants.syncMetadataTable)
        .select('id')
        .eq('status', 'error');

    final pendingList = pendingResult as List;
    DateTime? oldestPending;
    for (final row in pendingList) {
      final createdAt = DateTime.tryParse(row['created_at'] as String? ?? '');
      if (createdAt != null &&
          (oldestPending == null || createdAt.isBefore(oldestPending))) {
        oldestPending = createdAt;
      }
    }

    return SyncStatusSummary(
      pendingCount: pendingList.length,
      errorCount: (errorResult as List).length,
      oldestPendingAt: oldestPending,
    );
  } catch (e, st) {
    AppLogger.error('syncStatusSummaryProvider', e, st);
    return const SyncStatusSummary();
  }
});

/// Soft-delete statistics per table.
final softDeleteStatsProvider =
    FutureProvider.family<List<SoftDeleteStats>, int>((ref, olderThanDays) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  final cutoff = DateTime.now().subtract(Duration(days: olderThanDays));

  final stats = <SoftDeleteStats>[];
  for (final table in AdminConstants.softDeletableTables) {
    try {
      final allDeleted = await client
          .from(table)
          .select('id')
          .eq('is_deleted', true);
      final olderDeleted = await client
          .from(table)
          .select('id')
          .eq('is_deleted', true)
          .lt('updated_at', cutoff.toUtc().toIso8601String());

      stats.add(SoftDeleteStats(
        tableName: table,
        deletedCount: (allDeleted as List).length,
        olderThanDaysCount: (olderDeleted as List).length,
      ));
    } catch (e) {
      AppLogger.warning('softDeleteStats: Failed for $table: $e');
    }
  }
  return stats;
});

/// Orphan data detection via RPC.
final orphanDataProvider = FutureProvider<OrphanDataSummary>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  try {
    final orphanEggs = await client.rpc('admin_count_orphan_eggs');
    final orphanChicks = await client.rpc('admin_count_orphan_chicks');
    final orphanReminders = await client.rpc('admin_count_orphan_reminders');
    final orphanHealthRecords =
        await client.rpc('admin_count_orphan_health_records');

    return OrphanDataSummary(
      orphanEggs: (orphanEggs as int?) ?? 0,
      orphanChicks: (orphanChicks as int?) ?? 0,
      orphanReminders: (orphanReminders as int?) ?? 0,
      orphanHealthRecords: (orphanHealthRecords as int?) ?? 0,
    );
  } catch (e, st) {
    AppLogger.error('orphanDataProvider', e, st);
    return const OrphanDataSummary();
  }
});

/// Storage bucket usage.
final storageUsageProvider = FutureProvider<List<BucketUsage>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  final usages = <BucketUsage>[];
  for (final bucket in AdminConstants.storageBuckets) {
    try {
      final files = await client.storage.from(bucket).list(
            path: '',
            searchOptions: const SearchOptions(limit: 1000),
          );
      var totalSize = 0;
      for (final file in files) {
        totalSize += file.metadata?['size'] as int? ?? 0;
      }
      usages.add(BucketUsage(
        bucketName: bucket,
        fileCount: files.length,
        totalSizeBytes: totalSize,
      ));
    } catch (e) {
      AppLogger.warning('storageUsage: Failed for $bucket: $e');
      usages.add(BucketUsage(bucketName: bucket));
    }
  }
  return usages;
});
