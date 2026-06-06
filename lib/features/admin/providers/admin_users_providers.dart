import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/storage_url_normalizer.dart';
import '../../../data/remote/storage/storage_providers.dart';
import '../../../data/remote/storage/storage_url_resolver.dart';
import '../../../domain/services/presence/user_presence_constants.dart';
import '../../../domain/services/presence/user_presence_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../constants/admin_constants.dart';
import 'admin_auth_utils.dart';
import 'admin_content_models.dart';
import 'admin_models.dart';

part 'admin_user_content_provider.dart';

typedef AdminLocalPresence = ({String userId, DateTime lastActiveAt});

final adminLocalPresenceProvider = Provider<AdminLocalPresence?>((ref) {
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == 'anonymous') return null;

  final presence = ref.watch(userPresenceControllerProvider);
  final lastActiveAt = presence.lastActiveAt;
  if (!presence.isActive ||
      presence.userId != currentUserId ||
      lastActiveAt == null) {
    return null;
  }

  return (userId: currentUserId, lastActiveAt: lastActiveAt);
});

/// Admin users list provider with server-side filtering via [AdminUsersQuery].
final adminUsersProvider = FutureProvider.family<List<AdminUser>, AdminUsersQuery>((
  ref,
  query,
) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  final localPresence = ref.watch(adminLocalPresenceProvider);
  final onlineSince = DateTime.now().toUtc().subtract(
    UserPresenceConstants.onlineThreshold,
  );
  final onlineActivity = query.onlineOnly
      ? await _loadOnlineUserActivity(client, onlineSince)
      : <String, DateTime>{};
  _mergeLocalPresence(onlineActivity, localPresence, onlineSince);

  if (query.onlineOnly && onlineActivity.isEmpty) return [];

  var request = client
      .from(SupabaseConstants.profilesTable)
      .select(
        'id, email, full_name, avatar_url, created_at, is_active, is_premium, role',
      );

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
      final filters = [
        'email.ilike.%$sanitized%',
        'full_name.ilike.%$sanitized%',
        if (_isUuidSearchTerm(sanitized)) 'id.eq.$sanitized',
      ];
      request = request.or(filters.join(','));
    }
  }

  if (query.isActiveFilter != null) {
    request = request.eq('is_active', query.isActiveFilter!);
  }

  if (query.isPremiumFilter != null) {
    request = request.eq('is_premium', query.isPremiumFilter!);
  }

  if (query.onlineOnly) {
    request = request.inFilter('id', onlineActivity.keys.toList());
  }

  // Validate sortField against allowed columns to prevent schema probing
  const allowedSortFields = {
    'created_at',
    'email',
    'full_name',
    'is_active',
    'is_premium',
    'role',
  };
  final sortsByLastActive = query.sortField == 'last_active_at';
  final safeSortField = allowedSortFields.contains(query.sortField)
      ? query.sortField
      : 'created_at';
  final requestLimit = query.onlineOnly && sortsByLastActive
      ? AdminConstants.onlineUsersCandidateLimit
      : query.limit;

  final result = await request
      .order(safeSortField, ascending: query.sortAscending)
      .limit(requestLimit);

  final rows = (result as List).cast<Map<String, dynamic>>();
  final visibleActivity = query.onlineOnly
      ? Map<String, DateTime>.of(onlineActivity)
      : await _loadVisibleUserActivity(
          client,
          rows.map((row) => row['id'] as String),
          onlineSince,
        );
  _mergeLocalPresence(visibleActivity, localPresence, onlineSince);

  final users = rows.map((row) {
    final lastActiveAt = visibleActivity[row['id'] as String];
    return AdminUser.fromJson({
      ...row,
      'avatar_url': StorageUrlNormalizer.normalizePublicObjectUrl(
        row['avatar_url'] as String?,
      ),
      if (lastActiveAt != null)
        'last_active_at': lastActiveAt.toIso8601String(),
    });
  }).toList();

  if (sortsByLastActive) {
    users.sort((a, b) {
      final aValue = a.lastActiveAt;
      final bValue = b.lastActiveAt;
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return query.sortAscending ? -1 : 1;
      if (bValue == null) return query.sortAscending ? 1 : -1;
      return query.sortAscending
          ? aValue.compareTo(bValue)
          : bValue.compareTo(aValue);
    });
  }

  return users.take(query.limit).toList();
});

