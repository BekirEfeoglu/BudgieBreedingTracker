import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../../../data/models/community_post_model.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import 'community_feed_providers.dart';

// ---------------------------------------------------------------------------
// Search state
// ---------------------------------------------------------------------------

class CommunitySearchState {
  final String query;

  const CommunitySearchState({this.query = ''});

  bool get hasQuery => query.trim().isNotEmpty;

  CommunitySearchState copyWith({String? query}) {
    return CommunitySearchState(query: query ?? this.query);
  }
}

class CommunitySearchNotifier extends Notifier<CommunitySearchState> {
  @override
  CommunitySearchState build() => const CommunitySearchState();

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void clear() {
    state = const CommunitySearchState();
  }
}

final communitySearchProvider =
    NotifierProvider<CommunitySearchNotifier, CommunitySearchState>(
      CommunitySearchNotifier.new,
    );

// ---------------------------------------------------------------------------
// Server-side search results
// ---------------------------------------------------------------------------

final communitySearchResultsProvider =
    FutureProvider.family<List<CommunityPost>, String>((ref, query) async {
      if (query.trim().isEmpty) return [];

      final repo = ref.watch(communityPostRepositoryProvider);
      final userId = ref.watch(currentUserIdProvider);

      try {
        return await repo.search(query: query, currentUserId: userId);
      } catch (e, st) {
        AppLogger.error('communitySearchResultsProvider', e, st);
        return [];
      }
    });

// ---------------------------------------------------------------------------
// Search posts (derived from server-side results)
// ---------------------------------------------------------------------------

final communitySearchPostsProvider = Provider<List<CommunityPost>>((ref) {
  final query = ref.watch(communitySearchProvider).query.trim();
  if (query.isEmpty) return const [];

  final results = ref.watch(communitySearchResultsProvider(query));
  return results.value ?? const [];
});

// ---------------------------------------------------------------------------
// User result model (derived from feed data)
// ---------------------------------------------------------------------------

class CommunitySearchUserResult {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int postCount;
  final int totalLikes;

  const CommunitySearchUserResult({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.postCount,
    required this.totalLikes,
  });

  CommunitySearchUserResult copyWith({int? postCount, int? totalLikes}) {
    return CommunitySearchUserResult(
      userId: userId,
      username: username,
      avatarUrl: avatarUrl,
      postCount: postCount ?? this.postCount,
      totalLikes: totalLikes ?? this.totalLikes,
    );
  }
}

// ---------------------------------------------------------------------------
// Local search (from feed) for users and tags
// ---------------------------------------------------------------------------

final communitySearchUsersProvider = Provider<List<CommunitySearchUserResult>>((
  ref,
) {
  final query = ref.watch(communitySearchProvider).query.trim().toLowerCase();
  final posts = ref.watch(communityFeedProvider).posts;
  final users = _aggregateUsers(posts);

  if (query.isEmpty) return const [];

  return users
      .where((user) => user.username.toLowerCase().contains(query))
      .toList(growable: false);
});

final communitySearchTagsProvider = Provider<List<String>>((ref) {
  final query = ref.watch(communitySearchProvider).query.trim().toLowerCase();
  if (query.isEmpty) return const [];

  final tags = _extractTags(ref.watch(communityFeedProvider).posts);
  return tags
      .where((tag) => tag.toLowerCase().contains(query))
      .toList(growable: false);
});

final communityPopularTagsProvider = Provider<List<String>>((ref) {
  return _extractTags(ref.watch(communityFeedProvider).posts).take(12).toList();
});

final communitySuggestedUsersProvider =
    Provider<List<CommunitySearchUserResult>>((ref) {
      final users =
          _aggregateUsers(ref.watch(communityFeedProvider).posts).toList()
            ..sort((a, b) {
              final byPosts = b.postCount.compareTo(a.postCount);
              if (byPosts != 0) return byPosts;
              return b.totalLikes.compareTo(a.totalLikes);
            });
      return users.take(8).toList(growable: false);
    });

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<String> _extractTags(List<CommunityPost> posts) {
  final counts = <String, int>{};

  for (final post in posts) {
    for (final tag in [...post.tags, ...post.mutationTags]) {
      final normalized = tag.trim();
      if (normalized.isEmpty) continue;
      counts.update(normalized, (value) => value + 1, ifAbsent: () => 1);
    }
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.map((entry) => entry.key).toList(growable: false);
}

List<CommunitySearchUserResult> _aggregateUsers(List<CommunityPost> posts) {
  final users = <String, CommunitySearchUserResult>{};

  for (final post in posts) {
    final existing = users[post.userId];
    if (existing == null) {
      users[post.userId] = CommunitySearchUserResult(
        userId: post.userId,
        username: post.username,
        avatarUrl: post.avatarUrl,
        postCount: 1,
        totalLikes: post.likeCount,
      );
      continue;
    }

    users[post.userId] = existing.copyWith(
      postCount: existing.postCount + 1,
      totalLikes: existing.totalLikes + post.likeCount,
    );
  }

  return users.values.toList(growable: false);
}
