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
import '../../messaging/widgets/messaging_tab_content.dart';
import '../providers/community_providers.dart';
import '../widgets/community_feed_list.dart';

/// Community screen - social feed with posts, likes, comments, bookmarks.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(isCommunityEnabledProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 6,
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
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              Text(
                'community.content_label'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            _HeaderActionButton(
              icon: LucideIcons.search,
              tooltip: 'community.search'.tr(),
              onPressed: () => context.push(AppRoutes.communitySearch),
            ),
            const SizedBox(width: AppSpacing.sm),
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
                          icon: const AppIcon(AppIcons.guide, size: 16),
                          text: 'community.tab_guides'.tr(),
                        ),
                        Tab(
                          icon: const AppIcon(AppIcons.comment, size: 16),
                          text: 'community.tab_questions'.tr(),
                        ),
                        Tab(
                          icon: const Icon(LucideIcons.store, size: 16),
                          text: 'marketplace.title'.tr(),
                        ),
                        Tab(
                          icon: const Icon(LucideIcons.messageCircle, size: 16),
                          text: 'messaging.title'.tr(),
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
                  CommunityFeedList(tab: CommunityFeedTab.guides),
                  CommunityFeedList(tab: CommunityFeedTab.questions),
                  MarketplaceTabContent(),
                  MessagingTabContent(),
                ],
              )
            : const _ComingSoonBody(),
        floatingActionButton: isEnabled
            ? FloatingActionButton.extended(
                onPressed: () => context.push(AppRoutes.communityCreatePost),
                tooltip: 'community.create_post'.tr(),
                icon: const AppIcon(AppIcons.post, size: 18),
                label: Text('community.create_post'.tr()),
              )
            : null,
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
