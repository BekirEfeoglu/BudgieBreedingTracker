part of 'admin_users_providers.dart';

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
