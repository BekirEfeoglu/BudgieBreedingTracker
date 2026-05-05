import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/supabase_client.dart';
import 'package:budgie_breeding_tracker/domain/services/presence/user_presence_constants.dart';
import 'package:budgie_breeding_tracker/domain/services/presence/user_presence_service.dart';

class UserPresenceState {
  const UserPresenceState({
    this.userId,
    this.sessionId,
    this.lastActiveAt,
    this.isActive = false,
  });

  final String? userId;
  final String? sessionId;
  final DateTime? lastActiveAt;
  final bool isActive;
}

final userPresenceServiceProvider = Provider<UserPresenceService>((ref) {
  return UserPresenceService(ref.watch(supabaseClientProvider));
});

final userPresenceControllerProvider =
    NotifierProvider<UserPresenceController, UserPresenceState>(
      UserPresenceController.new,
    );

final userPresenceLifecycleProvider = Provider<void>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final controller = ref.read(userPresenceControllerProvider.notifier);

  void schedulePresenceUpdate(Future<void> Function() action) {
    Future<void>.microtask(() {
      if (!ref.mounted) return;
      unawaited(action());
    });
  }

  if (userId == 'anonymous') {
    schedulePresenceUpdate(controller.markInactive);
    return;
  }

  schedulePresenceUpdate(() => controller.markActive(userId));
});

class UserPresenceController extends Notifier<UserPresenceState> {
  Timer? _heartbeatTimer;
  Future<void>? _startFuture;
  String? _startUserId;
  String? _activeUserId;
  String? _activeSessionId;
  int _generation = 0;

  @override
  UserPresenceState build() {
    final service = ref.read(userPresenceServiceProvider);
    ref.onDispose(() {
      _heartbeatTimer?.cancel();
      final userId = _activeUserId;
      final sessionId = _activeSessionId;
      _activeUserId = null;
      _activeSessionId = null;
      if (userId != null && sessionId != null) {
        unawaited(service.endSession(userId: userId, sessionId: sessionId));
      }
    });
    return const UserPresenceState();
  }

  Future<void> markActive(String userId) {
    final pending = _startFuture;
    if (pending != null && _startUserId == userId) return pending;

    final generation = ++_generation;
    final future = _markActive(userId, generation);
    _startFuture = future;
    _startUserId = userId;
    future.whenComplete(() {
      if (_startFuture != future) return;
      _startFuture = null;
      _startUserId = null;
    });
    return future;
  }

  Future<void> _markActive(String userId, int generation) async {
    final current = state;
    if (current.userId == userId &&
        current.sessionId != null &&
        current.isActive) {
      await ref
          .read(userPresenceServiceProvider)
          .heartbeat(userId: userId, sessionId: current.sessionId!);
      if (_generation != generation ||
          ref.read(currentUserIdProvider) != userId) {
        return;
      }
      _setPresenceState(
        UserPresenceState(
          userId: userId,
          sessionId: current.sessionId,
          lastActiveAt: DateTime.now().toUtc(),
          isActive: true,
        ),
      );
      _startHeartbeatTimer(userId, current.sessionId!);
      return;
    }

    await _endCurrentSession();
    if (_generation != generation ||
        ref.read(currentUserIdProvider) != userId) {
      return;
    }

    final service = ref.read(userPresenceServiceProvider);
    final sessionId = await service.startSession(userId);
    if (sessionId == null || sessionId.isEmpty) return;

    if (_generation != generation ||
        ref.read(currentUserIdProvider) != userId) {
      await service.endSession(userId: userId, sessionId: sessionId);
      return;
    }

    _setPresenceState(
      UserPresenceState(
        userId: userId,
        sessionId: sessionId,
        lastActiveAt: DateTime.now().toUtc(),
        isActive: true,
      ),
    );
    _startHeartbeatTimer(userId, sessionId);
  }

  Future<void> markInactive() async {
    _generation++;
    await _endCurrentSession();
  }

  Future<void> _endCurrentSession() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    final current = state;
    _setPresenceState(const UserPresenceState());

    if (current.userId == null || current.sessionId == null) return;
    await ref
        .read(userPresenceServiceProvider)
        .endSession(userId: current.userId!, sessionId: current.sessionId!);
  }

  void _startHeartbeatTimer(String userId, String sessionId) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(UserPresenceConstants.heartbeatInterval, (
      _,
    ) {
      if (state.userId != userId || state.sessionId != sessionId) return;
      _setPresenceState(
        UserPresenceState(
          userId: userId,
          sessionId: sessionId,
          lastActiveAt: DateTime.now().toUtc(),
          isActive: true,
        ),
      );
      unawaited(
        ref
            .read(userPresenceServiceProvider)
            .heartbeat(userId: userId, sessionId: sessionId),
      );
    });
  }

  void _setPresenceState(UserPresenceState next) {
    _activeUserId = next.userId;
    _activeSessionId = next.sessionId;
    state = next;
  }
}
