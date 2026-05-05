import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/utils/storage_url_normalizer.dart';

/// Resolves persisted Supabase Storage URLs into currently fetchable URLs.
///
/// Public buckets can use stable public URLs. Private photo buckets need a
/// fresh signed URL because older signed URLs expire and public URLs are not
/// authorized by the bucket policy.
class StorageUrlResolver {
  StorageUrlResolver(this._client, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final SupabaseClient _client;
  final DateTime Function() _now;
  final Map<String, _CachedSignedUrl> _cache = {};

  static const int signedUrlExpirySeconds = 60 * 60 * 24 * 7;
  static const Duration _cacheTtl = Duration(days: 6);

  static const _privatePhotoBuckets = {
    SupabaseConstants.birdPhotosBucket,
    SupabaseConstants.eggPhotosBucket,
    SupabaseConstants.chickPhotosBucket,
  };

  Future<String?> resolve(String? url) async {
    final normalizedPublicUrl = StorageUrlNormalizer.normalizePublicObjectUrl(
      url,
    );
    final objectPath = StorageUrlNormalizer.extractObjectPath(
      normalizedPublicUrl,
    );
    if (objectPath == null ||
        !_privatePhotoBuckets.contains(objectPath.bucket)) {
      return normalizedPublicUrl;
    }

    final cacheKey = objectPath.cacheKey;
    final cached = _cache[cacheKey];
    final now = _now();
    if (cached != null && cached.expiresAt.isAfter(now)) {
      return cached.url;
    }

    try {
      final signedUrl = await _client.storage
          .from(objectPath.bucket)
          .createSignedUrl(objectPath.path, signedUrlExpirySeconds);
      _cache[cacheKey] = _CachedSignedUrl(
        url: signedUrl,
        expiresAt: now.add(_cacheTtl),
      );
      return signedUrl;
    } on StorageException catch (e) {
      AppLogger.warning(
        'Failed to resolve signed storage URL for ${objectPath.bucket}: '
        '${e.message}',
      );
      return normalizedPublicUrl;
    } catch (e, st) {
      AppLogger.warning(
        'Failed to resolve signed storage URL for ${objectPath.bucket}: $e',
      );
      AppLogger.debug('Storage URL resolver stack trace: $st');
      return normalizedPublicUrl;
    }
  }

  Future<List<String>> resolveAll(Iterable<String> urls) async {
    final resolved = await Future.wait(urls.map(resolve));
    return resolved.whereType<String>().toList();
  }
}

class _CachedSignedUrl {
  const _CachedSignedUrl({required this.url, required this.expiresAt});

  final String url;
  final DateTime expiresAt;
}
