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
      request = request.or(
        'email.ilike.%$sanitized%,full_name.ilike.%$sanitized%',
      );
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

/// Full user-generated content preview for admin user detail.
final adminUserContentProvider = FutureProvider.family<AdminUserContent, String>((
  ref,
  userId,
) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  final storageUrlResolver = ref.watch(storageUrlResolverProvider);

  final birdsFuture = client
      .from(SupabaseConstants.birdsTable)
      .select(
        'id, name, gender, status, species, ring_number, cage_number, photo_url, created_at',
      )
      .eq('user_id', userId)
      .eq('is_deleted', false)
      .order('created_at', ascending: false);
  final pairsFuture = client
      .from(SupabaseConstants.breedingPairsTable)
      .select(
        'id, status, male_id, female_id, cage_number, pairing_date, created_at',
      )
      .eq('user_id', userId)
      .eq('is_deleted', false)
      .order('created_at', ascending: false);
  final eggsFuture = client
      .from(SupabaseConstants.eggsTable)
      .select(
        'id, status, egg_number, clutch_id, lay_date, hatch_date, photo_url, created_at',
      )
      .eq('user_id', userId)
      .eq('is_deleted', false)
      .order('created_at', ascending: false);
  final chicksFuture = client
      .from(SupabaseConstants.chicksTable)
      .select(
        'id, name, gender, health_status, ring_number, hatch_date, photo_url, bird_id, created_at',
      )
      .eq('user_id', userId)
      .eq('is_deleted', false)
      .order('created_at', ascending: false);
  final photosFuture = client
      .from(SupabaseConstants.photosTable)
      .select(
        'id, entity_type, entity_id, url, thumbnail_url, is_primary, sort_order, file_size, mime_type, created_at',
      )
      .eq('user_id', userId)
      .eq('is_deleted', false)
      .order('created_at', ascending: false);

  final (
    birdsResult,
    pairsResult,
    eggsResult,
    chicksResult,
    photosResult,
  ) = await (
    birdsFuture,
    pairsFuture,
    eggsFuture,
    chicksFuture,
    photosFuture,
  ).wait;

  final resolvedPhotoEntries = await Future.wait(
    (photosResult as List).cast<Map<String, dynamic>>().map((row) async {
      final rawUrl =
          (row['url'] as String?) ?? (row['thumbnail_url'] as String?);
      final displayUrl =
          (row['thumbnail_url'] as String?) ?? (row['url'] as String?);
      return _ResolvedAdminPhotoEntry(
        id: row['id'] as String,
        entityType: row['entity_type'] as String? ?? 'unknown',
        entityId: row['entity_id'] as String? ?? '',
        fileName: _deriveFileName(rawUrl),
        filePath: await storageUrlResolver.resolve(displayUrl),
        isPrimary: row['is_primary'] as bool? ?? false,
        sortOrder: (row['sort_order'] as num?)?.toInt(),
        createdAt: _parseDate(row['created_at']),
      );
    }),
  );
  resolvedPhotoEntries.sort(_compareResolvedAdminPhotos);
  final fallbackPhotoUrlByEntityId = _fallbackPhotoUrlByEntityId(
    resolvedPhotoEntries,
  );

  final birds = await Future.wait(
    (birdsResult as List).cast<Map<String, dynamic>>().map(
      (row) async => AdminBirdRecord(
        id: row['id'] as String,
        name: row['name'] as String? ?? '',
        gender: row['gender'] as String? ?? 'unknown',
        status: row['status'] as String? ?? 'unknown',
        species: row['species'] as String? ?? 'unknown',
        ringNumber: row['ring_number'] as String?,
        cageNumber: row['cage_number'] as String?,
        photoUrl: await _resolveAdminEntityPhotoUrl(
          storageUrlResolver,
          row['photo_url'] as String?,
          fallbackPhotoUrlByEntityId[row['id'] as String?],
        ),
        createdAt: _parseDate(row['created_at']),
      ),
    ),
  );

  final birdNamesById = <String, String>{
    for (final bird in birds)
      bird.id: bird.name.isNotEmpty ? bird.name : bird.id,
  };

  final eggs = await Future.wait(
    (eggsResult as List).cast<Map<String, dynamic>>().map(
      (row) async => AdminEggRecord(
        id: row['id'] as String,
        status: row['status'] as String? ?? 'unknown',
        eggNumber: (row['egg_number'] as num?)?.toInt(),
        clutchId: row['clutch_id'] as String?,
        layDate:
            _parseDate(row['lay_date']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        hatchDate: _parseDate(row['hatch_date']),
        photoUrl: await _resolveAdminEntityPhotoUrl(
          storageUrlResolver,
          row['photo_url'] as String?,
          fallbackPhotoUrlByEntityId[row['id'] as String?],
        ),
        createdAt: _parseDate(row['created_at']),
      ),
    ),
  );

  final chicks = await Future.wait(
    (chicksResult as List).cast<Map<String, dynamic>>().map(
      (row) async => AdminChickRecord(
        id: row['id'] as String,
        name: row['name'] as String?,
        gender: row['gender'] as String? ?? 'unknown',
        healthStatus: row['health_status'] as String? ?? 'unknown',
        ringNumber: row['ring_number'] as String?,
        hatchDate: _parseDate(row['hatch_date']),
        photoUrl: await _resolveAdminEntityPhotoUrl(
          storageUrlResolver,
          row['photo_url'] as String?,
          fallbackPhotoUrlByEntityId[row['id'] as String?],
        ),
        birdId: row['bird_id'] as String?,
        createdAt: _parseDate(row['created_at']),
      ),
    ),
  );

  final entityLabels = <String, String>{};
  for (final bird in birds) {
    entityLabels[bird.id] = bird.name.isNotEmpty ? bird.name : bird.id;
  }
  for (final egg in eggs) {
    entityLabels[egg.id] = egg.eggNumber != null ? '#${egg.eggNumber}' : egg.id;
  }
  for (final chick in chicks) {
    entityLabels[chick.id] = chick.name?.isNotEmpty == true
        ? chick.name!
        : chick.id;
  }

  final photos = resolvedPhotoEntries
      .map(
        (entry) => AdminPhotoRecord(
          id: entry.id,
          entityType: entry.entityType,
          entityId: entry.entityId,
          fileName: entry.fileName,
          filePath: entry.filePath,
          entityLabel: entityLabels[entry.entityId],
          isPrimary: entry.isPrimary,
          createdAt: entry.createdAt,
        ),
      )
      .toList();

  return AdminUserContent(
    birds: birds,
    pairs: (pairsResult as List)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => AdminBreedingRecord(
            id: row['id'] as String,
            status: row['status'] as String? ?? 'unknown',
            maleId: row['male_id'] as String?,
            maleName: birdNamesById[row['male_id'] as String? ?? ''],
            femaleId: row['female_id'] as String?,
            femaleName: birdNamesById[row['female_id'] as String? ?? ''],
            cageNumber: row['cage_number'] as String?,
            pairingDate: _parseDate(row['pairing_date']),
            createdAt: _parseDate(row['created_at']),
          ),
        )
        .toList(),
    eggs: eggs,
    chicks: chicks,
    photos: photos,
  );
});

