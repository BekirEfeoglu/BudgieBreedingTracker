import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_icon.dart';
import '../providers/community_post_providers.dart';
import '../widgets/community_post_list_screen.dart';

/// Screen showing all posts from a specific user.
class CommunityUserPostsScreen extends ConsumerWidget {
  const CommunityUserPostsScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CommunityPostListScreen(
      appBarTitle: 'community.user_posts'.tr(),
      postsAsync: ref.watch(userPostsProvider(userId)),
      onRefresh: () async => ref.invalidate(userPostsProvider(userId)),
      emptyIcon: const AppIcon(AppIcons.post),
      emptyTitle: 'community.no_user_posts'.tr(),
    );
  }
}
