import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../providers/community_post_providers.dart';
import '../widgets/community_post_card.dart';

/// Screen showing the user's bookmarked community posts.
class CommunityBookmarksScreen extends ConsumerWidget {
  const CommunityBookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(bookmarkedPostsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('community.bookmarks'.tr())),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: app.ErrorState(
            message: 'common.data_load_error'.tr(),
            onRetry: () => ref.invalidate(bookmarkedPostsProvider),
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: EmptyState(
                icon: const AppIcon(AppIcons.bookmark),
                title: 'community.no_bookmarks'.tr(),
                subtitle: 'community.no_bookmarks_hint'.tr(),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(bookmarkedPostsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xxxl * 2,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) => CommunityPostCard(
                key: ValueKey(posts[index].id),
                post: posts[index],
              ),
            ),
          );
        },
      ),
    );
  }
}
