import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../data/remote/supabase/edge_function_client.dart';
import '../../auth/providers/auth_providers.dart';
import '../constants/admin_constants.dart';
import 'admin_auth_utils.dart';
import 'admin_models.dart';

export 'admin_capacity_providers.dart';
export 'admin_health_providers.dart';
export 'admin_users_providers.dart';

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
        .eq('role', AdminConstants.roleFounder)
        .maybeSingle();
    return result != null;
  } catch (e, st) {
    AppLogger.error('isFounderProvider', e, st);
    return false;
  }
});

/// Cache of user ID → display name for admin UIs.
final adminUserNameCacheProvider =
    NotifierProvider<AdminUserNameCacheNotifier, Map<String, String>>(
  AdminUserNameCacheNotifier.new,
);

class AdminUserNameCacheNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => {};

  Future<String> resolve(String userId) async {
    if (state.containsKey(userId)) return state[userId]!;

    try {
      final client = ref.read(supabaseClientProvider);
      final result = await client
          .from(SupabaseConstants.profilesTable)
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      final name =
          (result?['full_name'] as String?) ?? '${userId.substring(0, 8)}...';
      state = Map<String, String>.from(state)..[userId] = name;
      return name;
    } catch (e) {
      AppLogger.warning('admin: Failed to resolve user name for $userId: $e');
      final fallback = '${userId.substring(0, 8)}...';
      state = Map<String, String>.from(state)..[userId] = fallback;
      return fallback;
    }
  }
}

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
