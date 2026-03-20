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

/// Screen showing all posts from a specific user.
class CommunityUserPostsScreen extends ConsumerWidget {
  final String userId;

  const CommunityUserPostsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userPostsProvider(userId));

    return Scaffold(
      appBar: AppBar(title: Text('community.user_posts'.tr())),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: app.ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(userPostsProvider(userId)),
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: EmptyState(
                icon: const AppIcon(AppIcons.post),
                title: 'community.no_user_posts'.tr(),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userPostsProvider(userId)),
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
