import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/message_model.dart';
import '../../../data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';

/// Manages realtime message subscription for active chat
class MessagingRealtimeNotifier extends Notifier<List<Message>> {
  Object? _channel;

  @override
  List<Message> build() {
    ref.onDispose(() {
      _unsubscribe();
    });
    return [];
  }

  Future<void> subscribe(String conversationId) async {
    _unsubscribe();
    final repo = ref.read(messagingRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    _channel = await repo.subscribeToMessages(conversationId, userId, (
      message,
    ) {
      state = [message, ...state];
    });
  }

  void _unsubscribe() {
    if (_channel != null) {
      final repo = ref.read(messagingRepositoryProvider);
      repo.unsubscribe(_channel!);
      _channel = null;
    }
  }

  void addLocalMessage(Message message) {
    state = [message, ...state];
  }

  void clear() {
    _unsubscribe();
    state = [];
  }
}

final messagingRealtimeProvider =
    NotifierProvider<MessagingRealtimeNotifier, List<Message>>(
      MessagingRealtimeNotifier.new,
    );

/// Typing indicator state
class TypingIndicatorNotifier extends Notifier<Set<String>> {
  bool _disposed = false;

  @override
  Set<String> build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
    });
    return {};
  }

  void userStartedTyping(String userId) {
    state = {...state, userId};

    // Auto-stop after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (!_disposed && state.contains(userId)) {
        userStoppedTyping(userId);
      }
    });
  }

  void userStoppedTyping(String userId) {
    state = {...state}..remove(userId);
  }

  void clear() {
    state = {};
  }
}

final typingIndicatorProvider =
    NotifierProvider<TypingIndicatorNotifier, Set<String>>(
      TypingIndicatorNotifier.new,
    );
