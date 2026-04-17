import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';

/// Shared profile cache for community remote sources.
///
/// Fetches username/avatar_url from the profiles table and caches
/// results for [_ttl] to avoid redundant queries across posts and comments.
/// Large ID sets are chunked to stay within PostgREST URL limits.
class CommunityProfileCache {
  final SupabaseClient _client;
  final _cache = <String, _CachedProfile>{};
  final Duration _ttl;
  final DateTime Function() _now;

  static const _defaultTtl = Duration(minutes: 5);
  static const _chunkSize = 40;

  CommunityProfileCache(this._client) : _ttl = _defaultTtl, _now = _defaultNow;

  @visibleForTesting
  CommunityProfileCache.withClock(this._client, this._now, {Duration? ttl})
    : _ttl = ttl ?? _defaultTtl;

  static DateTime _defaultNow() => DateTime.now();

  /// Removes the cached entry for [userId] so the next lookup re-fetches
  /// from Supabase. Call this after the user updates their profile.
  void invalidate(String userId) {
    _cache.remove(userId);
  }

  /// Clears the entire cache, forcing a full re-fetch on next access.
  void clear() {
    _cache.clear();
  }

  /// Returns a map of userId -> profile data for the given [userIds].
  ///
  /// Cached entries are reused; only expired/unknown IDs hit Supabase.
  Future<Map<String, Map<String, dynamic>>> getProfiles(
    Set<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};

    final now = _now();
    final resolved = <String, Map<String, dynamic>>{};
    final toFetch = <String>[];

    for (final uid in userIds) {
      final cached = _cache[uid];
      if (cached != null && now.difference(cached.fetchedAt) < _ttl) {
        resolved[uid] = cached.data;
      } else {
        toFetch.add(uid);
      }
    }

    if (toFetch.isNotEmpty) {
      try {
        await _fetchAndCache(toFetch, resolved, now);
      } catch (e) {
        AppLogger.warning('CommunityProfileCache: fetch failed: $e');
      }
    }

    return resolved;
  }

  /// Merges profile data into raw rows as top-level `username` and
  /// `avatar_url` fields for direct consumption by [CommunityPost.fromJson].
  Future<List<Map<String, dynamic>>> mergeIntoRows(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return rows;

    final userIds = rows
        .map((r) => r['user_id']?.toString())
        .whereType<String>()
        .toSet();

    final profiles = await getProfiles(userIds);

    return rows.map((row) {
      final userId = row['user_id']?.toString();
      final profile = userId != null ? profiles[userId] : null;
      if (profile != null) {
        return {
          ...row,
          'username': _nonEmpty(profile['full_name']) ??
              _nonEmpty(profile['display_name']) ??
              _emailPrefix(profile['email']) ??
              '',
          'avatar_url': profile['avatar_url'],
        };
      }
      return row;
    }).toList();
  }

  Future<void> _fetchAndCache(
    List<String> ids,
    Map<String, Map<String, dynamic>> resolved,
    DateTime now,
  ) async {
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += _chunkSize) {
      final end = i + _chunkSize;
      chunks.add(ids.sublist(i, end > ids.length ? ids.length : end));
    }

    final results = await Future.wait(
      chunks.map(
        (chunk) => _client
            .from(SupabaseConstants.profilesTable)
            .select('id, display_name, full_name, email, avatar_url')
            .inFilter('id', chunk),
      ),
    );

    for (final profiles in results) {
      for (final p in profiles) {
        final id = p['id']?.toString();
        if (id != null) {
          resolved[id] = p;
          _cache[id] = _CachedProfile(p, now);
        }
      }
    }
  }

  static String? _nonEmpty(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  static String? _emailPrefix(dynamic email) {
    if (email == null) return null;
    final str = email.toString().trim();
    if (str.isEmpty) return null;
    final atIndex = str.indexOf('@');
    return atIndex > 0 ? str.substring(0, atIndex) : null;
  }
}

class _CachedProfile {
  final Map<String, dynamic> data;
  final DateTime fetchedAt;

  const _CachedProfile(this.data, this.fetchedAt);
}
