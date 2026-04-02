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
import '../widgets/community_feed_list.dart';

/// Community screen - social hub with feed, marketplace, messaging access.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(isCommunityEnabledProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          toolbarHeight: 76,
          titleSpacing: AppSpacing.lg,
          flexibleSpace: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.primary.withValues(alpha: 0.08),
                  theme.colorScheme.tertiary.withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                AppIcons.community,
                size: 24,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'community.title'.tr(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actions: [
            _HeaderActionButton(
              icon: LucideIcons.store,
              tooltip: 'marketplace.title'.tr(),
              onPressed: () => context.push(AppRoutes.marketplace),
            ),
            const SizedBox(width: AppSpacing.xs),
            _HeaderActionButton(
              icon: LucideIcons.messageCircle,
              tooltip: 'messaging.title'.tr(),
              onPressed: () => context.push(AppRoutes.messages),
            ),
            const SizedBox(width: AppSpacing.xs),
            _HeaderActionButton(
              icon: LucideIcons.search,
              tooltip: 'community.search'.tr(),
              onPressed: () => context.push(AppRoutes.communitySearch),
            ),
            const SizedBox(width: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: _HeaderActionButton(
                iconAsset: AppIcons.bookmark,
                tooltip: 'community.bookmarks'.tr(),
                onPressed: () => context.push(AppRoutes.communityBookmarks),
              ),
            ),
          ],
          bottom: isEnabled
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(52),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TabBar(
                      isScrollable: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        Tab(
                          icon: const AppIcon(AppIcons.community, size: 16),
                          text: 'community.tab_explore'.tr(),
                        ),
                        Tab(
                          icon: const AppIcon(AppIcons.like, size: 16),
                          text: 'community.tab_following'.tr(),
                        ),
                        Tab(
                          icon: const Icon(LucideIcons.store, size: 16),
                          text: 'marketplace.title'.tr(),
                        ),
                        Tab(
                          icon: const AppIcon(AppIcons.guide, size: 16),
                          text: 'community.tab_guides'.tr(),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
        body: isEnabled
            ? const TabBarView(
                children: [
                  CommunityFeedList(tab: CommunityFeedTab.explore),
                  CommunityFeedList(tab: CommunityFeedTab.following),
                  MarketplaceTabContent(),
                  CommunityFeedList(tab: CommunityFeedTab.guides),
                ],
              )
            : const _ComingSoonBody(),
        floatingActionButton: isEnabled
            ? _CommunityFab(theme: theme)
            : null,
      ),
    );
  }
}

/// FAB with bottom sheet for multiple creation options.
class _CommunityFab extends StatelessWidget {
  final ThemeData theme;

  const _CommunityFab({required this.theme});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showCreateOptions(context),
      tooltip: 'community.create_post'.tr(),
      child: const Icon(LucideIcons.plus),
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

class _HeaderActionButton extends StatelessWidget {
  final IconData? icon;
  final String? iconAsset;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderActionButton({
    this.icon,
    this.iconAsset,
    required this.tooltip,
    required this.onPressed,
  }) : assert(icon != null || iconAsset != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: IconButton(
        icon: iconAsset != null ? AppIcon(iconAsset!) : Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
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
