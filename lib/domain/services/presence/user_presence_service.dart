import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/remote/api/user_presence_remote_source.dart';
import 'package:budgie_breeding_tracker/domain/services/presence/user_presence_constants.dart';

class UserPresenceService {
  const UserPresenceService(this._remoteSource);

  final UserPresenceRemoteSource _remoteSource;
  static const _uuid = Uuid();

  Future<String?> startSession(String userId) async {
    if (!_hasMatchingAuthUser(userId)) return null;

    final now = DateTime.now().toUtc();
    final sessionId = _uuid.v7();
    try {
      await _remoteSource.upsertSession({
        SupabaseConstants.colId: sessionId,
        SupabaseConstants.colUserId: userId,
        SupabaseConstants.colPlatform: _platformName(),
        SupabaseConstants.colIsActive: true,
        SupabaseConstants.colLastActiveAt: now.toIso8601String(),
        SupabaseConstants.colExpiresAt: now
            .add(UserPresenceConstants.sessionTtl)
            .toIso8601String(),
      });
      AppLogger.debug(
        '[UserPresence] Session started for ${AppLogger.obfuscate(userId)}',
      );
      return sessionId;
    } catch (e, st) {
      AppLogger.warning('[UserPresence] startSession failed: $e');
      AppLogger.error('[UserPresence] startSession stack', e, st);
      return null;
    }
  }

  Future<void> heartbeat({
    required String userId,
    required String sessionId,
  }) async {
    if (!_hasMatchingAuthUser(userId)) return;

    final now = DateTime.now().toUtc();
    try {
      await _remoteSource.updateSession(
        sessionId: sessionId,
        userId: userId,
        payload: {
          SupabaseConstants.colIsActive: true,
          SupabaseConstants.colLastActiveAt: now.toIso8601String(),
          SupabaseConstants.colExpiresAt: now
              .add(UserPresenceConstants.sessionTtl)
              .toIso8601String(),
        },
      );
    } catch (e, st) {
      AppLogger.warning('[UserPresence] heartbeat failed: $e');
      AppLogger.error('[UserPresence] heartbeat stack', e, st);
    }
  }

  Future<void> endSession({
    required String userId,
    required String sessionId,
  }) async {
    if (!_hasMatchingAuthUser(userId)) return;

    try {
      await _remoteSource.updateSession(
        sessionId: sessionId,
        userId: userId,
        payload: {
          SupabaseConstants.colIsActive: false,
          SupabaseConstants.colLastActiveAt: DateTime.now()
              .toUtc()
              .toIso8601String(),
        },
      );
    } catch (e, st) {
      AppLogger.error('[UserPresence] endSession failed', e, st);
    }
  }

  bool _hasMatchingAuthUser(String userId) {
    final authUserId = _remoteSource.currentAuthUserId;
    if (authUserId == userId) return true;
    AppLogger.warning(
      '[UserPresence] Skipped ownership mismatch for '
      '${AppLogger.obfuscate(userId)}',
    );
    return false;
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'web',
    };
  }
}
