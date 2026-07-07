import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../remote/api/remote_source_providers.dart';

/// Fetches a user's public profile information from the community profile cache.
final publicUserProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
      if (userId.isEmpty) return null;
      final cache = ref.watch(communityProfileCacheProvider);
      final profiles = await cache.getProfiles({userId});
      return profiles[userId];
    });