bool _isUuidSearchTerm(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}

void _mergeLocalPresence(
  Map<String, DateTime> activity,
  AdminLocalPresence? localPresence,
  DateTime onlineSince,
) {
  if (localPresence == null) return;
  final lastActiveAt = localPresence.lastActiveAt.toUtc();
  if (lastActiveAt.isBefore(onlineSince)) return;

  final previous = activity[localPresence.userId];
  if (previous == null || lastActiveAt.isAfter(previous)) {
    activity[localPresence.userId] = lastActiveAt;
  }
}

Future<Map<String, DateTime>> _loadOnlineUserActivity(
  SupabaseClient client,
  DateTime onlineSince,
) async {
  final rows = await client
      .from(SupabaseConstants.userSessionsTable)
      .select('user_id, last_active_at')
      .eq('is_active', true)
      .gte('last_active_at', onlineSince.toIso8601String())
      .order('last_active_at', ascending: false)
      .limit(AdminConstants.onlineUsersCandidateLimit);

  return _latestActivityByUser(rows as List);
}

Future<Map<String, DateTime>> _loadVisibleUserActivity(
  SupabaseClient client,
  Iterable<String> userIds,
  DateTime onlineSince,
) async {
  final ids = userIds.toSet().toList();
  if (ids.isEmpty) return {};

  final rows = await client
      .from(SupabaseConstants.userSessionsTable)
      .select('user_id, last_active_at')
      .eq('is_active', true)
      .gte('last_active_at', onlineSince.toIso8601String())
      .inFilter('user_id', ids)
      .order('last_active_at', ascending: false);

  return _latestActivityByUser(rows as List);
}

Map<String, DateTime> _latestActivityByUser(List<dynamic> rows) {
  final activity = <String, DateTime>{};
  for (final row in rows.cast<Map<String, dynamic>>()) {
    final userId = row['user_id'] as String?;
    final rawLastActive = row['last_active_at'] as String?;
    if (userId == null || rawLastActive == null) continue;
    final lastActive = DateTime.tryParse(rawLastActive);
    if (lastActive == null) continue;

    final previous = activity[userId];
    if (previous == null || lastActive.isAfter(previous)) {
      activity[userId] = lastActive;
    }
  }
  return activity;
}

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
      .eq('is_deleted', false)
      .eq('user_id', userId);
  final pairsCountFuture = client
      .from(SupabaseConstants.breedingPairsTable)
      .count()
      .eq('is_deleted', false)
      .eq('user_id', userId);
  final eggsCountFuture = client
      .from(SupabaseConstants.eggsTable)
      .count()
      .eq('is_deleted', false)
      .eq('user_id', userId);
  final chicksCountFuture = client
      .from(SupabaseConstants.chicksTable)
      .count()
      .eq('is_deleted', false)
      .eq('user_id', userId);
  final healthRecordsCountFuture = client
      .from(SupabaseConstants.healthRecordsTable)
      .count()
      .eq('is_deleted', false)
      .eq('user_id', userId);
  final eventsCountFuture = client
      .from(SupabaseConstants.eventsTable)
      .count()
      .eq('is_deleted', false)
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
  final isRolePremium =
      role == AdminConstants.roleFounder || role == AdminConstants.roleAdmin;
  final isPremium = profile['is_premium'] as bool? ?? false;
  final hasPremiumAccess = isPremium || isRolePremium;
  final subPlan = hasPremiumAccess
      ? AdminConstants.planPremium
      : AdminConstants.planFree;
  final subStatus = isRolePremium
      ? role!
      : (subscription?['status'] as String? ??
            (hasPremiumAccess
                ? AdminConstants.statusActive
                : AdminConstants.statusFree));

  // Subscription updated_at for admin display
  final subUpdatedAtRaw = subscription?['updated_at'] as String?;
  final subUpdatedAt = subUpdatedAtRaw != null
      ? DateTime.tryParse(subUpdatedAtRaw)
      : null;

  return AdminUserDetail(
    id: profile['id'] as String,
    email: profile['email'] as String? ?? '',
    fullName: profile['full_name'] as String?,
    avatarUrl: StorageUrlNormalizer.normalizePublicObjectUrl(
      profile['avatar_url'] as String?,
    ),
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
