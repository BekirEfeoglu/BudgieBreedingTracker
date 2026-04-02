import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../router/route_names.dart';
import '../../marketplace/widgets/marketplace_tab_content.dart';
import '../providers/community_providers.dart';
import '../widgets/community_app_bar.dart';
import '../widgets/community_feed_list.dart';
import '../widgets/community_pill_tabs.dart';

/// Community screen — social hub with feed, marketplace, messaging access.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(isCommunityEnabledProvider);
    final activeTab = ref.watch(communityActiveTabProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CommunityAppBar(),
      body: isEnabled
          ? _buildBody(activeTab)
          : const _ComingSoonBody(),
      floatingActionButton: isEnabled
          ? _CommunityFab(theme: theme)
          : null,
    );
  }

  Widget _buildBody(CommunityFeedTab activeTab) {
    // questions tab is repurposed as marketplace tab in UI
    if (activeTab == CommunityFeedTab.questions) {
      return const Column(
        children: [
          CommunityPillTabs(),
          Expanded(child: MarketplaceTabContent()),
        ],
      );
    }

    return Column(
      children: [
        const CommunityPillTabs(),
        Expanded(
          child: CommunityFeedList(tab: activeTab),
        ),
      ],
    );
  }
}

/// FAB with bottom sheet for multiple creation options.
class _CommunityFab extends StatelessWidget {
  final ThemeData theme;

  const _CommunityFab({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => _showCreateOptions(context),
        tooltip: 'community.create_post'.tr(),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'community.create_post'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(LucideIcons.pencil),
              title: Text('community.create_post'.tr()),
              subtitle: Text('community.content_label'.tr()),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.communityCreatePost);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.store),
              title: Text('marketplace.add_listing'.tr()),
              subtitle: Text('marketplace.no_listings_hint'.tr()),
              onTap: () {
                Navigator.pop(context);
                context.push('${AppRoutes.marketplace}/form');
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.messageCircle),
              title: Text('messaging.new_message'.tr()),
              subtitle: Text('messaging.no_conversations_hint'.tr()),
              onTap: () {
                Navigator.pop(context);
                context.push('${AppRoutes.messages}/group/form');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonBody extends StatelessWidget {
  const _ComingSoonBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: const AppIcon(AppIcons.community),
        title: 'community.coming_soon'.tr(),
        subtitle: 'community.coming_soon_hint'.tr(),
      ),
    );
  }
}
