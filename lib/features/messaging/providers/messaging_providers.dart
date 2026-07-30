import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/feature_flags.dart';
import '../../../core/utils/logger.dart';
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

/// Feature flag for message attachment UI.
final messageAttachmentsEnabledProvider = Provider<bool>(
  (ref) => FeatureFlags.messageAttachmentsEnabled,
);

/// All conversations for current user, with blocked-user filtering.
///
/// A direct conversation whose last message came from a blocked user is
/// hidden from the list. The filter is heuristic (we can only see the
/// last sender's id, not every past participant) but covers the common
/// abuse vector: "I keep getting unwanted DMs from X." Server-side
/// `block_user` also stops new messages from blocked users from
/// arriving, so the filter doesn't need to cover historical traffic.
final conversationsProvider = FutureProvider.family<List<Conversation>, String>(
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
final conversationByIdProvider = FutureProvider.family<Conversation?, String>((
  ref,
  conversationId,
) async {
  final repo = ref.watch(messagingRepositoryProvider);
  return repo.getConversationById(conversationId);
});

const messageThreadPageSize = 50;

/// Immutable paginated snapshot for one conversation.
class MessageThreadState {
  final List<Message> messages;
  final bool hasMore;
  final bool isLoadingMore;
  final DateTime? oldestCursor;

  const MessageThreadState({
    required this.messages,
    required this.hasMore,
    required this.oldestCursor,
    this.isLoadingMore = false,
  });

  MessageThreadState copyWith({
    List<Message>? messages,
    bool? hasMore,
    bool? isLoadingMore,
    DateTime? oldestCursor,
  }) => MessageThreadState(
    messages: messages ?? this.messages,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    oldestCursor: oldestCursor ?? this.oldestCursor,
  );
}

/// Cursor-paginated message history for a conversation.
///
/// The first page contains the newest [messageThreadPageSize] rows. [loadMore]
/// appends older pages using the oldest server timestamp as the cursor while
/// preserving already-visible messages if a later page fails.
class MessageThreadNotifier extends AsyncNotifier<MessageThreadState> {
  MessageThreadNotifier(this.conversationId);

  final String conversationId;

  @override
  Future<MessageThreadState> build() async {
    final repo = ref.watch(messagingRepositoryProvider);
    final page = await repo.getMessages(
      conversationId,
      limit: messageThreadPageSize,
    );
    return MessageThreadState(
      messages: page,
      hasMore: page.length == messageThreadPageSize,
      oldestCursor: page.lastOrNull?.createdAt,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null ||
        current.isLoadingMore ||
        !current.hasMore ||
        current.oldestCursor == null) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final repo = ref.read(messagingRepositoryProvider);
      final page = await repo.getMessages(
        conversationId,
        limit: messageThreadPageSize,
        before: current.oldestCursor,
      );
      final byId = <String, Message>{
        for (final message in current.messages) message.id: message,
        for (final message in page) message.id: message,
      };
      state = AsyncData(
        MessageThreadState(
          messages: byId.values.toList(growable: false),
          hasMore: page.length == messageThreadPageSize,
          isLoadingMore: false,
          oldestCursor: page.isEmpty
              ? current.oldestCursor
              : page.last.createdAt,
        ),
      );
    } catch (e, st) {
      AppLogger.error('messaging.loadMore', e, st);
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final messageThreadProvider =
    AsyncNotifierProvider.family<
      MessageThreadNotifier,
      MessageThreadState,
      String
    >(MessageThreadNotifier.new);

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
    Provider.family<List<Conversation>, List<Conversation>>((
      ref,
      conversations,
    ) {
      final query = ref
          .watch(conversationSearchQueryProvider)
          .toLowerCase()
          .trim();
      if (query.isEmpty) return conversations;

      return conversations.where((c) {
        return (c.name?.toLowerCase().contains(query) ?? false) ||
            (c.lastMessageContent?.toLowerCase().contains(query) ?? false);
      }).toList();
    });

/// Total unread count across all conversations
final totalUnreadCountProvider = Provider.family<int, List<Conversation>>((
  ref,
  conversations,
) {
  return conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
});
