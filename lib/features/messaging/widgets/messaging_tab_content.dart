import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../../../features/breeding/providers/breeding_providers.dart';
import '../../../router/route_names.dart';
import '../providers/messaging_providers.dart';
import 'conversation_tile.dart';

/// Scaffold-free messaging content for embedding in TabBarView.
class MessagingTabContent extends ConsumerWidget {
  const MessagingTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final conversationsAsync = ref.watch(conversationsProvider(userId));

    return Column(
      children: [
        // Action bar
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'messaging.title'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.users, size: 20),
                tooltip: 'messaging.new_group'.tr(),
                onPressed: () =>
                    context.push('${AppRoutes.messages}/group/form'),
              ),
              IconButton(
                icon: const Icon(LucideIcons.pencil, size: 20),
                tooltip: 'messaging.new_message'.tr(),
                onPressed: () =>
                    context.push('${AppRoutes.messages}/group/form'),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(conversationsProvider(userId));
            },
            child: conversationsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => app.ErrorState(
                message: '${'messaging.load_error'.tr()}: $error',
                onRetry: () =>
                    ref.invalidate(conversationsProvider(userId)),
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
        ),
      ],
    );
  }
}
