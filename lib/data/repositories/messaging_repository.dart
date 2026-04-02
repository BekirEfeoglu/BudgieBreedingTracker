import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/logger.dart';
import '../models/conversation_model.dart';
import '../models/conversation_participant_model.dart';
import '../models/message_model.dart';
import '../remote/api/conversation_remote_source.dart';
import '../remote/api/message_remote_source.dart';

class MessagingRepository {
  final ConversationRemoteSource _conversationSource;
  final MessageRemoteSource _messageSource;

  const MessagingRepository({
    required ConversationRemoteSource conversationSource,
    required MessageRemoteSource messageSource,
  })  : _conversationSource = conversationSource,
        _messageSource = messageSource;

  Future<List<Conversation>> getConversations(String userId) async {
    final rows = await _conversationSource.fetchConversations(userId);
    return rows.map((r) => Conversation.fromJson(r)).toList();
  }

  Future<Conversation?> getConversationById(String id) async {
    final row = await _conversationSource.fetchById(id);
    if (row == null) return null;
    return Conversation.fromJson(row);
  }

  /// Find existing direct conversation or create a new one
  Future<String> getOrCreateDirectConversation({
    required String userId1,
    required String userId2,
  }) async {
    // Try to find existing
    final existing =
        await _conversationSource.findDirectConversation(userId1, userId2);
    if (existing != null) return existing['id'] as String;

    // Create new
    final conversationId = const Uuid().v4();
    await _conversationSource.create({
      'id': conversationId,
      'type': 'direct',
      'creator_id': userId1,
    });

    // Add both participants
    await _conversationSource.addParticipant({
      'conversation_id': conversationId,
      'user_id': userId1,
      'role': 'owner',
    });
    await _conversationSource.addParticipant({
      'conversation_id': conversationId,
      'user_id': userId2,
      'role': 'member',
    });

    return conversationId;
  }

  /// Create a new group conversation
  Future<String> createGroupConversation({
    required String creatorId,
    required String name,
    required List<String> participantIds,
    String? imageUrl,
  }) async {
    final conversationId = const Uuid().v4();
    await _conversationSource.create({
      'id': conversationId,
      'type': 'group',
      'name': name,
      'creator_id': creatorId,
      if (imageUrl != null) 'image_url': imageUrl,
    });

    // Add creator as owner
    await _conversationSource.addParticipant({
      'conversation_id': conversationId,
      'user_id': creatorId,
      'role': 'owner',
    });

    // Add other participants as members
    for (final userId in participantIds) {
      if (userId == creatorId) continue;
      await _conversationSource.addParticipant({
        'conversation_id': conversationId,
        'user_id': userId,
        'role': 'member',
      });
    }

    return conversationId;
  }

  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  }) async {
    final rows = await _messageSource.fetchMessages(
      conversationId,
      limit: limit,
      before: before,
    );
    return rows.map((r) => Message.fromJson(r)).toList();
  }

  Future<Message> sendMessage(Map<String, dynamic> data) async {
    final row = await _messageSource.insert(data);
    return Message.fromJson(row);
  }

  Future<void> markAsRead(String messageId, String userId) async {
    await _messageSource.markAsRead(messageId, userId);
  }

  Future<void> deleteMessage(String messageId) async {
    await _messageSource.softDelete(messageId);
  }

  Future<List<ConversationParticipant>> getParticipants(
    String conversationId,
  ) async {
    final rows =
        await _conversationSource.fetchParticipants(conversationId);
    return rows.map((r) => ConversationParticipant.fromJson(r)).toList();
  }

  Future<void> addParticipant(
    String conversationId,
    String userId, {
    String role = 'member',
  }) async {
    await _conversationSource.addParticipant({
      'conversation_id': conversationId,
      'user_id': userId,
      'role': role,
    });
  }

  Future<void> leaveConversation(
    String conversationId,
    String userId,
  ) async {
    await _conversationSource.updateParticipant(
      conversationId,
      userId,
      {'is_left': true},
    );
  }

  Future<void> updateParticipantRole(
    String conversationId,
    String userId,
    String role,
  ) async {
    await _conversationSource.updateParticipant(
      conversationId,
      userId,
      {'role': role},
    );
  }

  Future<void> muteConversation(
    String conversationId,
    String userId, {
    required bool muted,
  }) async {
    await _conversationSource.updateParticipant(
      conversationId,
      userId,
      {'is_muted': muted},
    );
  }

  /// Subscribe to new messages — returns channel for cleanup
  RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(Message message) onMessage,
  ) {
    return _messageSource.subscribeToMessages(
      conversationId,
      (payload) {
        try {
          final message = Message.fromJson(payload);
          onMessage(message);
        } catch (e, st) {
          AppLogger.error('messaging', e, st);
        }
      },
    );
  }

  /// Subscribe to conversation updates — returns channel for cleanup
  RealtimeChannel subscribeToConversationUpdates(
    List<String> conversationIds,
    void Function(Conversation conversation) onUpdate,
  ) {
    return _messageSource.subscribeToConversationUpdates(
      conversationIds,
      (payload) {
        try {
          final conversation = Conversation.fromJson(payload);
          onUpdate(conversation);
        } catch (e, st) {
          AppLogger.error('messaging', e, st);
        }
      },
    );
  }

  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _messageSource.unsubscribe(channel);
  }
}
