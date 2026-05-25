import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/enums/messaging_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (message.isDeleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Center(
          child: Text(
            'messaging.message_deleted'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && message.senderName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  message.senderName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            _buildContent(context, theme),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(context, message.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    message.readBy.length > 1
                        ? LucideIcons.checkCheck
                        : LucideIcons.check,
                    size: 14,
                    color: message.readBy.length > 1
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    switch (message.messageType) {
      case MessageType.text:
        return Text(
          message.content ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isMe
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
          ),
        );
      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: message.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: message.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  memCacheWidth: 640,
                  placeholder: (_, __) => Container(
                    height: 150,
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  errorWidget: (_, _, _) => Container(
                    height: 150,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(LucideIcons.imageOff, size: 32),
                  ),
                )
              : const SizedBox.shrink(),
        );
      case MessageType.birdCard:
        return _buildReferenceCard(
          context,
          theme,
          icon: AppIcon(
            AppIcons.bird,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          label: 'messaging.bird_card_message'.tr(),
        );
      case MessageType.listingCard:
        return _buildReferenceCard(
          context,
          theme,
          icon: Icon(
            LucideIcons.store,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          label: 'messaging.listing_card_message'.tr(),
        );
      case MessageType.unknown:
        return Text(
          message.content ?? '',
          style: theme.textTheme.bodyMedium,
        );
    }
  }

  Widget _buildReferenceCard(
    BuildContext context,
    ThemeData theme, {
    required Widget icon,
    required String label,
  }) {
    final title = message.referenceData['name'] as String? ??
        message.referenceData['title'] as String? ??
        label;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime? dateTime) {
    if (dateTime == null) return '';
    // Locale-aware so DE renders 14:30 and EN/TR keep their conventions.
    // Hardcoded HH:mm worked by accident for the current locale set
    // but violates datetime-format.md. The try/catch falls back to a
    // raw HH:mm when intl locale data hasn't been initialized (e.g.
    // unit tests that don't bootstrap easy_localization).
    final locale = context.locale.toString();
    try {
      return DateFormat.Hm(locale).format(dateTime);
    } catch (_) {
      final h = dateTime.hour.toString().padLeft(2, '0');
      final m = dateTime.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
  }
}
