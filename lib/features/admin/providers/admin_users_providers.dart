import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../auth/providers/auth_providers.dart';
import '../constants/admin_constants.dart';
import 'admin_auth_utils.dart';
import 'admin_models.dart';

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
  final isRolePremium = role == AdminConstants.roleFounder || role == AdminConstants.roleAdmin;
  final isPremium = profile['is_premium'] as bool? ?? false;
  final hasPremiumAccess = isPremium || isRolePremium;
  final subPlan = hasPremiumAccess ? AdminConstants.planPremium : AdminConstants.planFree;
  final subStatus = isRolePremium
      ? role!
      : (subscription?['status'] as String? ??
            (hasPremiumAccess ? AdminConstants.statusActive : AdminConstants.statusFree));

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
