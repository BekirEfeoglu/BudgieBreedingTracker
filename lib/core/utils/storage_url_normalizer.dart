import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';

/// Normalizes Supabase Storage URLs that point to public image buckets.
///
/// Older app versions persisted signed URLs for public buckets such as avatars
/// and marketplace photos. Those URLs expire and make old images disappear.
/// Private buckets must keep using signed URLs and are resolved by
/// `StorageUrlResolver` at render time.
abstract final class StorageUrlNormalizer {
  static const _publicImageBuckets = {
    SupabaseConstants.avatarsBucket,
    SupabaseConstants.marketplacePhotosBucket,
  };

  static String? normalizePublicObjectUrl(String? url) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return trimmed;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return trimmed;
    }

    final segments = uri.pathSegments;
    final objectIdx = segments.indexOf('object');
    if (objectIdx < 0 || objectIdx + 2 >= segments.length) return trimmed;

    final mode = segments[objectIdx + 1];
    final bucket = segments[objectIdx + 2];
    if (mode != 'sign' || !_publicImageBuckets.contains(bucket)) {
      return trimmed;
    }

    final normalized = Uri(
      scheme: uri.scheme,
      userInfo: uri.userInfo,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      pathSegments: [
        ...segments.take(objectIdx + 1),
        'public',
        bucket,
        ...segments.skip(objectIdx + 3),
      ],
    );
    return normalized.toString();
  }

  static List<String> normalizePublicObjectUrls(Iterable<String> urls) =>
      urls.map(normalizePublicObjectUrl).whereType<String>().toList();

  static StorageObjectPath? extractObjectPath(String? url) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) return null;

    final segments = uri.pathSegments;
    final objectIdx = segments.indexOf('object');
    if (objectIdx < 0 || objectIdx + 3 >= segments.length) return null;

    final mode = segments[objectIdx + 1];
    if (mode != 'sign' && mode != 'public') return null;

    final bucket = segments[objectIdx + 2];
    final path = segments.skip(objectIdx + 3).join('/');
    if (bucket.isEmpty || path.isEmpty) return null;

    return StorageObjectPath(bucket: bucket, path: path);
  }
}

class StorageObjectPath {
  const StorageObjectPath({required this.bucket, required this.path});

  final String bucket;
  final String path;

  String get cacheKey => '$bucket/$path';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageObjectPath &&
          runtimeType == other.runtimeType &&
          bucket == other.bucket &&
          path == other.path;

  @override
  int get hashCode => Object.hash(bucket, path);
}
