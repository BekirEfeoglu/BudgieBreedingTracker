import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/admin_constants.dart';

/// Manages the set of selected user IDs for bulk actions.
class AdminUserSelectionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String userId) {
    if (state.contains(userId)) {
      state = Set<String>.of(state)..remove(userId);
      return;
    }
    if (state.length >= AdminConstants.maxBulkOperationSize) return;
    state = Set<String>.of(state)..add(userId);
  }

  void selectAll(List<String> ids) {
    state = Set<String>.of(
      Set<String>.of(ids).take(AdminConstants.maxBulkOperationSize),
    );
  }

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
