import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import 'base_remote_source.dart';

class ConversationRemoteSource {
  final SupabaseClient _client;

  ConversationRemoteSource(this._client);

  /// Page size when fetching the conversation list. Caps the result so a
  /// power user with hundreds of conversations doesn't pull them all in
  /// one round trip. Older conversations can be loaded via `before`.
  static const int _conversationsPageLimit = 100;

  Future<List<Map<String, dynamic>>> fetchConversations(
    String userId, {
    int limit = _conversationsPageLimit,
    DateTime? before,
  }) async {
    try {
      // Get conversation IDs where user is a participant
      final participantRows = await _client
          .from(SupabaseConstants.conversationParticipantsTable)
          .select(SupabaseConstants.colConversationId)
          .eq(SupabaseConstants.colUserId, userId)
          .eq(SupabaseConstants.colIsLeft, false);

      final conversationIds = List<String>.from(
        (participantRows as List).map((r) => r['conversation_id'] as String),
      );

      if (conversationIds.isEmpty) return [];

      var query = _client
          .from(SupabaseConstants.conversationsTable)
          .select()
          .inFilter(SupabaseConstants.colId, conversationIds)
          .eq(SupabaseConstants.colIsDeleted, false);
      if (before != null) {
        query = query.lt(
          SupabaseConstants.colLastMessageAt,
          before.toIso8601String(),
        );
      }

      final response = await query
          .order(
            SupabaseConstants.colLastMessageAt,
            ascending: false,
            nullsFirst: false,
          )
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag('conversations', e, st);
    }
  }

  Future<Map<String, dynamic>?> fetchById(String id) async {
    try {
      final response = await _client
          .from(SupabaseConstants.conversationsTable)
          .select()
          .eq(SupabaseConstants.colId, id)
          .maybeSingle();
      return response;
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag('conversations', e, st);
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from(SupabaseConstants.conversationsTable)
          .upsert(
            data,
            onConflict: SupabaseConstants.colId,
            ignoreDuplicates: false,
          )
          .select()
          .single();
      return response;
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag('conversations', e, st);
    }
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    try {
      await _client
          .from(SupabaseConstants.conversationsTable)
          .update(data)
          .eq(SupabaseConstants.colId, id);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag('conversations', e, st);
    }
  }

  Future<List<Map<String, dynamic>>> fetchParticipants(
    String conversationId,
  ) async {
    try {
      final response = await _client
          .from(SupabaseConstants.conversationParticipantsTable)
          .select()
          .eq(SupabaseConstants.colConversationId, conversationId)
          .eq(SupabaseConstants.colIsLeft, false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag('conversations', e, st);
    }
  }

  Future<void> addParticipant(Map<String, dynamic> data) async {
    try {
      await _client
          .from(SupabaseConstants.conversationParticipantsTable)
          .upsert(
            data,
            onConflict: 'conversation_id,user_id',
            ignoreDuplicates: true,
          );
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag('conversations', e, st);
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
          .eq(SupabaseConstants.colConversationId, conversationId)
          .eq(SupabaseConstants.colUserId, userId);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag('conversations', e, st);
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
          .select(SupabaseConstants.colConversationId)
          .eq(SupabaseConstants.colUserId, userId1)
          .eq(SupabaseConstants.colIsLeft, false);

      final user1ConvoIds = List<String>.from(
        (user1Convos as List).map((r) => r['conversation_id'] as String),
      );

      if (user1ConvoIds.isEmpty) return null;

      final directConversations = await _client
          .from(SupabaseConstants.conversationsTable)
          .select()
          .inFilter(SupabaseConstants.colId, user1ConvoIds)
          .eq(SupabaseConstants.colType, 'direct')
          .eq(SupabaseConstants.colIsDeleted, false);

      for (final conversation in List<Map<String, dynamic>>.from(
        directConversations,
      )) {
        final conversationId = conversation['id'] as String?;
        if (conversationId == null) continue;

        final user2Check = await _client
            .from(SupabaseConstants.conversationParticipantsTable)
            .select(SupabaseConstants.colConversationId)
            .eq(SupabaseConstants.colConversationId, conversationId)
            .eq(SupabaseConstants.colUserId, userId2)
            .eq(SupabaseConstants.colIsLeft, false)
            .maybeSingle();

        if (user2Check != null) return conversation;
      }

      return null;
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag('conversations', e, st);
    }
  }
}