DateTime? _parseDate(dynamic raw) {
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

String _deriveFileName(String? url) {
  if (url == null || url.isEmpty) return '';
  final uri = Uri.tryParse(url);
  final segment = uri?.pathSegments.isNotEmpty == true
      ? uri!.pathSegments.last
      : url.split('/').last;
  return segment.isNotEmpty ? segment : url;
}

Future<String?> _resolveAdminEntityPhotoUrl(
  StorageUrlResolver resolver,
  String? rawUrl,
  String? fallbackUrl,
) async {
  final resolved = await resolver.resolve(rawUrl);
  if (resolved?.trim().isNotEmpty == true) return resolved;
  return fallbackUrl;
}

Map<String, String> _fallbackPhotoUrlByEntityId(
  List<_ResolvedAdminPhotoEntry> entries,
) {
  final urls = <String, String>{};
  for (final entry in entries) {
    final filePath = entry.filePath;
    if (entry.entityId.isEmpty || filePath == null || filePath.isEmpty) {
      continue;
    }
    urls.putIfAbsent(entry.entityId, () => filePath);
  }
  return urls;
}

int _compareResolvedAdminPhotos(
  _ResolvedAdminPhotoEntry a,
  _ResolvedAdminPhotoEntry b,
) {
  if (a.isPrimary != b.isPrimary) {
    return a.isPrimary ? -1 : 1;
  }

  final aSortOrder = a.sortOrder;
  final bSortOrder = b.sortOrder;
  if (aSortOrder != null && bSortOrder != null && aSortOrder != bSortOrder) {
    return aSortOrder.compareTo(bSortOrder);
  }
  if (aSortOrder != null && bSortOrder == null) return -1;
  if (aSortOrder == null && bSortOrder != null) return 1;

  final aCreatedAt = a.createdAt;
  final bCreatedAt = b.createdAt;
  if (aCreatedAt == null && bCreatedAt == null) return 0;
  if (aCreatedAt == null) return 1;
  if (bCreatedAt == null) return -1;
  return bCreatedAt.compareTo(aCreatedAt);
}

class _ResolvedAdminPhotoEntry {
  const _ResolvedAdminPhotoEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.fileName,
    required this.isPrimary,
    this.sortOrder,
    this.filePath,
    this.createdAt,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String fileName;
  final bool isPrimary;
  final String? filePath;
  final int? sortOrder;
  final DateTime? createdAt;
}
