import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../../../core/widgets/buttons/fab_button.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_stream_providers.dart';
import '../../../router/route_names.dart';
import '../providers/messaging_providers.dart';
import '../widgets/conversation_tile.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final isAnonymous = userId == 'anonymous';
    final conversationsAsync = ref.watch(conversationsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text('messaging.title'.tr()),
        actions: [
          if (!isAnonymous)
            IconButton(
              icon: const Icon(LucideIcons.edit),
              tooltip: 'messaging.new_message'.tr(),
              onPressed: () => _showNewMessageOptions(context),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(conversationsProvider(userId));
        },
        child: conversationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => app.ErrorState(
            message: '${'messaging.load_error'.tr()}: $error',
            onRetry: () => ref.invalidate(conversationsProvider(userId)),
          ),
          data: (allConversations) {
            final conversations = ref.watch(
              filteredConversationsProvider(allConversations),
            );

            if (allConversations.isEmpty) {
              return EmptyState(
                icon: const Icon(LucideIcons.messageCircle),
                title: 'messaging.no_conversations'.tr(),
                subtitle: 'messaging.no_conversations_hint'.tr(),
              );
            }

            if (conversations.isEmpty) {
              return EmptyState(
                icon: const Icon(LucideIcons.searchX),
                title: 'common.no_results'.tr(),
                subtitle: 'messaging.no_results'.tr(),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xxxl * 2,
              ),
              itemCount: conversations.length,
              itemBuilder: (context, index) =>
                  ConversationTile(conversation: conversations[index]),
            );
          },
        ),
      ),
      floatingActionButton: isAnonymous
          ? null
          : FabButton(
              icon: const Icon(LucideIcons.pencil),
              tooltip: 'messaging.new_message'.tr(),
              onPressed: () => _showNewMessageOptions(context),
            ),
    );
  }

  void _showNewMessageOptions(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: Icon(
                LucideIcons.messageCircle,
                color: theme.colorScheme.primary,
              ),
              title: Text('messaging.direct_message'.tr()),
              subtitle: Text('messaging.direct_message_hint'.tr()),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push('${AppRoutes.messages}/new');
              },
            ),
            ListTile(
              leading: Icon(
                LucideIcons.users,
                color: theme.colorScheme.primary,
              ),
              title: Text('messaging.new_group'.tr()),
              subtitle: Text('messaging.new_group_hint'.tr()),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push('${AppRoutes.messages}/group/form');
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
