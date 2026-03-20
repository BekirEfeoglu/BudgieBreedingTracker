import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../../../data/providers/auth_state_providers.dart';
import '../../../router/route_names.dart';
import '../providers/community_feed_providers.dart';
import '../providers/community_providers.dart';
import 'community_creator_strip.dart';
import 'community_hero_card.dart';
import 'community_post_card.dart';
import 'community_quick_composer.dart';
import 'community_section_bar.dart';
import 'community_story_strip.dart';

/// Scrollable feed list with infinite scroll and pull-to-refresh.
class CommunityFeedList extends ConsumerStatefulWidget {
  final CommunityFeedTab tab;

  const CommunityFeedList({super.key, this.tab = CommunityFeedTab.explore});

  @override
  ConsumerState<CommunityFeedList> createState() => _CommunityFeedListState();
}

class _CommunityFeedListState extends ConsumerState<CommunityFeedList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      ref.read(communityFeedProvider.notifier).fetchMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(communityFeedProvider);
    final posts = feedState.posts;
    final currentUserId = ref.watch(currentUserIdProvider);
    final visiblePosts = ref.watch(communityVisiblePostsProvider(widget.tab));
    final isExplore = widget.tab == CommunityFeedTab.explore;
    final showExploreExtras = isExplore && visiblePosts.isNotEmpty;
    final exploreSort = ref.watch(exploreSortProvider);

    if (feedState.error != null && posts.isEmpty) {
      return Center(
        child: app.ErrorState(
          message: '${'community.feed_load_error'.tr()}: ${feedState.error}',
          onRetry: () => ref.read(communityFeedProvider.notifier).refresh(),
        ),
      );
    }

    if (feedState.isLoading && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(communityFeedProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (isExplore) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: CommunityHeroCard(posts: posts),
              ),
            ),
            if (showExploreExtras)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: CommunityStoryStrip(
                    stories: CommunityStoryStrip.fromPosts(visiblePosts),
                    onCreatePost: () =>
                        context.push(AppRoutes.communityCreatePost),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: CommunityQuickComposer(
                  currentUserId: currentUserId,
                  onCreatePost: () =>
                      context.push(AppRoutes.communityCreatePost),
                ),
              ),
            ),
          ],
          if (visiblePosts.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: CommunitySectionBar(
                  tab: widget.tab,
                  visibleCount: visiblePosts.length,
                  exploreSort: exploreSort,
                  onExploreSortChanged: _changeSort,
                ),
              ),
            ),
          if (showExploreExtras) ...[
            () {
              final creators = CommunityCreatorStrip.fromPosts(visiblePosts);
              if (creators.isEmpty) return const SliverToBoxAdapter();
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: CommunityCreatorStrip(creators: creators),
                ),
              );
            }(),
          ],
          if (!feedState.isLoading && posts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xxxl * 2,
                ),
                child: EmptyState(
                  icon: const AppIcon(AppIcons.community),
                  title: 'community.no_posts'.tr(),
                  subtitle: 'community.no_posts_hint'.tr(),
                ),
              ),
            )
          else if (!feedState.isLoading && visiblePosts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxxl,
                ),
                child: _FilteredFeedEmptyState(
                  tab: widget.tab,
                  onReset: widget.tab == CommunityFeedTab.explore
                      ? null
                      : () => context.go(AppRoutes.community),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl * 2),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= visiblePosts.length) {
                      if (feedState.isLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                    final post = visiblePosts[index];
                    return CommunityPostCard(
                      key: ValueKey(post.id),
                      post: post,
                    );
                  },
                  childCount: visiblePosts.length + (feedState.hasMore ? 1 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _changeSort(CommunityExploreSort sort) {
    ref.read(exploreSortProvider.notifier).state = sort;

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }
}

class _FilteredFeedEmptyState extends StatelessWidget {
  final CommunityFeedTab tab;
  final VoidCallback? onReset;

  const _FilteredFeedEmptyState({required this.tab, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleKey = switch (tab) {
      CommunityFeedTab.explore => 'community.empty_filtered_title',
      CommunityFeedTab.following => 'community.empty_following_title',
      CommunityFeedTab.guides => 'community.empty_guides_title',
      CommunityFeedTab.questions => 'community.empty_questions_title',
    };
    final hintKey = switch (tab) {
      CommunityFeedTab.explore => 'community.empty_filtered_hint',
      CommunityFeedTab.following => 'community.empty_following_hint',
      CommunityFeedTab.guides => 'community.empty_guides_hint',
      CommunityFeedTab.questions => 'community.empty_questions_hint',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.searchX, size: 32),
          const SizedBox(height: AppSpacing.md),
          Text(
            titleKey.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hintKey.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (onReset != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonal(
              onPressed: onReset,
              child: Text('community.show_all'.tr()),
            ),
          ],
        ],
      ),
    );
  }
}
