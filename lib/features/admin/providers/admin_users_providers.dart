import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../auth/providers/auth_providers.dart';
import '../constants/admin_constants.dart';
import 'admin_auth_utils.dart';
import 'admin_models.dart';

/// Admin users list provider with server-side filtering via [AdminUsersQuery].
final adminUsersProvider = FutureProvider.family<List<AdminUser>, AdminUsersQuery>((
  ref,
  query,
) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

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

  // Validate sortField against allowed columns to prevent schema probing
  const allowedSortFields = {'created_at', 'email', 'full_name', 'is_active', 'is_premium', 'role'};
  final safeSortField = allowedSortFields.contains(query.sortField)
      ? query.sortField
      : 'created_at';

  final result = await request
      .order(safeSortField, ascending: query.sortAscending)
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

/// Full user-generated content preview for admin user detail.
final adminUserContentProvider = FutureProvider.family<AdminUserContent, String>((
  ref,
  userId,
) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

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
        'id, entity_type, entity_id, url, thumbnail_url, file_size, mime_type, created_at',
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

  final birds = (birdsResult as List)
      .cast<Map<String, dynamic>>()
      .map(
        (row) => AdminBirdRecord(
          id: row['id'] as String,
          name: row['name'] as String? ?? '',
          gender: row['gender'] as String? ?? 'unknown',
          status: row['status'] as String? ?? 'unknown',
          species: row['species'] as String? ?? 'unknown',
          ringNumber: row['ring_number'] as String?,
          cageNumber: row['cage_number'] as String?,
          photoUrl: row['photo_url'] as String?,
          createdAt: _parseDate(row['created_at']),
        ),
      )
      .toList();

  final birdNamesById = <String, String>{
    for (final bird in birds)
      bird.id: bird.name.isNotEmpty ? bird.name : bird.id,
  };

  final eggs = (eggsResult as List)
      .cast<Map<String, dynamic>>()
      .map(
        (row) => AdminEggRecord(
          id: row['id'] as String,
          status: row['status'] as String? ?? 'unknown',
          eggNumber: (row['egg_number'] as num?)?.toInt(),
          clutchId: row['clutch_id'] as String?,
          layDate:
              _parseDate(row['lay_date']) ??
              DateTime.fromMillisecondsSinceEpoch(0),
          hatchDate: _parseDate(row['hatch_date']),
          photoUrl: row['photo_url'] as String?,
          createdAt: _parseDate(row['created_at']),
        ),
      )
      .toList();

  final chicks = (chicksResult as List)
      .cast<Map<String, dynamic>>()
      .map(
        (row) => AdminChickRecord(
          id: row['id'] as String,
          name: row['name'] as String?,
          gender: row['gender'] as String? ?? 'unknown',
          healthStatus: row['health_status'] as String? ?? 'unknown',
          ringNumber: row['ring_number'] as String?,
          hatchDate: _parseDate(row['hatch_date']),
          photoUrl: row['photo_url'] as String?,
          birdId: row['bird_id'] as String?,
          createdAt: _parseDate(row['created_at']),
        ),
      )
      .toList();

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
    photos: (photosResult as List)
        .cast<Map<String, dynamic>>()
        .map(
          (row) => AdminPhotoRecord(
            id: row['id'] as String,
            entityType: row['entity_type'] as String? ?? 'unknown',
            entityId: row['entity_id'] as String? ?? '',
            fileName: _deriveFileName(
              (row['url'] as String?) ?? (row['thumbnail_url'] as String?),
            ),
            filePath:
                (row['thumbnail_url'] as String?) ?? (row['url'] as String?),
            entityLabel: entityLabels[row['entity_id'] as String? ?? ''],
            isPrimary: false,
            createdAt: _parseDate(row['created_at']),
          ),
        )
        .toList(),
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
