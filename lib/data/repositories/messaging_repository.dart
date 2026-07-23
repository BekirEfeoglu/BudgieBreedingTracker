import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/supabase_constants.dart';
import '../../core/enums/messaging_enums.dart';
import '../../core/utils/logger.dart';
import '../models/conversation_model.dart';
import '../models/conversation_participant_model.dart';
import '../models/message_model.dart';
import '../remote/api/conversation_remote_source.dart';
import '../remote/api/message_remote_source.dart';
import '../remote/storage/storage_service.dart';
import '../remote/storage/storage_url_resolver.dart';

/// Online-first: realtime multi-party conversations. No local Drift mirror by design.
///
/// Exempt from offline-first naming (see `.claude/rules/architecture.md`
/// § Online-First Exemption). Custom implementation (does not extend
/// [BaseRepository]) because messages live only on Supabase with realtime
/// subscriptions and cross user boundaries.
class MessagingRepository {
  final ConversationRemoteSource _conversationSource;
  final MessageRemoteSource _messageSource;
  final SupabaseClient _client;
  final StorageService? _storageService;
  final StorageUrlResolver? _storageUrlResolver;

  const MessagingRepository({
    required ConversationRemoteSource conversationSource,
    required MessageRemoteSource messageSource,
    required SupabaseClient client,
    StorageService? storageService,
    StorageUrlResolver? storageUrlResolver,
  }) : _conversationSource = conversationSource,
       _messageSource = messageSource,
       _client = client,
       _storageService = storageService,
       _storageUrlResolver = storageUrlResolver;

  /// Search profiles by display_name or full_name for DM user picker.
  ///
  /// Uses [_client] directly because messaging is online-first with no
  /// dedicated profile remote source — profiles are a cross-cutting concern
  /// not owned by the messaging domain.
  Future<List<Map<String, dynamic>>> searchProfiles(
    String query, {
    required String excludeUserId,
    int limit = 20,
  }) async {
    final sanitized = query
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .replaceAll(RegExp(r'''[\\%_,.()"';`]'''), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (sanitized.isEmpty) return [];

    final result = await _client
        .from(SupabaseConstants.profilesTable)
        .select(
          '${SupabaseConstants.colId}, ${SupabaseConstants.colDisplayName}, '
          '${SupabaseConstants.colFullName}, ${SupabaseConstants.colAvatarUrl}',
        )
        .or(
          '${SupabaseConstants.colDisplayName}.ilike.%$sanitized%,'
          '${SupabaseConstants.colFullName}.ilike.%$sanitized%',
        )
        .neq(SupabaseConstants.colId, excludeUserId)
        .limit(limit);

    return List<Map<String, dynamic>>.from(result);
  }

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
    final existing = await _conversationSource.findDirectConversation(
      userId1,
      userId2,
    );
    if (existing != null) return existing['id'] as String;

    // Create new — if race condition, retry find
    try {
      final conversationId = const Uuid().v7();
      await _conversationSource.create({
        SupabaseConstants.colId: conversationId,
        'type': 'direct',
        'creator_id': userId1,
      });

      // Add both participants
      await _conversationSource.addParticipant({
        'conversation_id': conversationId,
        SupabaseConstants.colUserId: userId1,
        SupabaseConstants.colRole: 'owner',
      });
      await _conversationSource.addParticipant({
        'conversation_id': conversationId,
        SupabaseConstants.colUserId: userId2,
        SupabaseConstants.colRole: 'member',
      });

      return conversationId;
    } catch (e, st) {
      // Race condition: another request may have created it — retry find
      AppLogger.warning(
        'messaging: Direct conversation create failed, retrying lookup: $e',
      );
      AppLogger.debug('messaging: direct conversation retry stack: $st');
      final retryFind = await _conversationSource.findDirectConversation(
        userId1,
        userId2,
      );
      if (retryFind != null) return retryFind['id'] as String;
      rethrow;
    }
  }

