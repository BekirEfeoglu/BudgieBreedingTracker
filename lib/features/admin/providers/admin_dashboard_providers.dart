import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../auth/providers/auth_providers.dart';
import '../constants/admin_constants.dart';
import 'admin_auth_utils.dart';
import 'admin_models.dart';

/// System alerts provider (unresolved alerts).
final adminSystemAlertsProvider = FutureProvider<List<SystemAlert>>((
  ref,
) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  final result = await client
      .from(SupabaseConstants.systemAlertsTable)
      .select()
      .eq('is_active', true)
      .eq('is_acknowledged', false)
      .order('created_at', ascending: false)
      .limit(AdminConstants.maxAlertsLimit);

  return (result as List)
      .map((row) => SystemAlert.fromJson(row as Map<String, dynamic>))
      .toList();
});

/// Pending content review count (posts + comments needing moderation).
final adminPendingReviewCountProvider = FutureProvider<int>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  final postsResult = await client
      .from(SupabaseConstants.communityPostsTable)
      .select('id')
      .eq('is_deleted', false)
      .eq('needs_review', true);

  final commentsResult = await client
      .from(SupabaseConstants.communityCommentsTable)
      .select('id')
      .eq('is_deleted', false)
      .eq('needs_review', true);

  return (postsResult as List).length + (commentsResult as List).length;
});

/// Recent admin actions provider (last [AdminConstants.recentActionsLimit] logs).
final recentAdminActionsProvider = FutureProvider<List<AdminLog>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  final result = await client
      .from(SupabaseConstants.adminLogsTable)
      .select()
      .order('created_at', ascending: false)
      .limit(AdminConstants.recentActionsLimit);

  return (result as List)
      .map((row) => AdminLog.fromJson(row as Map<String, dynamic>))
      .toList();
});

/// System settings provider with metadata per setting.
final adminSystemSettingsProvider =
    FutureProvider<Map<String, Map<String, dynamic>>>((ref) async {
      await requireAdmin(ref);
      final client = ref.watch(supabaseClientProvider);

      final result = await client
          .from(SupabaseConstants.systemSettingsTable)
          .select();

      final settings = <String, Map<String, dynamic>>{};
      for (final row in (result as List)) {
        final key = row['key'] as String;
        settings[key] = {
          'value': row['value'],
          'updated_at': row['updated_at'] as String?,
          'category': row['category'] as String?,
          'updated_by': row['updated_by'] as String?,
        };
      }
      return settings;
    });

/// User growth data for the last 30 days (new registrations per day).
final userGrowthDataProvider = FutureProvider<List<DailyDataPoint>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  final since = DateTime.now().subtract(const Duration(days: AdminConstants.chartPeriodDays));

  final result = await client
      .from(SupabaseConstants.profilesTable)
      .select('created_at')
      .gte('created_at', since.toUtc().toIso8601String())
      .order('created_at');

  final Map<String, int> grouped = {};
  for (final row in (result as List)) {
    final date = DateTime.parse(row['created_at'] as String);
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    grouped[key] = (grouped[key] ?? 0) + 1;
  }

  final points = <DailyDataPoint>[];
  for (var i = AdminConstants.chartPeriodDays - 1; i >= 0; i--) {
    final date = DateTime.now().subtract(Duration(days: i));
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    points.add(DailyDataPoint(date: date, count: grouped[key] ?? 0));
  }
  return points;
});

/// Top users by entity count.
/// Uses RPC for efficiency; falls back to client-side if RPC unavailable.
final topUsersProvider = FutureProvider<List<TopUser>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  try {
    // Try RPC first (single query, server-side aggregation)
    final result = await client.rpc('admin_top_users', params: {
      'p_limit': AdminConstants.topUsersLimit,
    });
    return (result as List).map((row) => TopUser(
      userId: row['user_id'] as String,
      fullName: row['full_name'] as String? ?? '',
      birdsCount: (row['birds_count'] as num?)?.toInt() ?? 0,
      pairsCount: (row['pairs_count'] as num?)?.toInt() ?? 0,
      totalEntities: (row['total_entities'] as num?)?.toInt() ?? 0,
    )).toList();
  } catch (_) {
    // Fallback: fetch counts per user (N+1 but works without RPC)
    final profiles = await client
        .from(SupabaseConstants.profilesTable)
        .select('id, full_name')
        .eq('is_active', true)
        .limit(100);

    final List<TopUser> users = [];
    for (final p in (profiles as List)) {
      final userId = p['id'] as String;
      final birdsCount = await client
          .from(SupabaseConstants.birdsTable)
          .count()
          .eq('user_id', userId)
          .eq('is_deleted', false);
      final pairsCount = await client
          .from(SupabaseConstants.breedingPairsTable)
          .count()
          .eq('user_id', userId)
          .eq('is_deleted', false);
      if (birdsCount > 0 || pairsCount > 0) {
        users.add(TopUser(
          userId: userId,
          fullName: p['full_name'] as String? ?? '',
          birdsCount: birdsCount,
          pairsCount: pairsCount,
          totalEntities: birdsCount + pairsCount,
        ));
      }
    }
    users.sort((a, b) => b.totalEntities.compareTo(a.totalEntities));
    return users.take(AdminConstants.topUsersLimit).toList();
  }
});
