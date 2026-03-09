import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../data/remote/supabase/edge_function_client.dart';
import '../../auth/providers/auth_providers.dart';
import 'admin_auth_utils.dart';
import 'admin_models.dart';

/// Page size for admin list pagination.
const kAdminPageSize = 50;

/// Notifier for admin users list limit (increases on "load more").
class AdminUsersLimitNotifier extends Notifier<int> {
  @override
  int build() => kAdminPageSize;
}

/// Current limit for admin users list (increases on "load more").
final adminUsersLimitProvider = NotifierProvider<AdminUsersLimitNotifier, int>(
  AdminUsersLimitNotifier.new,
);

/// Edge Function client provider.
final edgeFunctionClientProvider = Provider<EdgeFunctionClient>((ref) {
  return EdgeFunctionClient(ref.watch(supabaseClientProvider));
});

/// System health via Edge Function.
/// Returns 'ok' status when Edge Function is not deployed (404).
final systemHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.watch(edgeFunctionClientProvider);
  final result = await client.checkSystemHealth();
  if (result.success) return result.data ?? {};
  // Edge Function not deployed → treat as unavailable, not as error
  final errorStr = result.error ?? '';
  if (errorStr.contains('404') || errorStr.contains('NOT_FOUND')) {
    return {'status': 'unavailable'};
  }
  return {'status': 'error', 'message': result.error};
});

/// Whether current user is an admin/founder.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final initialized = ref.watch(supabaseInitializedProvider);
  if (!initialized) return false;
  final client = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'anonymous') return false;

  try {
    final result = await client
        .from(SupabaseConstants.adminUsersTable)
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    return result != null;
  } catch (e, st) {
    AppLogger.error('isAdminProvider', e, st);
    return false;
  }
});

/// Whether current user is specifically a founder.
final isFounderProvider = FutureProvider<bool>((ref) async {
  final initialized = ref.watch(supabaseInitializedProvider);
  if (!initialized) return false;
  final client = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'anonymous') return false;

  try {
    final result = await client
        .from(SupabaseConstants.adminUsersTable)
        .select('id')
        .eq('user_id', userId)
        .eq('role', 'founder')
        .maybeSingle();
    return result != null;
  } catch (e, st) {
    AppLogger.error('isFounderProvider', e, st);
    return false;
  }
});

/// Admin dashboard statistics.
/// Uses server-side RPC to bypass RLS and get accurate counts.
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  try {
    final result = await client.rpc('admin_get_stats');
    final data = result as Map<String, dynamic>;
    return AdminStats.fromJson(data);
  } catch (e, st) {
    AppLogger.error('adminStatsProvider RPC fallback', e, st);
    // Fallback to client-side queries
    final usersCount = await client
        .from(SupabaseConstants.profilesTable)
        .count();
    final birdsCount = await client.from(SupabaseConstants.birdsTable).count();
    final breedingCount = await client
        .from(SupabaseConstants.breedingPairsTable)
        .count();
    return AdminStats(
      totalUsers: usersCount,
      activeToday: 0,
      newUsersToday: 0,
      totalBirds: birdsCount,
      activeBreedings: breedingCount,
    );
  }
});

/// Admin users list provider with optional search query.
final adminUsersProvider = FutureProvider.family<List<AdminUser>, String>((
  ref,
  query,
) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  var request = client
      .from(SupabaseConstants.profilesTable)
      .select('id, email, full_name, avatar_url, created_at, is_active');

  if (query.isNotEmpty) {
    // Sanitize PostgREST special characters to prevent filter injection
    final sanitized = query
        .replaceAll(RegExp(r'[,.()\[\]]'), '')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    if (sanitized.isNotEmpty) {
      request = request.or(
        'email.ilike.%$sanitized%,full_name.ilike.%$sanitized%',
      );
    }
  }

  final limit = ref.watch(adminUsersLimitProvider);
  final result = await request
      .order('created_at', ascending: false)
      .limit(limit);

  return (result as List)
      .map((row) => AdminUser.fromJson(row as Map<String, dynamic>))
      .toList();
});

