import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../../../core/widgets/loading_state.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../router/route_names.dart';
import '../../../data/providers/user_role_providers.dart'
    show isFounderProvider;
import '../providers/community_feed_providers.dart';
import '../providers/community_providers.dart';
import 'community_feed_overlays.dart';
import 'community_feed_states.dart';
import 'community_following_list.dart';
import 'community_quick_composer.dart';
import 'community_section_bar.dart';
import 'community_story_strip.dart';
import 'community_swipeable_post_card.dart';

part 'community_feed_items.dart';
part 'community_feed_guides.dart';

/// Scrollable feed list with infinite scroll and pull-to-refresh.
class CommunityFeedList extends ConsumerStatefulWidget {
  final CommunityFeedTab tab;

  const CommunityFeedList({super.key, this.tab = CommunityFeedTab.explore});

  @override
  ConsumerState<CommunityFeedList> createState() => _CommunityFeedListState();
}

class _CommunityFeedListState extends ConsumerState<CommunityFeedList> {
  static const _swipeOnboardingKey = 'pref_swipe_onboarding_shown';
  static const _scrollToTopThreshold = 600.0;

  final _scrollController = ScrollController();
  Timer? _swipeHintTimer;
  int _lastSeenCount = 0;
  int _newPostCount = 0;
  bool _showSwipeHint = false;
  bool _showScrollToTop = false;

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
    final shouldShow = _scrollController.offset > _scrollToTopThreshold;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
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

    return _buildFeedScrollView(
      context: context,
      ref: ref,
      tab: widget.tab,
      scrollController: _scrollController,
      mounted: mounted,
      newPostCount: _newPostCount,
      lastSeenCount: _lastSeenCount,
      showSwipeHint: _showSwipeHint,
      showScrollToTop: _showScrollToTop,
      onUpdateNewPostCount: (v) => setState(() => _newPostCount = v),
      onUpdateLastSeenCount: (v) => _lastSeenCount = v,
      onScrollToTop: _scrollToTopAndDismiss,
      onDismissSwipeHint: _dismissSwipeHint,
      onChangeSort: _changeSort,
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
