import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/core/services/action_feedback_service.dart';

export 'package:budgie_breeding_tracker/core/services/action_feedback_service.dart';

/// Accumulates action feedbacks from [ActionFeedbackService.stream].
class ActionFeedbackNotifier extends Notifier<List<ActionFeedback>> {
  @override
  List<ActionFeedback> build() {
    final subscription = ActionFeedbackService.stream.listen((feedback) {
      state = [feedback, ...state];
      if (state.length > 20) {
        state = state.sublist(0, 20);
      }
    });
    ref.onDispose(subscription.cancel);
    return [];
  }

  /// Marks all feedbacks as read — clears the badge.
  void markAllRead() {
    if (!state.any((f) => !f.isRead)) return;
    state = state.map((f) => f.copyWith(isRead: true)).toList();
  }

  /// Removes all feedbacks from the list.
  void clearAll() {
    if (state.isEmpty) return;
    state = [];
  }
}

/// Provider for the action feedback list.
final actionFeedbackProvider =
    NotifierProvider<ActionFeedbackNotifier, List<ActionFeedback>>(
      ActionFeedbackNotifier.new,
    );

/// Derived provider: count of unread action feedbacks.
final unreadFeedbackCountProvider = Provider<int>((ref) {
  return ref.watch(actionFeedbackProvider).where((f) => !f.isRead).length;
});
