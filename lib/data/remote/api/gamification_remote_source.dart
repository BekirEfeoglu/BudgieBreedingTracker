import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';

class GamificationRemoteSource {
  final SupabaseClient _client;

  GamificationRemoteSource(this._client);

  Future<List<Map<String, dynamic>>> fetchBadges() async {
    try {
      final response = await _client
          .from(SupabaseConstants.badgesTable)
          .select()
          .order('sort_order');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      AppLogger.error('gamification', e, st);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserBadges(String userId) async {
    try {
      final response = await _client
          .from(SupabaseConstants.userBadgesTable)
          .select()
          .eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      AppLogger.error('gamification', e, st);
      rethrow;
    }
  }

  Future<void> upsertUserBadge(Map<String, dynamic> data) async {
    try {
      await _client
          .from(SupabaseConstants.userBadgesTable)
          .upsert(data, onConflict: 'user_id,badge_id');
    } catch (e, st) {
      AppLogger.error('gamification', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchUserLevel(String userId) async {
    try {
      final response = await _client
          .from(SupabaseConstants.userLevelsTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e, st) {
      AppLogger.error('gamification', e, st);
      rethrow;
    }
  }

  Future<void> upsertUserLevel(Map<String, dynamic> data) async {
    try {
      await _client
          .from(SupabaseConstants.userLevelsTable)
          .upsert(data, onConflict: 'user_id');
    } catch (e, st) {
      AppLogger.error('gamification', e, st);
      rethrow;
    }
  }

  Future<void> insertXpTransaction(Map<String, dynamic> data) async {
    try {
      await _client
          .from(SupabaseConstants.xpTransactionsTable)
          .insert(data);
    } catch (e, st) {
      AppLogger.error('gamification', e, st);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchXpTransactions(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from(SupabaseConstants.xpTransactionsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      AppLogger.error('gamification', e, st);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboard({int limit = 100}) async {
    try {
      final response = await _client
          .from(SupabaseConstants.userLevelsTable)
          .select()
          .order('total_xp', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      AppLogger.error('gamification', e, st);
      rethrow;
    }
  }

  /// Count today's XP transactions for a specific action (for daily limit check)
  Future<int> fetchDailyActionCount(String userId, String action) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final response = await _client
          .from(SupabaseConstants.xpTransactionsTable)
          .select('id')
          .eq('user_id', userId)
          .eq('action', action)
          .gte('created_at', startOfDay.toIso8601String());
      return (response as List).length;
    } catch (e, st) {
      AppLogger.error('gamification', e, st);
      return 0;
    }
  }

  /// Update profiles table for verified breeder status
  Future<void> updateProfileVerification(
    String userId, {
    required bool isVerified,
    required int level,
    required String title,
  }) async {
    try {
      await _client
          .from(SupabaseConstants.profilesTable)
          .update({
            'is_verified_breeder': isVerified,
            'level': level,
            'xp_title': title,
          })
          .eq('user_id', userId);
    } catch (e, st) {
      AppLogger.error('gamification', e, st);
      rethrow;
    }
  }

  /// Update only level and xp_title in the profile — does NOT touch is_verified_breeder
  Future<void> updateProfileLevelInfo(
    String userId, {
    required int level,
    required String title,
  }) async {
    try {
      await _client
          .from(SupabaseConstants.profilesTable)
          .update({
            'level': level,
            'xp_title': title,
          })
          .eq('user_id', userId);
    } catch (e, st) {
      AppLogger.error('gamification', e, st);
      rethrow;
    }
  }
}
