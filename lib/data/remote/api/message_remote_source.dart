import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';

class MessageRemoteSource {
  final SupabaseClient _client;

  MessageRemoteSource(this._client);

  Future<List<Map<String, dynamic>>> fetchMessages(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      var query = _client
          .from(SupabaseConstants.messagesTable)
          .select()
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false);

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> insert(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from(SupabaseConstants.messagesTable)
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
      rethrow;
    }
  }

  Future<void> markAsRead(String messageId, String userId) async {
    try {
      // Append userId to read_by array if not already present
      await _client.rpc('mark_message_read', params: {
        'p_message_id': messageId,
        'p_user_id': userId,
      });
    } catch (e) {
      AppLogger.warning('Mark as read failed: $e');
    }
  }

  Future<void> softDelete(String id, {required String userId}) async {
    try {
      await _client
          .from(SupabaseConstants.messagesTable)
          .update({'is_deleted': true})
          .eq('id', id)
          .eq('sender_id', userId);
    } catch (e, st) {
      AppLogger.error('messaging', e, st);
      rethrow;
    }
  }

  /// Subscribe to new messages in a conversation via Supabase Realtime
  RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(Map<String, dynamic> payload) onMessage,
  ) {
    final channel = _client.channel('messages:$conversationId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConstants.messagesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            onMessage(payload.newRecord);
          },
        )
        .subscribe();
    return channel;
  }

  /// Subscribe to conversation updates (last message changes)
  RealtimeChannel subscribeToConversationUpdates(
    List<String> conversationIds,
    void Function(Map<String, dynamic> payload) onUpdate,
  ) {
    final channel = _client.channel('conversation-updates');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabaseConstants.conversationsTable,
          callback: (payload) {
            final id = payload.newRecord['id'] as String?;
            if (id != null && conversationIds.contains(id)) {
              onUpdate(payload.newRecord);
            }
          },
        )
        .subscribe();
    return channel;
  }

  /// Unsubscribe from a realtime channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    try {
      await _client.removeChannel(channel);
    } catch (e) {
      AppLogger.warning('Channel unsubscribe failed: $e');
    }
  }
}
