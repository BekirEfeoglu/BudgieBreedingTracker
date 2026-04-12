import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';

class ConversationRemoteSource {
  final SupabaseClient _client;

  ConversationRemoteSource(this._client);

  Future<List<Map<String, dynamic>>> fetchConversations(String userId) async {
    try {
      // Get conversation IDs where user is a participant
      final participantRows = await _client
          .from(SupabaseConstants.conversationParticipantsTable)
          .select('conversation_id')
          .eq('user_id', userId)
          .eq('is_left', false);

      final conversationIds = List<String>.from(
        (participantRows as List).map((r) => r['conversation_id'] as String),
      );

      if (conversationIds.isEmpty) return [];

      final response = await _client
          .from(SupabaseConstants.conversationsTable)
          .select()
          .inFilter('id', conversationIds)
          .eq('is_deleted', false)
          .order('last_message_at', ascending: false, nullsFirst: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchById(String id) async {
    try {
      final response = await _client
          .from(SupabaseConstants.conversationsTable)
          .select()
          .eq('id', id)
          .maybeSingle();
      return response;
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from(SupabaseConstants.conversationsTable)
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
      rethrow;
    }
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _client
          .from(SupabaseConstants.conversationsTable)
          .update(data)
          .eq('id', id);
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchParticipants(
    String conversationId,
  ) async {
    try {
      final response = await _client
          .from(SupabaseConstants.conversationParticipantsTable)
          .select()
          .eq('conversation_id', conversationId)
          .eq('is_left', false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
      rethrow;
    }
  }

  Future<void> addParticipant(Map<String, dynamic> data) async {
    try {
      await _client
          .from(SupabaseConstants.conversationParticipantsTable)
          .insert(data);
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
      rethrow;
    }
  }

  Future<void> updateParticipant(
    String conversationId,
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _client
          .from(SupabaseConstants.conversationParticipantsTable)
          .update(data)
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
      rethrow;
    }
  }

  /// Find existing direct conversation between two users
  Future<Map<String, dynamic>?> findDirectConversation(
    String userId1,
    String userId2,
  ) async {
    try {
      // Find conversations where both users are participants and type is direct
      final user1Convos = await _client
          .from(SupabaseConstants.conversationParticipantsTable)
          .select('conversation_id')
          .eq('user_id', userId1)
          .eq('is_left', false);

      final user1ConvoIds = List<String>.from(
        (user1Convos as List).map((r) => r['conversation_id'] as String),
      );

      if (user1ConvoIds.isEmpty) return null;

      // Find direct conversations where user2 is also a participant
      final result = await _client
          .from(SupabaseConstants.conversationsTable)
          .select()
          .inFilter('id', user1ConvoIds)
          .eq('type', 'direct')
          .eq('is_deleted', false)
          .limit(1)
          .maybeSingle();

      if (result == null) return null;

      // Verify user2 is in this conversation
      final user2Check = await _client
          .from(SupabaseConstants.conversationParticipantsTable)
          .select('conversation_id')
          .eq('conversation_id', result['id'])
          .eq('user_id', userId2)
          .eq('is_left', false)
          .maybeSingle();

      return user2Check != null ? result : null;
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
      rethrow;
    }
  }
}
