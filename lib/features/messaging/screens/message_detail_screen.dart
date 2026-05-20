import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/error_state.dart' as app;
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import '../providers/messaging_providers.dart';
import '../providers/messaging_realtime_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

class MessageDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const MessageDetailScreen({super.key, required this.conversationId});

  @override
  ConsumerState<MessageDetailScreen> createState() =>
      _MessageDetailScreenState();
}

class _MessageDetailScreenState extends ConsumerState<MessageDetailScreen> {
  final _scrollController = ScrollController();
  MessagingRealtimeNotifier? _realtimeNotifier;
  final Set<String> _markedRead = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(messagingRealtimeProvider.notifier);
      _realtimeNotifier = notifier;
      notifier.subscribe(widget.conversationId);
    });
  }

  /// Marks incoming messages as read once the conversation is on screen.
  /// Deduplicates via [_markedRead] so the build loop doesn't fan out a
  /// new RPC for the same message every frame.
  void _markVisibleAsRead(List<Message> messages, String userId) {
    final repo = ref.read(messagingRepositoryProvider);
    for (final msg in messages) {
      if (msg.senderId == userId) continue;
      if (msg.isReadBy(userId)) continue;
      if (!_markedRead.add(msg.id)) continue;
      repo.markAsRead(msg.id, userId).catchError((Object e) {
        // Best-effort: server-side append is idempotent and a missed read
        // receipt is recoverable on the next conversation open.
        AppLogger.warning(
          '[MessageDetailScreen] markAsRead failed for ${msg.id}: $e',
        );
        // Allow a retry on the next visible-rebuild.
        _markedRead.remove(msg.id);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Drop the realtime channel and any buffered messages so they don't
    // leak into the next conversation the user opens. Use the cached
    // notifier reference because `ref` is unsafe during dispose.
    _realtimeNotifier?.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final conversationAsync = ref.watch(
      conversationByIdProvider(widget.conversationId),
    );
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final realtimeMessages = ref.watch(messagingRealtimeProvider);
    final typingUsers = ref.watch(typingIndicatorProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: conversationAsync.when(
          loading: () => Text('messaging.title'.tr()),
          error: (_, __) => Text('messaging.title'.tr()),
          data: (conversation) {
            if (conversation == null) return Text('messaging.title'.tr());
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  conversation.name ?? 'messaging.direct_message'.tr(),
                  style: theme.textTheme.titleMedium,
                ),
                if (conversation.isGroup)
                  Text(
                    'messaging.member_count'.tr(
                      args: ['${conversation.participantCount}'],
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          if (typingUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
              child: Center(
                child: Text(
                  'messaging.typing'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const LoadingState(),
              error: (error, _) => app.ErrorState(
                message: '${'messaging.load_error'.tr()}: $error',
                onRetry: () =>
                    ref.invalidate(messagesProvider(widget.conversationId)),
              ),
              data: (fetchedMessages) {
                final allMessages = <String, Message>{};
                for (final msg in realtimeMessages) {
                  allMessages[msg.id] = msg;
                }
                for (final msg in fetchedMessages) {
                  allMessages.putIfAbsent(msg.id, () => msg);
                }
                final messages = allMessages.values.toList()
                  ..sort(
                    (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                      a.createdAt ?? DateTime(0),
                    ),
                  );

                // Mark visible incoming messages as read after this frame
                // so unread counts and read indicators converge.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _markVisibleAsRead(messages, userId);
                });

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'messaging.no_messages_hint'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return MessageBubble(
                      message: message,
                      isMe: message.senderId == userId,
                    );
                  },
                );
              },
            ),
          ),
          MessageInputBar(conversationId: widget.conversationId),
        ],
      ),
    );
  }
}
