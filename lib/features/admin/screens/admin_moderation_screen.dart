import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../data/models/community_comment_model.dart';
import '../../../data/models/community_post_model.dart';
import '../providers/admin_moderation_providers.dart';

class AdminModerationScreen extends ConsumerStatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  ConsumerState<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends ConsumerState<AdminModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('admin.moderation').tr(),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'community.posts'.tr()),
            Tab(text: 'community.comments'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PendingPostsTab(),
          _PendingCommentsTab(),
        ],
      ),
    );
  }
}

class _PendingPostsTab extends ConsumerWidget {
  const _PendingPostsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(adminPendingPostsProvider);

    return postsAsync.when(
      loading: () => const LoadingState(),
      error: (error, stack) => ErrorState(
        message: 'common.data_load_error'.tr(),
        onRetry: () => ref.invalidate(adminPendingPostsProvider),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Text(
              'admin.no_pending_reports'.tr(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: posts.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final post = posts[index];
            return _PendingPostCard(post: post);
          },
        );
      },
    );
  }
}

class _PendingPostCard extends ConsumerWidget {
  final CommunityPost post;

  const _PendingPostCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDeleting = ref.watch(adminModerationProvider).isLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: post.avatarUrl != null
                      ? NetworkImage(post.avatarUrl!)
                      : null,
                  child: post.avatarUrl == null
                      ? const Icon(LucideIcons.user)
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.username.isNotEmpty ? post.username : 'Unknown',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        post.createdAt != null
                            ? DateFormat.yMMMd().format(post.createdAt!)
                            : '',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: const Icon(LucideIcons.externalLink),
                  semanticLabel: 'admin.view_user'.tr(),
                  onPressed: () {
                    context.push('/admin/users/${post.userId}');
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (post.title != null && post.title!.isNotEmpty) ...[
              Text(
                post.title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(post.content),
            if (post.allImageUrls.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.allImageUrls.length,
                  separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    return Image.network(
                      post.allImageUrls[index],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(LucideIcons.check),
                  label: const Text('admin.approve_content').tr(),
                  style: TextButton.styleFrom(foregroundColor: AppColors.success),
                  onPressed: isDeleting
                      ? null
                      : () => ref.read(adminModerationProvider.notifier).approvePost(post.id),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton.icon(
                  icon: const Icon(LucideIcons.trash2),
                  label: const Text('common.delete').tr(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () => ref.read(adminModerationProvider.notifier).deletePost(post.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingCommentsTab extends ConsumerWidget {
  const _PendingCommentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(adminPendingCommentsProvider);

    return commentsAsync.when(
      loading: () => const LoadingState(),
      error: (error, stack) => ErrorState(
        message: 'common.data_load_error'.tr(),
        onRetry: () => ref.invalidate(adminPendingCommentsProvider),
      ),
      data: (comments) {
        if (comments.isEmpty) {
          return Center(
            child: Text(
              'admin.no_pending_reports'.tr(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: comments.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final comment = comments[index];
            return _PendingCommentCard(comment: comment);
          },
        );
      },
    );
  }
}

class _PendingCommentCard extends ConsumerWidget {
  final CommunityComment comment;

  const _PendingCommentCard({required this.comment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDeleting = ref.watch(adminModerationProvider).isLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: comment.avatarUrl != null
                      ? NetworkImage(comment.avatarUrl!)
                      : null,
                  child: comment.avatarUrl == null
                      ? const Icon(LucideIcons.user)
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.username.isNotEmpty ? comment.username : 'Unknown',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        comment.createdAt != null
                            ? DateFormat.yMMMd().format(comment.createdAt!)
                            : '',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: const Icon(LucideIcons.externalLink),
                  semanticLabel: 'admin.view_user'.tr(),
                  onPressed: () {
                    context.push('/admin/users/${comment.userId}');
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(comment.content),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(LucideIcons.check),
                  label: const Text('admin.approve_content').tr(),
                  style: TextButton.styleFrom(foregroundColor: AppColors.success),
                  onPressed: isDeleting
                      ? null
                      : () => ref.read(adminModerationProvider.notifier).approveComment(comment.id),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton.icon(
                  icon: const Icon(LucideIcons.trash2),
                  label: const Text('common.delete').tr(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () => ref.read(adminModerationProvider.notifier).deleteComment(comment.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
