import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../../../data/models/community_post_model.dart';
import 'community_feed_states.dart';
import 'community_post_card.dart';

/// Shared scaffold for screens that display a list of [CommunityPost] items.
///
/// Handles loading/error/empty/data states uniformly, used by
/// [CommunityBookmarksScreen] and [CommunityUserPostsScreen].
class CommunityPostListScreen extends ConsumerWidget {
  const CommunityPostListScreen({
    super.key,
    required this.appBarTitle,
    required this.postsAsync,
    required this.onRefresh,
    required this.emptyIcon,
    required this.emptyTitle,
    this.emptySubtitle,
  });

  final String appBarTitle;
  final AsyncValue<List<CommunityPost>> postsAsync;
  final Future<void> Function() onRefresh;
  final Widget emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: postsAsync.when(
        loading: () => const CommunityFeedSkeleton(),
        error: (e, _) => Center(
          child: app.ErrorState(
            message: 'common.data_load_error'.tr(),
            onRetry: onRefresh,
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: EmptyState(
                icon: emptyIcon,
                title: emptyTitle,
                subtitle: emptySubtitle,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xxxl * 2,
              ),
              itemCount: posts.length,
              itemBuilder: (_, i) => CommunityPostCard(
                key: ValueKey(posts[i].id),
                post: posts[i],
              ),
            ),
          );
        },
      ),
    );
  }
}
