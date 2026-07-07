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
import '../widgets/community_post_markdown.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import '../../../data/providers/user_role_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/community_feed_providers.dart';

/// Detail screen showing a single post with its comments.
class CommunityPostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const CommunityPostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState
    extends ConsumerState<CommunityPostDetailScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final postId = widget.postId;
    final postAsync = ref.watch(communityPostByIdProvider(postId));
    final commentState = ref.watch(commentListProvider(postId));
    final visibleComments = ref.watch(visibleCommentsProvider(postId));
    final isAdmin = ref.watch(isAdminProvider).value ?? false;

    ref.listen<CommentFormState>(commentFormProvider, (_, state) {
      if (!context.mounted) return;
      if (state.isSuccess) {
        ref.read(commentFormProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('community.comment_success'.tr())),
        );
        _scrollToBottom();
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
        actions: [
          if (isAdmin)
            postAsync.maybeWhen(
              data: (post) => post != null
                  ? AppIconButton(
                      icon: Icon(post.isPinned ? LucideIcons.pinOff : LucideIcons.pin),
                      semanticLabel: post.isPinned ? 'community.unpin_post'.tr() : 'community.pin_post'.tr(),
                      onPressed: () async {
                        await ref
                            .read(communityPostRepositoryProvider)
                            .togglePin(postId: post.id, isPinned: !post.isPinned);
                        ref.invalidate(communityPostByIdProvider(post.id));
                        ref.read(communityFeedProvider.notifier).refresh();
                      },
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
        ],
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
                controller: _scrollController,
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
                          child: LoadingState(),
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
                    const SliverToBoxAdapter(child: CommunityCommentSkeleton())
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
                  else if (visibleComments.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Center(
                          child: Text(
                            'community.no_comments'.tr(),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final comments = visibleComments;
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
                            child: LoadingState(),
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
                                    .read(commentListProvider(postId).notifier)
                                    .fetchMore(),
                                child: Text(
                                  'community.load_more_comments'.tr(),
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }, childCount: visibleComments.length + 1),
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
              color: theme.colorScheme.primary.withValues(alpha: 0.18),
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContentText(
                content: post.content,
                showFull: true,
                maxLines: 0,
              ),
              if (post.allImageUrls.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                for (final imageUrl in post.allImageUrls)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          memCacheWidth: 600,
                          placeholder: (_, __) => const SkeletonLoader(
                            height: 220,
                            width: double.infinity,
                          ),
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
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
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
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
