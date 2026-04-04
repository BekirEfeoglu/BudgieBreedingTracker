import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../data/remote/supabase/edge_function_client.dart';
import '../../auth/providers/auth_providers.dart';
import '../constants/admin_constants.dart';
import 'admin_auth_utils.dart';
import 'admin_models.dart';

export 'admin_capacity_providers.dart';

/// Notifier for admin users list limit (increases on "load more").
class AdminUsersLimitNotifier extends Notifier<int> {
  @override
  int build() => AdminConstants.usersPageSize;
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
/// requireAdmin() is called outside try-catch so permission failures
/// propagate directly without falling through to the fallback.
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  try {
    final result = await client.rpc('admin_get_stats');
    final data = result as Map<String, dynamic>;
    return AdminStats.fromJson(data);
  } catch (e, st) {
    AppLogger.error('adminStatsProvider RPC fallback', e, st);
    // Fallback to client-side queries — safe because:
    // 1. requireAdmin() already verified admin status above (outside try-catch)
    // 2. Supabase RLS policies enforce server-side access control on these tables
    final usersCount = await client
        .from(SupabaseConstants.profilesTable)
        .count();
    final birdsCount = await client.from(SupabaseConstants.birdsTable).count();
    final breedingCount = await client
        .from(SupabaseConstants.breedingPairsTable)
        .count();
    final premiumResult = await client
        .from(SupabaseConstants.profilesTable)
        .select('id')
        .eq('is_premium', true);
    final premiumCount = (premiumResult as List).length;

    final pendingSync = await client
        .from(SupabaseConstants.syncMetadataTable)
        .select('id')
        .eq('status', 'pending');
    final errorSync = await client
        .from(SupabaseConstants.syncMetadataTable)
        .select('id')
        .eq('status', 'error');

    return AdminStats(
      totalUsers: usersCount,
      activeToday: 0,
      newUsersToday: 0,
      totalBirds: birdsCount,
      activeBreedings: breedingCount,
      premiumCount: premiumCount,
      freeCount: usersCount - premiumCount,
      pendingSyncCount: (pendingSync as List).length,
      errorSyncCount: (errorSync as List).length,
    );
  }
});

/// Admin users list provider with server-side filtering via [AdminUsersQuery].
final adminUsersProvider =
    FutureProvider.family<List<AdminUser>, AdminUsersQuery>((
  ref,
  query,
) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  var request = client
      .from(SupabaseConstants.profilesTable)
      .select('id, email, full_name, avatar_url, created_at, is_active, is_premium, role');

  if (query.searchTerm.isNotEmpty) {
    // Sanitize PostgREST special characters to prevent filter injection.
    // Remove control chars and PostgREST delimiters, then escape wildcards
    // and URI-encode to prevent semantic manipulation of the filter string.
    final sanitized = query.searchTerm
        .replaceAll(RegExp(r'[\x00-\x1f]'), '')
        .replaceAll(RegExp(r'[,.()\[\]\\]'), '')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    if (sanitized.isNotEmpty) {
      // Do NOT Uri.encodeComponent — PostgREST client handles encoding.
      request = request.or(
        'email.ilike.%$sanitized%,full_name.ilike.%$sanitized%',
      );
    }
  }

  if (query.isActiveFilter != null) {
    request = request.eq('is_active', query.isActiveFilter!);
  }

  final result = await request
      .order(query.sortField, ascending: query.sortAscending)
      .limit(query.limit);

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

  // Run all 9 independent queries in parallel
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
  final pairsCountFuture = client
      .from(SupabaseConstants.breedingPairsTable)
      .count()
      .eq('user_id', userId);
  final eggsCountFuture = client
      .from(SupabaseConstants.eggsTable)
      .count()
      .eq('user_id', userId);
  final chicksCountFuture = client
      .from(SupabaseConstants.chicksTable)
      .count()
      .eq('user_id', userId);
  final healthRecordsCountFuture = client
      .from(SupabaseConstants.healthRecordsTable)
      .count()
      .eq('user_id', userId);
  final eventsCountFuture = client
      .from(SupabaseConstants.eventsTable)
      .count()
      .eq('user_id', userId);
  final logsFuture = client
      .from(SupabaseConstants.adminLogsTable)
      .select()
      .eq('target_user_id', userId)
      .order('created_at', ascending: false)
      .limit(AdminConstants.userActivityLogsLimit);

  final (
    profile,
    subscriptionRows,
    birdsCount,
    pairsCount,
    eggsCount,
    chicksCount,
    healthRecordsCount,
    eventsCount,
    logsResult,
  ) = await (
    profileFuture,
    subscriptionFuture,
    birdsCountFuture,
    pairsCountFuture,
    eggsCountFuture,
    chicksCountFuture,
    healthRecordsCountFuture,
    eventsCountFuture,
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
    pairsCount: pairsCount,
    eggsCount: eggsCount,
    chicksCount: chicksCount,
    healthRecordsCount: healthRecordsCount,
    eventsCount: eventsCount,
    activityLogs: (logsResult as List)
        .map((l) => AdminLog.fromJson(l as Map<String, dynamic>))
        .toList(),
  );
});

