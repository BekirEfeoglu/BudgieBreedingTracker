import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/enums/admin_enums.dart';
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
    // Fallback: fetch all birds and pairs, group by user_id client-side
    // Avoids N+1 by fetching two flat lists instead of per-user queries
    final (birdsResult, pairsResult, profilesResult) = await (
      client
          .from(SupabaseConstants.birdsTable)
          .select('user_id')
          .eq('is_deleted', false),
      client
          .from(SupabaseConstants.breedingPairsTable)
          .select('user_id')
          .eq('is_deleted', false),
      client
          .from(SupabaseConstants.profilesTable)
          .select('id, full_name')
          .eq('is_active', true),
    ).wait;

    // Count entities per user
    final birdCounts = <String, int>{};
    for (final row in (birdsResult as List)) {
      final uid = row['user_id'] as String;
      birdCounts[uid] = (birdCounts[uid] ?? 0) + 1;
    }
    final pairCounts = <String, int>{};
    for (final row in (pairsResult as List)) {
      final uid = row['user_id'] as String;
      pairCounts[uid] = (pairCounts[uid] ?? 0) + 1;
    }

    // Build profile lookup
    final profileMap = <String, String>{};
    for (final p in (profilesResult as List)) {
      profileMap[p['id'] as String] = p['full_name'] as String? ?? '';
    }

    // Merge user IDs from both tables
    final allUserIds = {...birdCounts.keys, ...pairCounts.keys};
    final List<TopUser> users = [];
    for (final userId in allUserIds) {
      final bc = birdCounts[userId] ?? 0;
      final pc = pairCounts[userId] ?? 0;
      users.add(TopUser(
        userId: userId,
        fullName: profileMap[userId] ?? '',
        birdsCount: bc,
        pairsCount: pc,
        totalEntities: bc + pc,
      ));
    }
    users.sort((a, b) => b.totalEntities.compareTo(a.totalEntities));
    return users.take(AdminConstants.topUsersLimit).toList();
  }
});

/// Recent user activity in last 24 hours (entity creation grouped by user).
final recentUserActivityProvider = FutureProvider<List<UserActivity>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  final since = DateTime.now().subtract(const Duration(hours: 24)).toUtc().toIso8601String();

  Future<List<Map<String, dynamic>>> fetchRecent(String table) async {
    final result = await client
        .from(table)
        .select('user_id, created_at')
        .gte('created_at', since)
        .eq('is_deleted', false);
    return (result as List).cast<Map<String, dynamic>>();
  }

  final (birds, pairs, eggs, chicks) = await (
    fetchRecent(SupabaseConstants.birdsTable),
    fetchRecent(SupabaseConstants.breedingPairsTable),
    fetchRecent(SupabaseConstants.eggsTable),
    fetchRecent(SupabaseConstants.chicksTable),
  ).wait;

  // Group by user + entity type
  final Map<String, UserActivity> grouped = {};
  void process(List<Map<String, dynamic>> rows, String entityType) {
    for (final row in rows) {
      final userId = row['user_id'] as String;
      final createdAt = DateTime.parse(row['created_at'] as String);
      final key = '$userId:$entityType';
      final existing = grouped[key];
      if (existing != null) {
        grouped[key] = existing.copyWith(
          count: existing.count + 1,
          latestAt: createdAt.isAfter(existing.latestAt) ? createdAt : existing.latestAt,
        );
      } else {
        grouped[key] = UserActivity(
          userId: userId,
          entityType: entityType,
          count: 1,
          latestAt: createdAt,
        );
      }
    }
  }

  process(birds, 'bird');
  process(pairs, 'breeding_pair');
  process(eggs, 'egg');
  process(chicks, 'chick');

  // Enrich with user names
  final userIds = grouped.values.map((a) => a.userId).toSet();
  final profileRows = await client
      .from(SupabaseConstants.profilesTable)
      .select('id, full_name, avatar_url')
      .inFilter('id', userIds.toList());
  final profiles = <String, Map<String, dynamic>>{};
  for (final p in (profileRows as List)) {
    profiles[p['id'] as String] = p as Map<String, dynamic>;
  }

  final activities = grouped.values.map((a) {
    final profile = profiles[a.userId];
    return a.copyWith(
      fullName: profile?['full_name'] as String? ?? '',
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }).toList();

  activities.sort((a, b) => b.latestAt.compareTo(a.latestAt));
  return activities.take(20).toList();
});

/// Error summary for last 24 hours.
final recentErrorsSummaryProvider = FutureProvider<ErrorSummary>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  final since = DateTime.now().subtract(const Duration(hours: 24)).toUtc().toIso8601String();

  final eventsResult = await client
      .from(SupabaseConstants.securityEventsTable)
      .select()
      .gte('created_at', since)
      .order('created_at', ascending: false);

  final events = (eventsResult as List)
      .map((row) => SecurityEvent.fromJson(row as Map<String, dynamic>))
      .toList();

  int high = 0, medium = 0, low = 0;
  for (final e in events) {
    switch (e.severity) {
      case SecuritySeverityLevel.high:
        high++;
      case SecuritySeverityLevel.medium:
        medium++;
      case SecuritySeverityLevel.low:
        low++;
      case SecuritySeverityLevel.unknown:
        low++;
    }
  }

  return ErrorSummary(
    totalErrors: events.length,
    highSeverity: high,
    mediumSeverity: medium,
    lowSeverity: low,
    recentEvents: events.take(3).toList(),
  );
});