/// Single user detail for admin view.
/// Runs independent queries in parallel for faster loading.
final adminUserDetailProvider = FutureProvider.family<AdminUserDetail, String>((
  ref,
  userId,
) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  // Run all 4 independent queries in parallel
  final profileFuture = client
      .from(SupabaseConstants.profilesTable)
      .select()
      .eq('id', userId)
      .single();
  final subscriptionFuture = client
      .from(SupabaseConstants.userSubscriptionsTable)
      .select()
      .eq('user_id', userId)
      .order('updated_at', ascending: false)
      .limit(1);
  final birdsCountFuture = client
      .from(SupabaseConstants.birdsTable)
      .count()
      .eq('user_id', userId);
  final logsFuture = client
      .from(SupabaseConstants.adminLogsTable)
      .select()
      .eq('target_user_id', userId)
      .order('created_at', ascending: false)
      .limit(20);

  final (profile, subscriptionRows, birdsCount, logsResult) = await (
    profileFuture,
    subscriptionFuture,
    birdsCountFuture,
    logsFuture,
  ).wait;
  final subscription = (subscriptionRows as List).isNotEmpty
      ? subscriptionRows.first
      : null;

  // Role-based access parity with app-level premium logic:
  // founder/admin accounts should be treated as premium in admin UI too.
  final role = (profile['role'] as String?)?.toLowerCase();
  final isRolePremium = role == 'founder' || role == 'admin';
  final isPremium = profile['is_premium'] as bool? ?? false;
  final hasPremiumAccess = isPremium || isRolePremium;
  final subPlan = hasPremiumAccess ? 'premium' : 'free';
  final subStatus = isRolePremium
      ? role!
      : (subscription?['status'] as String? ??
            (hasPremiumAccess ? 'active' : 'free'));

  // Subscription updated_at for admin display
  final subUpdatedAtRaw = subscription?['updated_at'] as String?;
  final subUpdatedAt = subUpdatedAtRaw != null
      ? DateTime.tryParse(subUpdatedAtRaw)
      : null;

  return AdminUserDetail(
    id: profile['id'] as String,
    email: profile['email'] as String? ?? '',
    fullName: profile['full_name'] as String?,
    avatarUrl: profile['avatar_url'] as String?,
    createdAt: DateTime.parse(profile['created_at'] as String),
    isActive: profile['is_active'] as bool? ?? true,
    subscriptionPlan: subPlan,
    subscriptionStatus: subStatus,
    subscriptionUpdatedAt: subUpdatedAt,
    birdsCount: birdsCount,
    activityLogs: (logsResult as List)
        .map((l) => AdminLog.fromJson(l as Map<String, dynamic>))
        .toList(),
  );
});

