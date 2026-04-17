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
      final today = DateTime.now().toUtc();
      final startOfDay = DateTime.utc(today.year, today.month, today.day);

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

  /// Fetch entity counts for verified breeder criteria check.
  ///
  /// Uses the `get_entity_counts` RPC to consolidate 4 table queries into a
  /// single round-trip. Falls back to per-table counts if the RPC is missing
  /// (e.g. on a project that hasn't applied the 2026-04-17 migration yet).
  Future<Map<String, int>> fetchEntityCounts(String userId) async {
    try {
      final response = await _client
          .rpc('get_entity_counts', params: {'p_user_id': userId});
      if (response is Map) {
        return {
          'birds': (response['birds'] as num?)?.toInt() ?? 0,
          'breeding_pairs': (response['breeding_pairs'] as num?)?.toInt() ?? 0,
          'chicks': (response['chicks'] as num?)?.toInt() ?? 0,
          'posts': (response['posts'] as num?)?.toInt() ?? 0,
        };
      }
      // Unexpected response shape — fall through to fallback below.
    } catch (e) {
      // Fall through to fallback on RPC errors (e.g. function not yet deployed).
      AppLogger.warning(
        'gamification fetchEntityCounts: RPC failed, using fallback: $e',
      );
    }

    try {
      final results = await Future.wait([
        _client
            .from(SupabaseConstants.birdsTable)
            .select('id')
            .eq('user_id', userId)
            .then((r) => (r as List).length),
        _client
            .from(SupabaseConstants.breedingPairsTable)
            .select('id')
            .eq('user_id', userId)
            .then((r) => (r as List).length),
        _client
            .from(SupabaseConstants.chicksTable)
            .select('id')
            .eq('user_id', userId)
            .then((r) => (r as List).length),
        _client
            .from(SupabaseConstants.communityPostsTable)
            .select('id')
            .eq('user_id', userId)
            .then((r) => (r as List).length),
      ]);
      return {
        'birds': results[0],
        'breeding_pairs': results[1],
        'chicks': results[2],
        'posts': results[3],
      };
    } catch (e, st) {
      AppLogger.error('gamification fetchEntityCounts', e, st);
      return {'birds': 0, 'breeding_pairs': 0, 'chicks': 0, 'posts': 0};
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