  /// Create a new group conversation
  Future<String> createGroupConversation({
    required String creatorId,
    required String name,
    required List<String> participantIds,
    String? imageUrl,
  }) async {
    final conversationId = const Uuid().v7();
    await _conversationSource.create({
      SupabaseConstants.colId: conversationId,
      'type': 'group',
      SupabaseConstants.colName: name,
      'creator_id': creatorId,
      if (imageUrl != null) 'image_url': imageUrl,
    });

    // Add creator as owner
    await _conversationSource.addParticipant({
      'conversation_id': conversationId,
      SupabaseConstants.colUserId: creatorId,
      SupabaseConstants.colRole: 'owner',
    });

    // Add other participants as members
    for (final userId in participantIds) {
      if (userId == creatorId) continue;
      await _conversationSource.addParticipant({
        'conversation_id': conversationId,
        SupabaseConstants.colUserId: userId,
        SupabaseConstants.colRole: 'member',
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
    final messages = rows.map((r) => Message.fromJson(r)).toList();
    final resolver = _storageUrlResolver;
    if (resolver == null) return messages;
    return Future.wait(
      messages.map((message) => _resolveMessageImageUrl(message, resolver)),
    );
  }

  Future<Message> sendMessage(Map<String, dynamic> data) async {
    final row = await _messageSource.insert(data);
    return Message.fromJson(row);
  }

  Future<String> uploadMessagePhoto({
    required String userId,
    required String conversationId,
    required XFile file,
  }) {
    final storageService = _storageService;
    if (storageService == null) {
      throw StateError('Message photo upload requires StorageService');
    }
    return storageService.uploadMessagePhoto(
      userId: userId,
      conversationId: conversationId,
      file: file,
    );
  }

  Future<Message> _resolveMessageImageUrl(
    Message message,
    StorageUrlResolver resolver,
  ) async {
    if (message.messageType != MessageType.image || message.imageUrl == null) {
      return message;
    }
    final resolved = await resolver.resolve(message.imageUrl);
    if (resolved == null || resolved == message.imageUrl) return message;
    return message.copyWith(imageUrl: resolved);
  }

  Future<void> markAsRead(String messageId, String userId) async {
    await _messageSource.markAsRead(messageId, userId);
  }

  Future<void> deleteMessage(String messageId, {required String userId}) async {
    await _messageSource.softDelete(messageId, userId: userId);
  }

  Future<List<ConversationParticipant>> getParticipants(
    String conversationId,
  ) async {
    final rows = await _conversationSource.fetchParticipants(conversationId);
    return rows.map((r) => ConversationParticipant.fromJson(r)).toList();
  }

  Future<void> addParticipant(
    String conversationId,
    String userId, {
    String role = 'member',
  }) async {
    await _conversationSource.addParticipant({
      'conversation_id': conversationId,
      SupabaseConstants.colUserId: userId,
      SupabaseConstants.colRole: role,
    });
  }

  Future<void> leaveConversation(String conversationId, String userId) async {
    await _conversationSource.updateParticipant(conversationId, userId, {
      'is_left': true,
    });
  }

  Future<void> updateParticipantRole(
    String conversationId,
    String userId,
    String role,
  ) async {
    await _conversationSource.updateParticipant(conversationId, userId, {
      SupabaseConstants.colRole: role,
    });
  }

  Future<void> muteConversation(
    String conversationId,
    String userId, {
    required bool muted,
  }) async {
    await _conversationSource.updateParticipant(conversationId, userId, {
      'is_muted': muted,
    });
  }

  /// Subscribe to new messages — returns channel for cleanup.
  ///
  /// Verifies the user is a conversation participant before subscribing.
  /// Returns null if the user is not a member (prevents unauthorized subscriptions).
  Future<Object?> subscribeToMessages(
    String conversationId,
    String userId,
    void Function(Message message) onMessage,
  ) async {
    // Verify membership before subscribing to prevent unauthorized channel access
    final isMember = await _messageSource.isConversationParticipant(
      conversationId,
      userId,
    );
    if (!isMember) {
      // Obfuscate the user id — `.warning` attaches a Sentry breadcrumb even in
      // release, and the full auth UUID is PII (observability.md).
      AppLogger.warning(
        '[Messaging] User ${AppLogger.obfuscate(userId)} is not a '
        'participant of $conversationId',
      );
      return null;
    }
    return _messageSource.subscribeToMessages(conversationId, (payload) {
      try {
        final message = Message.fromJson(payload);
        onMessage(message);
      } catch (e, st) {
        AppLogger.error('messaging', e, st);
      }
    });
  }

  /// Subscribe to conversation updates — returns channel for cleanup
  Object subscribeToConversationUpdates(
    List<String> conversationIds,
    void Function(Conversation conversation) onUpdate,
  ) {
    return _messageSource.subscribeToConversationUpdates(conversationIds, (
      payload,
    ) {
      try {
        final conversation = Conversation.fromJson(payload);
        onUpdate(conversation);
      } catch (e, st) {
        AppLogger.error('messaging', e, st);
      }
    });
  }

  Future<void> unsubscribe(Object channel) async {
    if (channel is RealtimeChannel) {
      await _messageSource.unsubscribe(channel);
    }
  }
}
