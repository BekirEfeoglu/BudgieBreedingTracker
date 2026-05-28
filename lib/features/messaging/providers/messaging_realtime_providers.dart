import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/services/sync/realtime_sync_service.dart';
import '../../../domain/services/sync/sync_settings_providers.dart';
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
    // Clear any messages still in state from a previous conversation.
    // Without this, opening Chat B after Chat A would render Chat A's
    // messages in B's view (the screen merges this state with the per-
    // conversation message stream).
    state = [];

    // Gate realtime subscribe behind feature flags (feature-flags.md § Sync Runtime Flags):
    // local toggle, server kill switch, and per-user rollout bucket. If any rejects,
    // skip subscribe — UI still works via pull-on-open.
    final userId = ref.read(currentUserIdProvider);
    final enabled = ref.read(syncRealtimeEnabledProvider);
    final killSwitchEnabled = ref.read(syncRealtimeServerKillSwitchProvider);
    final rolloutAllowed =
        !killSwitchEnabled &&
        RealtimeSyncService.isUserInRollout(
          userId: userId,
          percent: ref.read(syncRealtimeRolloutPercentProvider),
        );
    if (!RealtimeSyncService.shouldSubscribe(
      enabled: enabled,
      userId: userId,
      online: true,
      rolloutAllowed: rolloutAllowed,
    )) {
      AppLogger.info(
        '[messaging] realtime subscribe skipped '
        '(flag/kill-switch/rollout gate)',
      );
      return;
    }

    final repo = ref.read(messagingRepositoryProvider);
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

  /// Per-user auto-stop timer. Without per-user cancellation, rapid
  /// successive typing events would stack timers — an earlier 5-second
  /// timer would fire and remove the user from `state` while they were
  /// still actively typing.
  final Map<String, Timer> _autoStopTimers = {};

  @override
  Set<String> build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      for (final timer in _autoStopTimers.values) {
        timer.cancel();
      }
      _autoStopTimers.clear();
    });
    return {};
  }

  void userStartedTyping(String userId) {
    state = {...state, userId};

    // Cancel any pending auto-stop so the freshly-typing user doesn't
    // get cleared by a stale timer.
    _autoStopTimers.remove(userId)?.cancel();

    // Spec: 3s timeout (messaging.md). Was 5s — drifted from rule;
    // audit L3.
    _autoStopTimers[userId] = Timer(const Duration(seconds: 3), () {
      _autoStopTimers.remove(userId);
      if (!_disposed && state.contains(userId)) {
        userStoppedTyping(userId);
      }
    });
  }

  void userStoppedTyping(String userId) {
    _autoStopTimers.remove(userId)?.cancel();
    state = {...state}..remove(userId);
  }

  void clear() {
    for (final timer in _autoStopTimers.values) {
      timer.cancel();
    }
    _autoStopTimers.clear();
    state = {};
  }
}

final typingIndicatorProvider =
    NotifierProvider<TypingIndicatorNotifier, Set<String>>(
      TypingIndicatorNotifier.new,
    );
