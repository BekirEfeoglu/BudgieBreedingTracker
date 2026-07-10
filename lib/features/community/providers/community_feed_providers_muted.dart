part of 'community_feed_providers.dart';

// ---------------------------------------------------------------------------
// Muted users (SharedPreferences cache + Supabase server sync)
// ---------------------------------------------------------------------------

/// Muted user IDs — loads from local cache first, then syncs with server.
///
/// One-directional, visibility-only: hides a muted user's posts and
/// comments from the muter's own view. Unlike blocking, muting does not
/// affect DMs and is not reciprocal.
class MutedUsersNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    Future.microtask(() => load());
    return [];
  }

  /// Loads muted user IDs from local cache, then syncs from server.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final localIds =
        prefs.getStringList(AppPreferences.keyMutedUserIds) ?? [];
    if (!ref.mounted) return;
    state = localIds;

    // The server is authoritative. Replace (do NOT union) the local cache with
    // the server set so an unmute performed on another device propagates here.
    // A union would re-add server-removed IDs forever, so an unmute could never
    // self-heal across devices. The local cache is only a fast-start snapshot
    // shown before this fetch and a fallback if it fails.
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == 'anonymous') return;
      final repo = ref.read(communitySocialRepositoryProvider);
      final serverIds = await repo.fetchMutedUserIds(userId);
      if (!ref.mounted) return;

      final authoritative = serverIds.toSet().toList();
      await prefs.setStringList(AppPreferences.keyMutedUserIds, authoritative);
      state = authoritative;
    } catch (e) {
      AppLogger.warning('Failed to sync muted users from server: $e');
    }
  }

  /// Mute a user — persists locally and pushes to server.
  Future<void> mute(String mutedUserId) async {
    if (state.contains(mutedUserId)) return;

    final previous = state;

    // Optimistic local update
    final updated = [...state, mutedUserId];
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppPreferences.keyMutedUserIds, updated);

    // Push to server — rollback on failure
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == 'anonymous') return;
      final repo = ref.read(communitySocialRepositoryProvider);
      await repo.muteUser(userId: userId, mutedUserId: mutedUserId);
    } catch (e) {
      AppLogger.warning('Failed to push mute to server, rolling back: $e');
      state = previous;
      await prefs.setStringList(AppPreferences.keyMutedUserIds, previous);
    }
  }

  /// Unmute a user — persists locally and pushes to server.
  Future<void> unmute(String mutedUserId) async {
    final previous = state;

    // Optimistic local update
    final updated = state.where((id) => id != mutedUserId).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppPreferences.keyMutedUserIds, updated);

    // Push to server — rollback on failure
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == 'anonymous') return;
      final repo = ref.read(communitySocialRepositoryProvider);
      await repo.unmuteUser(userId: userId, mutedUserId: mutedUserId);
    } catch (e) {
      AppLogger.warning('Failed to push unmute to server, rolling back: $e');
      state = previous;
      await prefs.setStringList(AppPreferences.keyMutedUserIds, previous);
    }
  }
}

final mutedUsersProvider =
    NotifierProvider<MutedUsersNotifier, List<String>>(
      MutedUsersNotifier.new,
    );
