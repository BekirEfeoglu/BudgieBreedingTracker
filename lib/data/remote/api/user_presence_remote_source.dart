import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';

/// Online-only remote source for `user_sessions` heartbeat writes.
///
/// Not a [BaseRemoteSource] subclass: presence rows are transient key-value
/// writes with no offline mirror, sync lifecycle, or Freezed domain model —
/// a single-user remote-only resource (architecture.md § Online-First
/// Exemption), not a synced entity.
class UserPresenceRemoteSource {
  const UserPresenceRemoteSource(this._client);

  final SupabaseClient _client;

  /// The currently authenticated Supabase user id, or `null` if signed out.
  String? get currentAuthUserId => _client.auth.currentUser?.id;

  Future<void> upsertSession(Map<String, dynamic> payload) {
    return _client.from(SupabaseConstants.userSessionsTable).upsert(payload);
  }

  Future<void> updateSession({
    required String sessionId,
    required String userId,
    required Map<String, dynamic> payload,
  }) {
    return _client
        .from(SupabaseConstants.userSessionsTable)
        .update(payload)
        .eq(SupabaseConstants.colId, sessionId)
        .eq(SupabaseConstants.colUserId, userId);
  }
}
