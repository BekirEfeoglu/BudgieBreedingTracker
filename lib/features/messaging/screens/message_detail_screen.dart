import 'dart:async';

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
  // Retry budget per message — flapping network used to schedule a new
  // RPC every rebuild (audit M3). Cap at 3 attempts then give up; the
  // next conversation open will retry.
  final Map<String, int> _markReadAttempts = <String, int>{};
  static const int _maxMarkReadAttempts = 3;
  Timer? _markReadThrottle;

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

  /// Throttles the visible-mark-as-read sweep so a stream of rebuilds
  /// doesn't fire an RPC per frame. The dedupe-via-[_markedRead] still
  /// applies; this just bounds how often we walk the message list.
  void _scheduleMarkVisibleAsRead(List<Message> messages, String userId) {
    _markReadThrottle?.cancel();
    _markReadThrottle = Timer(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      _markVisibleAsRead(messages, userId);
    });
  }

  /// Marks incoming messages as read once the conversation is on screen.
  /// Deduplicates via [_markedRead] so the build loop doesn't fan out a
  /// new RPC for the same message every frame; retries up to
  /// [_maxMarkReadAttempts] times before giving up to avoid the
  /// flapping-network unbounded-retry hazard.
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
        // Capped retry: increment attempt counter; only re-allow if we
        // haven't blown the budget yet.
        final attempts = (_markReadAttempts[msg.id] ?? 0) + 1;
        _markReadAttempts[msg.id] = attempts;
        if (attempts < _maxMarkReadAttempts) {
          _markedRead.remove(msg.id);
        }
      });
    }
  }

  @override
  void dispose() {
    _markReadThrottle?.cancel();
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
                // Sort newest-first. Optimistic (just-sent) messages may
                // have null `createdAt` until the server timestamp comes
                // back; treat them as "newest" so they appear at the top
                // of the reversed ListView instead of falling to year 0
                // and disappearing for the sender (audit M4).
                final pinnedTop = DateTime.now().add(
                  const Duration(days: 365 * 1000),
                );
                final messages = allMessages.values.toList()
                  ..sort(
                    (a, b) => (b.createdAt ?? pinnedTop).compareTo(
                      a.createdAt ?? pinnedTop,
                    ),
                  );

                // Schedule the mark-as-read sweep with a 750ms throttle.
                // Previously this fired on every rebuild — incoming
                // realtime events caused fan-out RPCs (audit M3).
                _scheduleMarkVisibleAsRead(messages, userId);

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
