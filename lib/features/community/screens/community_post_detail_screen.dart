import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../providers/community_comment_providers.dart';
import '../providers/community_post_providers.dart';
import '../providers/community_providers.dart';
import '../widgets/community_comment_input.dart';
import '../widgets/community_comment_tile.dart';
import '../widgets/community_feed_states.dart';
import '../widgets/community_post_card.dart';

/// Detail screen showing a single post with its comments.
class CommunityPostDetailScreen extends ConsumerWidget {
  final String postId;

  const CommunityPostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(communityPostByIdProvider(postId));
    final commentState = ref.watch(commentListProvider(postId));

    ref.listen<CommentFormState>(commentFormProvider, (_, state) {
      if (!context.mounted) return;
      if (state.isSuccess) {
        ref.read(commentFormProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('community.comment_success'.tr())),
        );
      }
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'community.comment_error'.tr()),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          postAsync.maybeWhen(
            data: (post) => post?.postType == CommunityPostType.guide
                ? 'community.tab_guides'.tr()
                : 'community.post_detail'.tr(),
            orElse: () => 'community.post_detail'.tr(),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(communityPostByIdProvider(postId));
                await ref
                    .read(commentListProvider(postId).notifier)
                    .fetchInitial();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  // Post
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        0,
                      ),
                      child: postAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: app.ErrorState(
                            message: 'common.data_load_error'.tr(),
                            onRetry: () => ref.invalidate(
                              communityPostByIdProvider(postId),
                            ),
                          ),
                        ),
                        data: (post) {
                          if (post == null) {
                            return Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Center(
                                child: Text('community.post_not_found'.tr()),
                              ),
                            );
                          }
                          if (post.postType == CommunityPostType.guide) {
                            return _GuideDetailArticle(post: post);
                          }

                          return CommunityPostCard(
                            post: post,
                            showFullContent: true,
                            isInteractive: false,
                          );
                        },
                      ),
                    ),
                  ),

                  // Divider + Comments header
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          child: Text(
                            postAsync.maybeWhen(
                              data: (post) =>
                                  post?.postType == CommunityPostType.guide
                                  ? 'community.guide_discussion_title'.tr()
                                  : 'community.comments'.tr(),
                              orElse: () => 'community.comments'.tr(),
                            ),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Comments list
                  if (commentState.isLoading)
                    const SliverToBoxAdapter(
                      child: CommunityCommentSkeleton(),
                    )
                  else if (commentState.error != null &&
                      commentState.comments.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: app.ErrorState(
                          message: 'community.comment_error'.tr(),
                          onRetry: () => ref
                              .read(commentListProvider(postId).notifier)
                              .fetchInitial(),
                        ),
                      ),
                    )
                  else if (commentState.comments.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Center(
                          child: Text(
                            'community.no_comments'.tr(),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final comments = commentState.comments;
                          if (index < comments.length) {
                            return CommunityCommentTile(
                              key: ValueKey(comments[index].id),
                              comment: comments[index],
                            );
                          }
                          // Load-more footer
                          if (commentState.isLoadingMore) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (commentState.hasMore) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              child: Center(
                                child: TextButton(
                                  onPressed: () => ref
                                      .read(
                                        commentListProvider(postId).notifier,
                                      )
                                      .fetchMore(),
                                  child: Text(
                                    'community.load_more_comments'.tr(),
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        childCount: commentState.comments.length + 1,
                      ),
                    ),

                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: AppSpacing.xl),
                  ),
                ],
              ),
            ),
          ),

          // Comment input
          CommunityCommentInput(postId: postId),
        ],
      ),
    );
  }
}

class _GuideDetailArticle extends StatelessWidget {
  const _GuideDetailArticle({required this.post});

  final CommunityPost post;

  int get _readMinutes {
    final totalWords = '${post.title ?? ''} ${post.content}'
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .length;
    return (totalWords / 180).ceil().clamp(1, 99);
  }

  List<String> get _outlineItems {
    return post.content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.startsWith('#'))
        .map((line) => line.replaceFirst(RegExp(r'^#+\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .take(4)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.14),
                theme.colorScheme.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'community.guide_detail_kicker'.tr().toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                post.title ?? 'community.tab_guides'.tr(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${post.username} • ${formatCommunityDate(post.createdAt)} • ${'community.guide_read_time'.tr(args: ['$_readMinutes'])}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _GuideMetaChip(
                    label: 'community.guide_meta_read'.tr(
                      args: ['$_readMinutes'],
                    ),
                  ),
                  _GuideMetaChip(
                    label: 'community.guide_meta_comments'.tr(
                      args: ['${post.commentCount}'],
                    ),
                  ),
                  if (post.tags.isNotEmpty)
                    _GuideMetaChip(
                      label: 'community.guide_meta_tags'.tr(
                        args: ['${post.tags.length}'],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (_outlineItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _GuideOutlineCard(items: _outlineItems),
        ],
        const SizedBox(height: AppSpacing.lg),
        CommunityPostCard(
          post: post,
          showFullContent: true,
          isInteractive: false,
        ),
      ],
    );
  }
}

class _GuideMetaChip extends StatelessWidget {
  const _GuideMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GuideOutlineCard extends StatelessWidget {
  const _GuideOutlineCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'community.guide_outline_title'.tr(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < items.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    items[i],
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
            if (i < items.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
