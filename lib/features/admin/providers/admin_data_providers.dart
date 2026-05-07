import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import '../constants/admin_constants.dart';
import 'admin_auth_utils.dart';
import 'admin_models.dart';

export 'admin_capacity_providers.dart';
export 'admin_health_providers.dart';
export 'admin_users_providers.dart';
export '../../../data/providers/edge_function_provider.dart'
    show edgeFunctionClientProvider;
export '../../../data/providers/user_role_providers.dart'
    show isAdminProvider, isFounderProvider;

/// Notifier for admin users list limit (increases on "load more").
class AdminUsersLimitNotifier extends Notifier<int> {
  @override
  int build() => AdminConstants.usersPageSize;
}

/// Current limit for admin users list (increases on "load more").
final adminUsersLimitProvider = NotifierProvider<AdminUsersLimitNotifier, int>(
  AdminUsersLimitNotifier.new,
);

/// Cache of user ID to display name for admin UIs.
final adminUserNameCacheProvider =
    NotifierProvider<AdminUserNameCacheNotifier, Map<String, String>>(
      AdminUserNameCacheNotifier.new,
    );

class AdminUserNameCacheNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => {};

  Future<String> resolve(String userId) async {
    final cached = state[userId];
    if (cached != null) return cached;

    try {
      final client = ref.read(supabaseClientProvider);
      final result = await client
          .from(SupabaseConstants.profilesTable)
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      final fullName = result?['full_name'] as String?;
      final fallback = _shortUserId(userId);
      final name = fullName?.trim().isNotEmpty == true
          ? fullName!.trim()
          : fallback;
      state = Map<String, String>.from(state)..[userId] = name;
      return name;
    } catch (e, st) {
      AppLogger.error('AdminUserNameCacheNotifier.resolve', e, st);
      final fallback = _shortUserId(userId);
      state = Map<String, String>.from(state)..[userId] = fallback;
      return fallback;
    }
  }

  String _shortUserId(String userId) =>
      userId.length <= 8 ? userId : '${userId.substring(0, 8)}...';
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
    Sentry.captureException(
      e,
      stackTrace: st,
      withScope: (scope) {
        scope.setTag('feature', 'admin_dashboard');
        scope.setTag('provider', 'adminStatsProvider');
        scope.setContexts('admin_stats', {
          'stage': 'rpc',
          'rpc_name': 'admin_get_stats',
        });
      },
    );
    Future<int> safeCount(String table, {bool excludeDeleted = false}) async {
      try {
        var query = client.from(table).count();
        if (excludeDeleted) {
          query = query.eq('is_deleted', false);
        }
        return await query;
      } catch (inner, innerSt) {
        AppLogger.warning(
          '[adminStatsProvider] count fallback failed for $table: $inner',
        );
        AppLogger.debug(innerSt.toString());
        Sentry.captureException(
          inner,
          stackTrace: innerSt,
          withScope: (scope) {
            scope.setTag('feature', 'admin_dashboard');
            scope.setTag('provider', 'adminStatsProvider');
            scope.setContexts('admin_stats', {
              'stage': 'fallback_count',
              'table': table,
              'exclude_deleted': excludeDeleted,
            });
          },
        );
        return 0;
      }
    }

    Future<int> safeSelectLength(
      String table, {
      required String column,
      required Object value,
      bool excludeDeleted = false,
    }) async {
      try {
        var query = client.from(table).select('id').eq(column, value);
        if (excludeDeleted) {
          query = query.eq('is_deleted', false);
        }
        final result = await query;
        return (result as List).length;
      } catch (inner, innerSt) {
        AppLogger.warning(
          '[adminStatsProvider] select fallback failed for $table.$column=$value: $inner',
        );
        AppLogger.debug(innerSt.toString());
        Sentry.captureException(
          inner,
          stackTrace: innerSt,
          withScope: (scope) {
            scope.setTag('feature', 'admin_dashboard');
            scope.setTag('provider', 'adminStatsProvider');
            scope.setContexts('admin_stats', {
              'stage': 'fallback_select',
              'table': table,
              'column': column,
              'value': value.toString(),
              'exclude_deleted': excludeDeleted,
            });
          },
        );
        return 0;
      }
    }

    final usersCount = await safeCount(SupabaseConstants.profilesTable);
    final birdsCount = await safeCount(
      SupabaseConstants.birdsTable,
      excludeDeleted: true,
    );
    final breedingCount = await safeCount(
      SupabaseConstants.breedingPairsTable,
      excludeDeleted: true,
    );
    final premiumCount = await safeSelectLength(
      SupabaseConstants.profilesTable,
      column: 'is_premium',
      value: true,
    );
    final pendingSyncCount = await safeSelectLength(
      SupabaseConstants.syncMetadataTable,
      column: 'status',
      value: 'pending',
    );
    final errorSyncCount = await safeSelectLength(
      SupabaseConstants.syncMetadataTable,
      column: 'status',
      value: 'error',
    );

    return AdminStats(
      totalUsers: usersCount,
      activeToday: 0,
      newUsersToday: 0,
      totalBirds: birdsCount,
      activeBreedings: breedingCount,
      premiumCount: premiumCount,
      freeCount: usersCount - premiumCount,
      pendingSyncCount: pendingSyncCount,
      errorSyncCount: errorSyncCount,
    );
  }
});
