import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../providers/community_post_providers.dart';
import '../widgets/community_feed_states.dart';
import '../widgets/community_post_card.dart';

/// Discovery feed for a single tag / mutation tag.
///
/// Opened by tapping a tag chip (`PostTagWrap`) or a mutation chip on a post
/// card. Shows every post carrying [tag] in its free `tags` or bird-derived
/// `mutation_tags`, newest first.
class CommunityTagFeedScreen extends ConsumerWidget {
  const CommunityTagFeedScreen({super.key, required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(communityTagFeedProvider(tag));

    return Scaffold(
      appBar: AppBar(title: Text('#$tag')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(communityTagFeedProvider(tag).future),
        child: postsAsync.when(
          loading: () => const CommunityFeedSkeleton(),
          error: (_, __) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              app.ErrorState(
                message: 'community.feed_load_error'.tr(),
                onRetry: () => ref.invalidate(communityTagFeedProvider(tag)),
              ),
            ],
          ),
          data: (posts) {
            if (posts.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xxxl,
                ),
                children: [
                  EmptyState(
                    icon: const AppIcon(AppIcons.community),
                    title: 'community.tag_feed_empty_title'.tr(
                      namedArgs: {'tag': tag},
                    ),
                    subtitle: 'community.tag_feed_empty_hint'.tr(),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) =>
                  CommunityPostCard(key: ValueKey(posts[index].id), post: posts[index]),
            );
          },
        ),
      ),
    );
  }
}
