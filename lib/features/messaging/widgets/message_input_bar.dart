import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/enums/messaging_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/profile_stream_providers.dart';
import '../providers/messaging_form_providers.dart';
import '../providers/messaging_providers.dart'
    show messageAttachmentsEnabledProvider;
import 'package:budgie_breeding_tracker/core/widgets/bottom_sheet/app_bottom_sheet.dart';

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
    final attachmentsEnabled = ref.watch(messageAttachmentsEnabledProvider);

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
            // Attach button hidden until the upload pipeline ships.
            // Messaging audit C1+C2 — the bottom-sheet options were dead
            // UI (`onTap: Navigator.pop`) and the receive-side rendering
            // path for image/bird/listing messages had no producer.
            if (attachmentsEnabled)
              AppIconButton(
                icon: const Icon(LucideIcons.plus),
                onPressed: _showAttachmentOptions,
                tooltip: 'messaging.attach_photo'.tr(),
                semanticLabel: 'messaging.attach_photo'.tr(),
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
            AppIconButton(
              icon: Icon(
                LucideIcons.send,
                color: _hasText
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              onPressed: _hasText ? _sendMessage : null,
              tooltip: 'messaging.send'.tr(),
              semanticLabel: 'messaging.send'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userId = ref.read(currentUserIdProvider);
    final notifier = ref.read(messagingFormStateProvider.notifier);
    // Pull the display name once at send time so the saved row carries
    // attribution (audit M6 — group recipients otherwise saw no sender
    // label). Falls back to empty string when the profile hasn't loaded
    // yet; server-side trigger can backfill from `profiles` later.
    final profile = ref.read(userProfileProvider).value;
    final senderName = profile?.resolvedDisplayName ?? '';
    // Don't clear the input until we know the send succeeded. If the
    // call is rejected (cooldown, length cap, content moderation), the
    // user keeps their text instead of losing it and having to retype.
    await notifier.sendMessage(
      conversationId: widget.conversationId,
      senderId: userId,
      senderName: senderName,
      content: text,
      messageType: MessageType.text,
    );
    if (!mounted) return;
    final state = ref.read(messagingFormStateProvider);
    if (state.error == null && state.isSuccess) {
      _controller.clear();
    }
  }

  void _showAttachmentOptions() {
    showAppBottomSheet(
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
              leading: const AppIcon(AppIcons.bird),
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
