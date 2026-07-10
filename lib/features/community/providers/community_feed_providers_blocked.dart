part of 'community_feed_providers.dart';

// ---------------------------------------------------------------------------
// Blocked users (SharedPreferences cache + Supabase server sync)
// ---------------------------------------------------------------------------

/// Blocked user IDs — loads from local cache first, then syncs with server.
class BlockedUsersNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    Future.microtask(() => load());
    return [];
  }

  /// Loads blocked user IDs from local cache, then syncs from server.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final localIds =
        prefs.getStringList(AppPreferences.keyBlockedUserIds) ?? [];
    if (!ref.mounted) return;
    state = localIds;

    // The server is authoritative. Replace (do NOT union) the local cache with
    // the server set so an unblock performed on another device propagates here.
    // A union would re-add server-removed IDs forever, so an unblock could never
    // self-heal across devices. The local cache is only a fast-start snapshot
    // shown before this fetch and a fallback if it fails.
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == 'anonymous') return;
      final repo = ref.read(communitySocialRepositoryProvider);
      final serverIds = await repo.fetchBlockedUserIds(userId);
      if (!ref.mounted) return;

      final authoritative = serverIds.toSet().toList();
      await prefs.setStringList(
        AppPreferences.keyBlockedUserIds,
        authoritative,
      );
      state = authoritative;
    } catch (e) {
      AppLogger.warning('Failed to sync blocked users from server: $e');
    }
  }

  /// Block a user — persists locally and pushes to server.
  Future<void> block(String blockedUserId) async {
    if (state.contains(blockedUserId)) return;

    final previous = state;

    // Optimistic local update
    final updated = [...state, blockedUserId];
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppPreferences.keyBlockedUserIds, updated);

    // Push to server — rollback on failure
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == 'anonymous') return;
      final repo = ref.read(communitySocialRepositoryProvider);
      await repo.blockUser(userId: userId, blockedUserId: blockedUserId);
    } catch (e) {
      AppLogger.warning('Failed to push block to server, rolling back: $e');
      state = previous;
      await prefs.setStringList(AppPreferences.keyBlockedUserIds, previous);
    }
  }

  /// Unblock a user — persists locally and pushes to server.
  Future<void> unblock(String blockedUserId) async {
    final previous = state;

    // Optimistic local update
    final updated = state.where((id) => id != blockedUserId).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppPreferences.keyBlockedUserIds, updated);

    // Push to server — rollback on failure
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == 'anonymous') return;
      final repo = ref.read(communitySocialRepositoryProvider);
      await repo.unblockUser(userId: userId, blockedUserId: blockedUserId);
    } catch (e) {
      AppLogger.warning('Failed to push unblock to server, rolling back: $e');
      state = previous;
      await prefs.setStringList(AppPreferences.keyBlockedUserIds, previous);
    }
  }
}

final blockedUsersProvider =
    NotifierProvider<BlockedUsersNotifier, List<String>>(
      BlockedUsersNotifier.new,
    );