/// Database table info provider.
/// Uses server-side RPC to bypass RLS and get accurate row counts.
final adminDatabaseInfoProvider = FutureProvider<List<TableInfo>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  try {
    final result = await client.rpc('admin_get_table_counts');
    final rows = result as List;
    return rows.map((row) {
      return TableInfo(
        name: row['table_name'] as String,
        rowCount: (row['row_count'] as num).toInt(),
      );
    }).toList();
  } catch (e, st) {
    AppLogger.error(
      'adminDatabaseInfoProvider RPC failed, using fallback',
      e,
      st,
    );
    // Fallback: try individual count queries for all known tables
    final tables = [
      SupabaseConstants.birdsTable,
      SupabaseConstants.eggsTable,
      SupabaseConstants.chicksTable,
      SupabaseConstants.incubationsTable,
      SupabaseConstants.clutchesTable,
      SupabaseConstants.breedingPairsTable,
      SupabaseConstants.nestsTable,
      SupabaseConstants.healthRecordsTable,
      SupabaseConstants.growthMeasurementsTable,
      SupabaseConstants.profilesTable,
      SupabaseConstants.eventsTable,
      SupabaseConstants.notificationsTable,
      SupabaseConstants.notificationSettingsTable,
      SupabaseConstants.photosTable,
      SupabaseConstants.userSubscriptionsTable,
      SupabaseConstants.adminLogsTable,
      SupabaseConstants.adminUsersTable,
      SupabaseConstants.securityEventsTable,
      SupabaseConstants.systemSettingsTable,
      SupabaseConstants.systemMetricsTable,
      SupabaseConstants.systemStatusTable,
      SupabaseConstants.systemAlertsTable,
      SupabaseConstants.userSessionsTable,
      SupabaseConstants.userPreferencesTable,
      SupabaseConstants.subscriptionPlansTable,
      SupabaseConstants.backupJobsTable,
      SupabaseConstants.eventRemindersTable,
      SupabaseConstants.notificationSchedulesTable,
      SupabaseConstants.feedbackTable,
    ];

    final infos = <TableInfo>[];
    for (final table in tables) {
      try {
        final count = await client.from(table).count();
        infos.add(TableInfo(name: table, rowCount: count));
      } catch (e2, st2) {
        AppLogger.error('adminDatabaseInfoProvider: $table', e2, st2);
        infos.add(TableInfo(name: table, rowCount: -1));
      }
    }
    return infos;
  }
});

/// Capacity threshold above which a Sentry warning is sent (90%).
const _capacityCriticalThreshold = 0.9;

/// Server capacity provider — queries PostgreSQL system catalogs via RPC.
/// Falls back to basic table counts if the RPC function is unavailable.
final serverCapacityProvider = FutureProvider<ServerCapacity>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  try {
    final result = await client.rpc('get_server_capacity');
    final data = result as Map<String, dynamic>;
    final capacity = ServerCapacity.fromJson(data);

    // Sentry alert when capacity exceeds critical threshold
    final dbRatio = capacity.databaseSizeBytes / (500 * 1024 * 1024);
    final connRatio = capacity.connectionUsageRatio;
    final worstRatio = math.max(dbRatio, connRatio);

    if (worstRatio >= _capacityCriticalThreshold) {
      Sentry.captureMessage(
        'Server capacity critical: DB ${(dbRatio * 100).toStringAsFixed(1)}%, '
        'Connections ${(connRatio * 100).toStringAsFixed(1)}%',
        level: SentryLevel.warning,
      );
    }

    return capacity;
  } catch (e, st) {
    AppLogger.error('serverCapacityProvider RPC failed, using fallback', e, st);

    // Fallback: estimate capacity from table counts
    final coreTables = [
      SupabaseConstants.birdsTable,
      SupabaseConstants.eggsTable,
      SupabaseConstants.chicksTable,
      SupabaseConstants.breedingPairsTable,
      SupabaseConstants.profilesTable,
      SupabaseConstants.eventsTable,
      SupabaseConstants.photosTable,
    ];

    var totalRows = 0;
    final tableCapacities = <TableCapacity>[];
    for (final table in coreTables) {
      try {
        final count = await client.from(table).count();
        totalRows += count;
        tableCapacities.add(
          TableCapacity(
            name: table,
            sizeBytes: 0,
            rowCount: count,
            deadTupleCount: 0,
            deadTupleRatio: 0,
          ),
        );
      } catch (_) {
        tableCapacities.add(
          TableCapacity(
            name: table,
            sizeBytes: 0,
            rowCount: -1,
            deadTupleCount: 0,
            deadTupleRatio: 0,
          ),
        );
      }
    }

    return ServerCapacity(
      databaseSizeBytes: 0,
      activeConnections: 0,
      totalConnections: 0,
      maxConnections: 60,
      cacheHitRatio: 0,
      totalRows: totalRows,
      indexHitRatio: 0,
      tables: tableCapacities,
    );
  }
});
