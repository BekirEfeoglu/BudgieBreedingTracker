import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/message_model.dart';
import '../../../data/repositories/repository_providers.dart';

/// Manages realtime message subscription for active chat
class MessagingRealtimeNotifier extends Notifier<List<Message>> {
  RealtimeChannel? _channel;

  @override
  List<Message> build() {
    ref.onDispose(() {
      _unsubscribe();
    });
    return [];
  }

  void subscribe(String conversationId) {
    _unsubscribe();
    final repo = ref.read(messagingRepositoryProvider);
    _channel = repo.subscribeToMessages(
      conversationId,
      (message) {
        state = [message, ...state];
      },
    );
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
  @override
  Set<String> build() => {};

  void userStartedTyping(String userId) {
    state = {...state, userId};

    // Auto-stop after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (state.contains(userId)) {
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
