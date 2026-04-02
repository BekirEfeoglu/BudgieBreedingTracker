import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/constants/app_icons.dart';
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
      backgroundColor: theme.colorScheme.surface,
      appBar: const CommunityAppBar(),
      floatingActionButton: isEnabled && activeTab != CommunityFeedTab.questions
          ? FloatingActionButton.extended(
              onPressed: () => context.push(_buildCreatePostRoute(activeTab)),
              icon: Icon(
                activeTab == CommunityFeedTab.guides
                    ? Icons.menu_book_rounded
                    : Icons.edit_rounded,
              ),
              label: Text('community.create_post'.tr()),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.38),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
            stops: const [0, 0.24, 1],
          ),
        ),
        child: SafeArea(
          top: false,
          child: isEnabled
              ? _buildBody(context, activeTab)
              : const _ComingSoonBody(),
        ),
      ),
    );
  }

  String _buildCreatePostRoute(CommunityFeedTab activeTab) {
    final initialType = switch (activeTab) {
      CommunityFeedTab.guides => CommunityPostType.guide,
      _ => CommunityPostType.general,
    };

    return initialType == CommunityPostType.general
        ? AppRoutes.communityCreatePost
        : '${AppRoutes.communityCreatePost}?type=${initialType.toJson()}';
  }

  Widget _buildBody(BuildContext context, CommunityFeedTab activeTab) {
    final theme = Theme.of(context);

    // questions tab is repurposed as marketplace tab in UI
    if (activeTab == CommunityFeedTab.questions) {
      return Column(
        children: [
          const _CommunityTabRail(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXl),
                ),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.18,
                  ),
                ),
              ),
              child: const MarketplaceTabContent(),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const _CommunityTabRail(),
        Expanded(child: CommunityFeedList(tab: activeTab)),
      ],
    );
  }
}

class _CommunityTabRail extends StatelessWidget {
  const _CommunityTabRail();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const CommunityPillTabs(),
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
