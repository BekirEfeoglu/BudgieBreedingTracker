import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';

class FcmTokenRemoteSource {
  const FcmTokenRemoteSource(this._client);

  final SupabaseClient _client;

  Future<void> upsertToken({
    required String userId,
    required String token,
    required String platform,
    String? deviceId,
  }) async {
    try {
      // Verify the userId matches the authenticated user to prevent
      // registering tokens under another user's ID (ownership check).
      final authUserId = _client.auth.currentUser?.id;
      if (authUserId == null || authUserId != userId) {
        throw const NetworkException(
          'FCM token ownership mismatch: userId does not match authenticated user',
        );
      }

      await _client.from(SupabaseConstants.fcmTokensTable).upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': platform,
          'device_id': deviceId,
          'is_active': true,
          'last_used_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'token',
      );
    } catch (e, st) {
      AppLogger.error('[FcmTokenRemoteSource] upsertToken failed', e, st);
      if (e is NetworkException) rethrow;
      throw NetworkException(e.toString(), originalError: e);
    }
  }

  Future<void> deactivateToken(String token) async {
    try {
      await _client.from(SupabaseConstants.fcmTokensTable).update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('token', token);
    } catch (e, st) {
      AppLogger.error('[FcmTokenRemoteSource] deactivateToken failed', e, st);
      throw NetworkException(e.toString(), originalError: e);
    }
  }
}
