import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/repository_providers.dart';

export 'package:budgie_breeding_tracker/data/models/conversation_model.dart';
export 'package:budgie_breeding_tracker/data/models/message_model.dart';
export 'package:budgie_breeding_tracker/data/models/conversation_participant_model.dart';
export 'package:budgie_breeding_tracker/core/enums/messaging_enums.dart';

/// Feature flag
final isMessagingEnabledProvider = Provider<bool>((ref) => true);

/// All conversations for current user
final conversationsProvider =
    FutureProvider.family<List<Conversation>, String>(
  (ref, userId) async {
    final repo = ref.watch(messagingRepositoryProvider);
    return repo.getConversations(userId);
  },
);

/// Single conversation by ID
final conversationByIdProvider =
    FutureProvider.family<Conversation?, String>(
  (ref, conversationId) async {
    final repo = ref.watch(messagingRepositoryProvider);
    return repo.getConversationById(conversationId);
  },
);

/// Messages for a conversation
final messagesProvider =
    FutureProvider.family<List<Message>, String>(
  (ref, conversationId) async {
    final repo = ref.watch(messagingRepositoryProvider);
    return repo.getMessages(conversationId);
  },
);

/// Search state
class ConversationSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
}

final conversationSearchQueryProvider =
    NotifierProvider<ConversationSearchQueryNotifier, String>(
  ConversationSearchQueryNotifier.new,
);

/// Filtered conversations (computed)
final filteredConversationsProvider =
    Provider.family<List<Conversation>, List<Conversation>>(
  (ref, conversations) {
    final query =
        ref.watch(conversationSearchQueryProvider).toLowerCase().trim();
    if (query.isEmpty) return conversations;

    return conversations.where((c) {
      return (c.name?.toLowerCase().contains(query) ?? false) ||
          (c.lastMessageContent?.toLowerCase().contains(query) ?? false);
    }).toList();
  },
);

/// Total unread count across all conversations
final totalUnreadCountProvider =
    Provider.family<int, List<Conversation>>(
  (ref, conversations) {
    return conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
  },
);
