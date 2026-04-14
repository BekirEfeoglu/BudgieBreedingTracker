import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/enums/messaging_enums.dart';
import '../../../core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import '../providers/messaging_form_providers.dart';

class MessageInputBar extends ConsumerStatefulWidget {
  final String conversationId;

  const MessageInputBar({super.key, required this.conversationId});

  @override
  ConsumerState<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends ConsumerState<MessageInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.plus),
              onPressed: _showAttachmentOptions,
              tooltip: 'messaging.attach_photo'.tr(),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'messaging.type_message'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              icon: Icon(
                LucideIcons.send,
                color: _hasText
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              onPressed: _hasText ? _sendMessage : null,
              tooltip: 'messaging.send'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userId = ref.read(currentUserIdProvider);
    ref.read(messagingFormStateProvider.notifier).sendMessage(
          conversationId: widget.conversationId,
          senderId: userId,
          senderName: '',
          content: text,
          messageType: MessageType.text,
        );

    _controller.clear();
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: Text('messaging.attach_photo'.tr()),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.bird),
              title: Text('messaging.attach_bird'.tr()),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.store),
              title: Text('messaging.attach_listing'.tr()),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
