import 'package:flutter/foundation.dart';

import '../../models/community_post_model.dart';

/// In-memory TTL cache for community posts.
///
/// Caches feed pages and individual post lookups to reduce redundant
/// Supabase requests. Follows the same pattern as [CommunityProfileCache].
/// Write operations (create, delete) invalidate all cached data.
class CommunityPostCache {
  final Duration _ttl;
  final DateTime Function() _now;

  static const _defaultTtl = Duration(minutes: 5);

  final _feedCache = <String, _CachedEntry<List<CommunityPost>>>{};
  final _postCache = <String, _CachedEntry<CommunityPost>>{};

  CommunityPostCache() : _ttl = _defaultTtl, _now = _defaultNow;

  @visibleForTesting
  CommunityPostCache.withClock(this._now, {Duration? ttl})
    : _ttl = ttl ?? _defaultTtl;

  static DateTime _defaultNow() => DateTime.now();

  // ---------------------------------------------------------------------------
  // Feed cache
  // ---------------------------------------------------------------------------

  /// Returns cached feed for [key], or `null` if expired/missing.
  List<CommunityPost>? getFeed(String key) {
    final entry = _feedCache[key];
    if (entry == null) return null;
    if (_now().difference(entry.fetchedAt) >= _ttl) {
      _feedCache.remove(key);
      return null;
    }
    return entry.data;
  }

  /// Stores [posts] under [key] with the current timestamp.
  void putFeed(String key, List<CommunityPost> posts) {
    _feedCache[key] = _CachedEntry(posts, _now());
  }

  // ---------------------------------------------------------------------------
  // Single-post cache
  // ---------------------------------------------------------------------------

  /// Returns cached post for [postId], or `null` if expired/missing.
  CommunityPost? getPost(String postId) {
    final entry = _postCache[postId];
    if (entry == null) return null;
    if (_now().difference(entry.fetchedAt) >= _ttl) {
      _postCache.remove(postId);
      return null;
    }
    return entry.data;
  }

  /// Stores a single [post] by its ID.
  void putPost(CommunityPost post) {
    _postCache[post.id] = _CachedEntry(post, _now());
  }

  // ---------------------------------------------------------------------------
  // Invalidation
  // ---------------------------------------------------------------------------

  /// Clears all cached data. Called on write operations (create, delete).
  void invalidateAll() {
    _feedCache.clear();
    _postCache.clear();
  }

  /// Removes a single post from the post cache.
  void invalidatePost(String postId) {
    _postCache.remove(postId);
    _feedCache.clear();
  }
}

class _CachedEntry<T> {
  final T data;
  final DateTime fetchedAt;

  const _CachedEntry(this.data, this.fetchedAt);
}
