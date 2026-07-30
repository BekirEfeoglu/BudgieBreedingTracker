import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/remote/api/user_presence_remote_source.dart';
import 'package:budgie_breeding_tracker/domain/services/presence/user_presence_constants.dart';

typedef AppVersionLoader = Future<String?> Function();

class UserPresenceService {
  UserPresenceService(this._remoteSource, {AppVersionLoader? appVersionLoader})
    : _appVersionLoader = appVersionLoader ?? _loadInstalledAppVersion;

  final UserPresenceRemoteSource _remoteSource;
  final AppVersionLoader _appVersionLoader;
  static const _uuid = Uuid();
  static Future<String?>? _cachedInstalledAppVersion;

  Future<String?> startSession(String userId) async {
    if (!_hasMatchingAuthUser(userId)) return null;

    final now = DateTime.now().toUtc();
    final sessionId = _uuid.v7();
    final appVersion = await _resolveAppVersion();
    try {
      await _remoteSource.upsertSession({
        SupabaseConstants.colId: sessionId,
        SupabaseConstants.colUserId: userId,
        SupabaseConstants.colPlatform: _platformName(),
        if (appVersion != null) SupabaseConstants.colAppVersion: appVersion,
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

  Future<String?> _resolveAppVersion() async {
    try {
      final value = (await _appVersionLoader())?.trim();
      return value == null || value.isEmpty ? null : value;
    } catch (e) {
      // Presence is best-effort. Package metadata failure must not prevent the
      // session heartbeat itself, and is not actionable Sentry noise.
      AppLogger.debug('[UserPresence] App version unavailable: $e');
      return null;
    }
  }

  static Future<String?> _loadInstalledAppVersion() async {
    final cachedVersion = _cachedInstalledAppVersion;
    if (cachedVersion != null) {
      return cachedVersion;
    }

    final loadingVersion = _readInstalledAppVersion();
    _cachedInstalledAppVersion = loadingVersion;
    try {
      return await loadingVersion;
    } catch (_) {
      if (identical(_cachedInstalledAppVersion, loadingVersion)) {
        _cachedInstalledAppVersion = null;
      }
      rethrow;
    }
  }

  static Future<String?> _readInstalledAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    final version = info.version.trim();
    final build = info.buildNumber.trim();
    if (version.isEmpty || build.isEmpty) return null;
    return '$version+$build';
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
