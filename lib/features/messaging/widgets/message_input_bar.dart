import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:budgie_breeding_tracker/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/profile_stream_providers.dart';

import '../../../core/enums/messaging_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../../../core/utils/image_picker_guard.dart';
import '../../../core/utils/logger.dart';
import '../providers/messaging_form_providers.dart';
import '../providers/messaging_providers.dart'
    show messageAttachmentsEnabledProvider;
import '../services/message_attachment_service.dart';

class MessageInputBar extends ConsumerStatefulWidget {
  final String conversationId;

  const MessageInputBar({super.key, required this.conversationId});

  @override
  ConsumerState<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends ConsumerState<MessageInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;
  bool _isAttachingPhoto = false;

  /// The last send that has not yet succeeded, so the SnackBar "retry" action
  /// replays the exact same payload — crucially the IMAGE (with its already
  /// uploaded URL, reused not re-uploaded) rather than blindly re-sending the
  /// text field. Reusing [messageId] lets the failed optimistic bubble be
  /// replaced on retry instead of duplicated. Cleared on success.
  ({String? content, MessageType type, String? imageUrl, String messageId})?
  _pendingSend;

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

    // Surface send failures (cooldown, moderation, length cap, network). The
    // form provider set `error` but nothing displayed it, so a failed send was
    // silent apart from the input keeping its text. Show the reason with a
    // retry action that re-sends the preserved text.
    ref.listen<MessagingFormState>(messagingFormStateProvider, (prev, next) {
      final error = next.error;
      if (error == null || error == prev?.error || !mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error),
            action: SnackBarAction(
              label: 'common.retry'.tr(),
              onPressed: _retryLastSend,
            ),
          ),
        );
      ref.read(messagingFormStateProvider.notifier).clearError();
    });

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
            if (attachmentsEnabled)
              AppIconButton(
                icon: _isAttachingPhoto
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.plus),
                onPressed: _isAttachingPhoto ? null : _showAttachmentOptions,
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
    await _dispatchSend(content: text, type: MessageType.text);
  }

  /// Single send path for both text and image messages. Records [_pendingSend]
  /// before dispatching so a failure can be replayed verbatim, and clears the
  /// text field / pending payload only once the send actually succeeds.
  Future<void> _dispatchSend({
    String? content,
    required MessageType type,
    String? imageUrl,
    String? reuseMessageId,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    final notifier = ref.read(messagingFormStateProvider.notifier);
    // Pull the display name once at send time so the saved row carries
    // attribution (audit M6 — group recipients otherwise saw no sender
    // label). Falls back to empty string when the profile hasn't loaded
    // yet; server-side trigger can backfill from `profiles` later.
    final profile = ref.read(userProfileProvider).value;
    final senderName = profile?.resolvedDisplayName ?? '';
    final messageId = reuseMessageId ?? const Uuid().v7();
    _pendingSend = (
      content: content,
      type: type,
      imageUrl: imageUrl,
      messageId: messageId,
    );

    // Don't clear the input until we know the send succeeded. If the call is
    // rejected (cooldown, length cap, content moderation), the user keeps
    // their text/photo instead of losing it and having to redo it.
    final sent = await notifier.sendMessage(
      conversationId: widget.conversationId,
      senderId: userId,
      senderName: senderName,
      content: content,
      messageType: type,
      imageUrl: imageUrl,
      clientMessageId: messageId,
    );
    if (sent == null) return;
    _pendingSend = null;
    if (type == MessageType.text && mounted) _controller.clear();
  }

  /// Replays the last unsuccessful send. For an image this re-sends the SAME
  /// uploaded URL (no re-upload, no orphan) instead of the old behavior of
  /// firing the text field. Falls back to a fresh text send when nothing is
  /// pending.
  void _retryLastSend() {
    final pending = _pendingSend;
    if (pending == null) {
      unawaited(_sendMessage());
      return;
    }
    unawaited(
      _dispatchSend(
        content: pending.content,
        type: pending.type,
        imageUrl: pending.imageUrl,
        reuseMessageId: pending.messageId,
      ),
    );
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
                unawaited(_sendPhotoAttachment());
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPhotoAttachment() async {
    if (_isAttachingPhoto) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isAttachingPhoto = true);

    try {
      final attachmentService = ref.read(messageAttachmentServiceProvider);
      final picked = await attachmentService.pickPhoto(ImageSource.gallery);
      if (!mounted || picked == null) return;

      final withinSize = await ImagePickerGuard.ensureWithinSizeLimitVia(
        messenger,
        picked,
      );
      if (!mounted || !withinSize) return;

      // Gate on the send cooldown BEFORE uploading — otherwise a photo picked
      // within 2s of the previous send uploads to Storage and is then rejected
      // by sendMessage's cooldown, orphaning the object.
      final notifier = ref.read(messagingFormStateProvider.notifier);
      if (notifier.isWithinSendCooldown) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('messaging.send_cooldown'.tr())),
          );
        return;
      }

      final userId = ref.read(currentUserIdProvider);
      final imageUrl = await attachmentService.uploadPhoto(
        userId: userId,
        conversationId: widget.conversationId,
        file: picked,
      );
      if (!mounted) return;

      // Reuse the uploaded URL through the shared send path so a failure can be
      // retried without re-uploading (the SnackBar retry replays this exact
      // image, not the text field).
      await _dispatchSend(type: MessageType.image, imageUrl: imageUrl);
    } catch (e, st) {
      AppLogger.error('messaging attachment upload failed', e, st);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('messaging.attachment_upload_failed'.tr())),
        );
    } finally {
      if (mounted) {
        setState(() => _isAttachingPhoto = false);
      }
    }
  }
}
