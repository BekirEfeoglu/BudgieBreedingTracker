import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/conversation_model.dart';
import '../../../router/route_names.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;

  const ConversationTile({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        radius: 24,
        backgroundImage: conversation.imageUrl != null
            ? NetworkImage(conversation.imageUrl!)
            : null,
        child: conversation.imageUrl == null
            ? Icon(
                conversation.isGroup
                    ? LucideIcons.users
                    : LucideIcons.user,
                size: 20,
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.name ?? 'messaging.direct_message'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: conversation.hasUnread
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.lastMessageAt != null)
            Text(
              _formatTime(conversation.lastMessageAt!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: conversation.hasUnread
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessageContent ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: conversation.hasUnread
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.outline,
                fontWeight: conversation.hasUnread
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.hasUnread)
            Container(
              margin: const EdgeInsets.only(left: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
      onTap: () => context.push('${AppRoutes.messages}/${conversation.id}'),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'messaging.just_now'.tr();
    if (diff.inMinutes < 60) {
      return 'messaging.minutes_ago'.tr(args: ['${diff.inMinutes}']);
    }
    if (diff.inHours < 24) {
      return 'messaging.hours_ago'.tr(args: ['${diff.inHours}']);
    }
    if (diff.inDays == 1) return 'messaging.yesterday'.tr();
    return '${dateTime.day}/${dateTime.month}';
  }
}
