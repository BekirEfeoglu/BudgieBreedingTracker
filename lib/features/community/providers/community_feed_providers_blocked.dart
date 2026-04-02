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

    // Pull from server (merge with local)
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == 'anonymous') return;
      final repo = ref.read(communitySocialRepositoryProvider);
      final serverIds = await repo.fetchBlockedUserIds(userId);
      if (!ref.mounted) return;

      final merged = {...localIds, ...serverIds}.toList();
      await prefs.setStringList(AppPreferences.keyBlockedUserIds, merged);
      state = merged;
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
