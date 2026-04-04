import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/utils/logger.dart';
import '../../../data/models/community_comment_model.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/services/moderation/content_moderation_service.dart';
import 'community_feed_providers.dart';
import 'community_moderation_providers.dart';

// ---------------------------------------------------------------------------
// Comments for a post
// ---------------------------------------------------------------------------

final commentsForPostProvider =
    FutureProvider.family<List<CommunityComment>, String>((ref, postId) async {
      final repo = ref.watch(communityCommentRepositoryProvider);
      final userId = ref.watch(currentUserIdProvider);

      try {
        return await repo.getByPost(postId: postId, currentUserId: userId);
      } catch (e, st) {
        AppLogger.error('commentsForPostProvider', e, st);
        return [];
      }
    });

// ---------------------------------------------------------------------------
// Comment form
// ---------------------------------------------------------------------------

class CommentFormState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const CommentFormState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  CommentFormState copyWith({bool? isLoading, String? error, bool? isSuccess}) {
    return CommentFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class CommentFormNotifier extends Notifier<CommentFormState> {
  @override
  CommentFormState build() => const CommentFormState();

  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == 'anonymous') {
        state = state.copyWith(
          isLoading: false,
          error: 'community.not_authenticated'.tr(),
        );
        return;
      }

      // Content length validation
      const maxCommentLength = 1000;
      if (content.trim().length > maxCommentLength) {
        state = state.copyWith(
          isLoading: false,
          error: 'community.content_too_long'.tr(),
        );
        return;
      }

      // Content moderation check (Apple Guideline 1.2)
      final moderationService = ref.read(contentModerationServiceProvider);
      final modResult = await moderationService.checkText(content);
      if (!modResult.isAllowed) {
        state = state.copyWith(
          isLoading: false,
          error: ContentModerationService.localizedError(
            modResult.rejectionReason,
          ),
        );
        return;
      }

      final repo = ref.read(communityCommentRepositoryProvider);
      await repo.create(
        postId: postId,
        userId: userId,
        content: content,
        needsReview: modResult.needsReview,
      );

      ref.read(communityFeedProvider.notifier).incrementCommentCount(postId);
      ref.invalidate(commentsForPostProvider(postId));

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('CommentFormNotifier', e, st);
      Sentry.captureException(e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const CommentFormState();
}

final commentFormProvider =
    NotifierProvider<CommentFormNotifier, CommentFormState>(
      CommentFormNotifier.new,
    );

// ---------------------------------------------------------------------------
// Comment delete
// ---------------------------------------------------------------------------

class CommentDeleteNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<bool> deleteComment({
    required String commentId,
    required String postId,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == 'anonymous') return false;

    try {
      final repo = ref.read(communityCommentRepositoryProvider);
      await repo.delete(commentId: commentId, userId: userId);
      ref.read(communityFeedProvider.notifier).decrementCommentCount(postId);
      ref.invalidate(commentsForPostProvider(postId));
      return true;
    } catch (e, st) {
      AppLogger.error('CommentDeleteNotifier', e, st);
      Sentry.captureException(e, stackTrace: st);
      return false;
    }
  }
}

final commentDeleteProvider = NotifierProvider<CommentDeleteNotifier, void>(
  CommentDeleteNotifier.new,
);

// ---------------------------------------------------------------------------
// Comment like toggle
// ---------------------------------------------------------------------------

class CommentLikeToggleNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> toggleCommentLike({
    required String commentId,
    required String postId,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == 'anonymous') return;

    try {
      final repo = ref.read(communitySocialRepositoryProvider);
      await repo.toggleCommentLike(userId: userId, commentId: commentId);
      ref.invalidate(commentsForPostProvider(postId));
    } catch (e, st) {
      AppLogger.error('CommentLikeToggleNotifier', e, st);
      Sentry.captureException(e, stackTrace: st);
    }
  }
}

final commentLikeToggleProvider =
    NotifierProvider<CommentLikeToggleNotifier, void>(
      CommentLikeToggleNotifier.new,
    );
