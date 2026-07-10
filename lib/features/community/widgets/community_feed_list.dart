import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/utils/logger.dart';
import '../../../router/route_names.dart';
import '../../../data/providers/user_role_providers.dart'
    show isFounderProvider;
import '../providers/community_feed_providers.dart';
import '../providers/community_providers.dart';
import 'community_avatar.dart';
import 'community_feed_overlays.dart';
import 'community_feed_states.dart';
import 'community_story_strip.dart';
import 'community_swipeable_post_card.dart';

part 'community_feed_items.dart';
part 'community_feed_guides.dart';
part 'community_feed_guide_cards.dart';

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
    } catch (e) {
      AppLogger.warning('Community swipe onboarding unavailable: $e');
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
    ref.read(communityNewPostCountProvider.notifier).reset();
    _lastSeenCount = ref.read(communityFeedProvider).posts.length;
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
    // NOTE: communityNewPostCountProvider is intentionally NOT watched here.
    // It's watched inside _NewPostsBannerOverlay so a foreign user's post
    // rebuilds only the floating banner, not the whole feed scroll view (which
    // would re-run communityVisiblePostsProvider for a background insert).
    return _buildFeedScrollView(
      context: context,
      ref: ref,
      tab: widget.tab,
      scrollController: _scrollController,
      mounted: mounted,
      lastSeenCount: _lastSeenCount,
      showSwipeHint: _showSwipeHint,
      onUpdateNewPostCount: (_) =>
          ref.read(communityNewPostCountProvider.notifier).reset(),
      onUpdateLastSeenCount: (v) => _lastSeenCount = v,
      onScrollToTop: _scrollToTopAndDismiss,
      onDismissSwipeHint: _dismissSwipeHint,
    );
  }
}
