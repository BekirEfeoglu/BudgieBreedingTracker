import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Type of action feedback shown near the bell icon.
enum ActionFeedbackType { success, error, info }

/// A single action feedback item.
class ActionFeedback {
  final String id;
  final String message;
  final ActionFeedbackType type;
  final DateTime createdAt;
  final bool isRead;

  /// Optional route to navigate to when the feedback is tapped.
  final String? actionRoute;

  /// Label for the action (e.g. "Yavrulara Git").
  final String? actionLabel;

  const ActionFeedback({
    required this.id,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.actionRoute,
    this.actionLabel,
  });

  ActionFeedback copyWith({bool? isRead}) => ActionFeedback(
    id: id,
    message: message,
    type: type,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
    actionRoute: actionRoute,
    actionLabel: actionLabel,
  );
}

/// Static service for broadcasting action feedbacks.
///
/// Can be called from anywhere without [WidgetRef] — e.g. from
/// [BuildContext] extensions or domain services.
class ActionFeedbackService {
  ActionFeedbackService._();

  static const _uuid = Uuid();
  static var _controller = StreamController<ActionFeedback>.broadcast(
    sync: true,
  );

  /// Stream of new feedbacks for Riverpod consumption.
  static Stream<ActionFeedback> get stream => _controller.stream;

  /// Whether the stream has any active listeners.
  /// Used by [ContextExtensions.showSnackBar] to fall back to SnackBar
  /// when no bell button is mounted on the current screen.
  static bool get hasListeners => _controller.hasListener;

  /// Resets the stream — old listeners stop receiving events.
  ///
  /// Only intended for test isolation; production code should never call this.
  @visibleForTesting
  static void resetForTesting() {
    if (!_controller.isClosed) {
      _controller.close();
    }
    _controller = StreamController<ActionFeedback>.broadcast(sync: true);
  }

  /// Broadcasts a new action feedback.
  ///
  /// Optionally provide [actionRoute] and [actionLabel] so the feedback
  /// becomes tappable — navigating to [actionRoute] when pressed.
  static void show(
    String message, {
    ActionFeedbackType type = ActionFeedbackType.success,
    String? actionRoute,
    String? actionLabel,
  }) {
    if (_controller.isClosed) return;
    _controller.add(
      ActionFeedback(
        id: _uuid.v7(),
        message: message,
        type: type,
        createdAt: DateTime.now(),
        actionRoute: actionRoute,
        actionLabel: actionLabel,
      ),
    );
  }
}
