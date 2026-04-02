import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../../../features/breeding/providers/breeding_providers.dart';
import '../providers/messaging_providers.dart';
import '../providers/messaging_realtime_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';

class MessageDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const MessageDetailScreen({super.key, required this.conversationId});

  @override
  ConsumerState<MessageDetailScreen> createState() =>
      _MessageDetailScreenState();
}

class _MessageDetailScreenState extends ConsumerState<MessageDetailScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(messagingRealtimeProvider.notifier)
          .subscribe(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final conversationAsync =
        ref.watch(conversationByIdProvider(widget.conversationId));
    final messagesAsync =
        ref.watch(messagesProvider(widget.conversationId));
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
                    'messaging.member_count'
                        .tr(args: ['${conversation.participantCount}']),
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
              padding: const EdgeInsets.only(right: AppSpacing.md),
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
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => app.ErrorState(
                message: '${'messaging.load_error'.tr()}: $error',
                onRetry: () => ref.invalidate(
                    messagesProvider(widget.conversationId)),
              ),
              data: (fetchedMessages) {
                final allMessages = <String, dynamic>{};
                for (final msg in realtimeMessages) {
                  allMessages[msg.id] = msg;
                }
                for (final msg in fetchedMessages) {
                  allMessages.putIfAbsent(msg.id, () => msg);
                }
                final messages = allMessages.values.toList()
                  ..sort((a, b) =>
                      (b.createdAt ?? DateTime(0))
                          .compareTo(a.createdAt ?? DateTime(0)));

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
          MessageInputBar(
            conversationId: widget.conversationId,
          ),
        ],
      ),
    );
  }
}
