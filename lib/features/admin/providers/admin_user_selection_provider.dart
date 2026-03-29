import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the set of selected user IDs for bulk actions.
class AdminUserSelectionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String userId) {
    state = state.contains(userId)
        ? (Set<String>.of(state)..remove(userId))
        : (Set<String>.of(state)..add(userId));
  }

  void selectAll(List<String> ids) => state = Set<String>.of(ids);
  void clear() => state = const {};
}

final adminUserSelectionProvider =
    NotifierProvider<AdminUserSelectionNotifier, Set<String>>(
  AdminUserSelectionNotifier.new,
);

final isSelectionActiveProvider = Provider<bool>((ref) {
  return ref.watch(adminUserSelectionProvider).isNotEmpty;
});

final selectedUserCountProvider = Provider<int>((ref) {
  return ref.watch(adminUserSelectionProvider).length;
});
