import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../../../data/providers/auth_state_providers.dart';
import '../../../router/route_names.dart';
import '../providers/community_feed_providers.dart';
import '../providers/community_providers.dart';
import 'community_feed_overlays.dart';
import 'community_feed_states.dart';
import 'community_following_list.dart';
import 'community_quick_composer.dart';
import 'community_section_bar.dart';
import 'community_story_strip.dart';
import 'community_swipeable_post_card.dart';

/// Scrollable feed list with infinite scroll and pull-to-refresh.
class CommunityFeedList extends ConsumerStatefulWidget {
  final CommunityFeedTab tab;

  const CommunityFeedList({super.key, this.tab = CommunityFeedTab.explore});

  @override
  ConsumerState<CommunityFeedList> createState() => _CommunityFeedListState();
}

class _CommunityFeedListState extends ConsumerState<CommunityFeedList> {
  static const _swipeOnboardingKey = 'pref_swipe_onboarding_shown';

  final _scrollController = ScrollController();
  Timer? _swipeHintTimer;
  int _lastSeenCount = 0;
  int _newPostCount = 0;
  bool _showSwipeHint = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkSwipeOnboarding();
  }

  @override
  void dispose() {
    _swipeHintTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkSwipeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_swipeOnboardingKey) == true) return;
      if (!mounted) return;
      setState(() => _showSwipeHint = true);
      await prefs.setBool(_swipeOnboardingKey, true);
      _swipeHintTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showSwipeHint = false);
      });
    } catch (_) {
      // SharedPreferences unavailable — skip onboarding
    }
  }

  void _dismissSwipeHint() {
    if (_showSwipeHint) setState(() => _showSwipeHint = false);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      ref.read(communityFeedProvider.notifier).fetchMore();
    }
  }

  void _scrollToTopAndDismiss() {
    setState(() {
      _newPostCount = 0;
      _lastSeenCount = ref.read(communityFeedProvider).posts.length;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Following tab shows a people list, not a post feed
    if (widget.tab == CommunityFeedTab.following) {
      return const CommunityFollowingList();
    }

    final feedState = ref.watch(communityFeedProvider);
    final posts = feedState.posts;

    // Detect new posts arriving while user is scrolled down
    ref.listen<FeedState>(communityFeedProvider, (prev, next) {
      if (prev == null || next.isLoading) return;
      final prevLen = prev.posts.length;
      final nextLen = next.posts.length;
      // Only show banner if new posts appeared at the beginning (refresh),
      // not from pagination (fetchMore appends at the end).
      if (nextLen > prevLen && _lastSeenCount > 0) {
        final isScrolledDown = _scrollController.hasClients &&
            _scrollController.position.pixels > 200;
        if (isScrolledDown) {
          setState(() => _newPostCount = nextLen - _lastSeenCount);
        }
      }
      _lastSeenCount = nextLen;
    });

    // Initialize last seen count on first build
    if (_lastSeenCount == 0 && posts.isNotEmpty) {
      _lastSeenCount = posts.length;
    }

    final currentUserId = ref.watch(currentUserIdProvider);
    final visiblePosts = ref.watch(communityVisiblePostsProvider(widget.tab));
    final isExplore = widget.tab == CommunityFeedTab.explore;
    final showExploreExtras = isExplore && visiblePosts.isNotEmpty;
    final exploreSort = ref.watch(exploreSortProvider);
    final defaultCreateType = widget.tab == CommunityFeedTab.guides
        ? CommunityPostType.guide
        : CommunityPostType.general;

    if (feedState.error != null && posts.isEmpty) {
      return Center(
        child: app.ErrorState(
          message: '${'community.feed_load_error'.tr()}: ${feedState.error}',
          onRetry: () => ref.read(communityFeedProvider.notifier).refresh(),
        ),
      );
    }

    if (feedState.isLoading && posts.isEmpty) {
      return const CommunityFeedSkeleton();
    }

    return Stack(
      children: [
      RefreshIndicator(
      onRefresh: () async {
        await ref.read(communityFeedProvider.notifier).refresh();
        if (!mounted) return;
        setState(() {
          _newPostCount = 0;
          _lastSeenCount = ref.read(communityFeedProvider).posts.length;
        });
      },
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // 1. Quick Composer
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: CommunityQuickComposer(
                currentUserId: currentUserId,
                onCreatePost: () =>
                    context.push(_buildCreatePostRoute(defaultCreateType)),
                onCreateTypedPost: (type) =>
                    context.push(_buildCreatePostRoute(type)),
              ),
            ),
          ),
          // 2. Story Strip (explore only)
          if (isExplore && showExploreExtras)
            SliverToBoxAdapter(
              child: CommunityStoryStrip(
                stories: CommunityStoryStrip.fromPosts(visiblePosts),
                onCreatePost: () =>
                    context.push(_buildCreatePostRoute(defaultCreateType)),
              ),
            ),
          // 3. Section Bar
          if (visiblePosts.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
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
          // 4. Empty states or post list
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
                  actionLabel: 'community.create_post'.tr(),
                  onAction: () => context.push(AppRoutes.communityCreatePost),
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
                child: FilteredFeedEmptyState(
                  tab: widget.tab,
                  onReset: widget.tab == CommunityFeedTab.explore
                      ? null
                      : () => context.go(AppRoutes.community),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xxxl * 3,
              ),
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
                    return SwipeablePostCard(
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
    ),
      // "New posts" floating banner with slide-in animation
      Positioned(
        top: AppSpacing.sm,
        left: 0,
        right: 0,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          offset: _newPostCount > 0 ? Offset.zero : const Offset(0, -2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _newPostCount > 0 ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: _newPostCount == 0,
              child: NewPostsBanner(
                count: _newPostCount,
                onTap: _scrollToTopAndDismiss,
              ),
            ),
          ),
        ),
      ),
      // Swipe onboarding hint
      if (_showSwipeHint)
        Positioned(
          bottom: AppSpacing.xxxl * 3 + AppSpacing.lg,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          child: GestureDetector(
            onTap: _dismissSwipeHint,
            child: SwipeOnboardingHint(onDismiss: _dismissSwipeHint),
          ),
        ),
      ],
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

  String _buildCreatePostRoute(CommunityPostType type) {
    return type == CommunityPostType.general
        ? AppRoutes.communityCreatePost
        : '${AppRoutes.communityCreatePost}?type=${type.toJson()}';
  }
}


