import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../shared/providers/community.dart';

export 'package:budgie_breeding_tracker/data/models/conversation_model.dart';
export 'package:budgie_breeding_tracker/data/models/message_model.dart';
export 'package:budgie_breeding_tracker/data/models/conversation_participant_model.dart';
export 'package:budgie_breeding_tracker/core/enums/messaging_enums.dart';

/// Feature flag
final isMessagingEnabledProvider = Provider<bool>((ref) => true);

/// All conversations for current user, with blocked-user filtering.
///
/// A direct conversation whose last message came from a blocked user is
/// hidden from the list. The filter is heuristic (we can only see the
/// last sender's id, not every past participant) but covers the common
/// abuse vector: "I keep getting unwanted DMs from X." Server-side
/// `block_user` also stops new messages from blocked users from
/// arriving, so the filter doesn't need to cover historical traffic.
final conversationsProvider =
    FutureProvider.family<List<Conversation>, String>(
  (ref, userId) async {
    final repo = ref.watch(messagingRepositoryProvider);
    final blocked = ref.watch(blockedUsersProvider).toSet();
    final conversations = await repo.getConversations(userId);
    if (blocked.isEmpty) return conversations;
    return conversations.where((c) {
      // Keep group conversations: blocking a single member shouldn't
      // hide the whole thread. Direct conversations whose last sender
      // is blocked get hidden.
      if (c.isGroup) return true;
      final lastSender = c.lastMessageUserId;
      if (lastSender == null) return true;
      if (lastSender == userId) return true; // last message from me — keep
      return !blocked.contains(lastSender);
    }).toList();
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

/// Messages for a conversation, with blocked-sender filtering.
///
/// Messages from blocked senders are silently removed from the visible
/// thread. Server-side block also prevents new ones from arriving, but
/// this client filter handles historical messages and any in-flight
/// realtime emissions before the server enforces the block.
final messagesProvider =
    FutureProvider.family<List<Message>, String>(
  (ref, conversationId) async {
    final repo = ref.watch(messagingRepositoryProvider);
    final blocked = ref.watch(blockedUsersProvider).toSet();
    final messages = await repo.getMessages(conversationId);
    if (blocked.isEmpty) return messages;
    return messages.where((m) => !blocked.contains(m.senderId)).toList();
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
