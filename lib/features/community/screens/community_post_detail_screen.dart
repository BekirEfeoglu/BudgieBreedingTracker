import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../providers/community_comment_providers.dart';
import '../providers/community_post_providers.dart';
import '../widgets/community_comment_input.dart';
import '../widgets/community_comment_tile.dart';
import '../widgets/community_post_card.dart';

/// Detail screen showing a single post with its comments.
class CommunityPostDetailScreen extends ConsumerWidget {
  final String postId;

  const CommunityPostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(communityPostByIdProvider(postId));
    final commentsAsync = ref.watch(commentsForPostProvider(postId));

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
            content: Text(
              state.error ?? 'community.comment_error'.tr(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text('community.post_detail'.tr())),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(communityPostByIdProvider(postId));
                ref.invalidate(commentsForPostProvider(postId));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Post
                  SliverToBoxAdapter(
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
                        return CommunityPostCard(
                          post: post,
                          showFullContent: true,
                        );
                      },
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
                            'community.comments'.tr(),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Comments list
                  commentsAsync.when(
                    loading: () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    error: (e, _) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'community.comment_error'.tr(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    data: (comments) {
                      if (comments.isEmpty) {
                        return SliverToBoxAdapter(
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
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => CommunityCommentTile(
                            key: ValueKey(comments[index].id),
                            comment: comments[index],
                          ),
                          childCount: comments.length,
                        ),
                      );
                    },
                  ),

                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: AppSpacing.xxxl),
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
