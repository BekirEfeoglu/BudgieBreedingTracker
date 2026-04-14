import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_icon.dart';
import '../providers/community_post_providers.dart';
import '../widgets/community_post_list_screen.dart';

/// Screen showing the user's bookmarked community posts.
class CommunityBookmarksScreen extends ConsumerWidget {
  const CommunityBookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CommunityPostListScreen(
      appBarTitle: 'community.bookmarks'.tr(),
      postsAsync: ref.watch(bookmarkedPostsProvider),
      onRefresh: () async => ref.invalidate(bookmarkedPostsProvider),
      emptyIcon: const AppIcon(AppIcons.bookmark),
      emptyTitle: 'community.no_bookmarks'.tr(),
      emptySubtitle: 'community.no_bookmarks_hint'.tr(),
    );
  }
}
