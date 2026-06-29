import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../data/models/community_comment_model.dart';
import '../../../data/models/community_post_model.dart';
import '../../../shared/providers/auth.dart';
import 'admin_auth_utils.dart';

/// Provider that fetches pending community posts that need review.
final adminPendingPostsProvider =
    FutureProvider.autoDispose<List<CommunityPost>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  final result = await client
      .from(SupabaseConstants.communityPostsTable)
      .select()
      .eq(SupabaseConstants.colIsDeleted, false)
      .eq(SupabaseConstants.colNeedsReview, true)
      .order(SupabaseConstants.colCreatedAt, ascending: false);

  return (result as List)
      .map((r) => CommunityPost.fromJson(r as Map<String, dynamic>))
      .toList();
});

/// Provider that fetches pending community comments that need review.
final adminPendingCommentsProvider =
    FutureProvider.autoDispose<List<CommunityComment>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  final result = await client
      .from(SupabaseConstants.communityCommentsTable)
      .select()
      .eq(SupabaseConstants.colIsDeleted, false)
      .eq(SupabaseConstants.colNeedsReview, true)
      .order(SupabaseConstants.colCreatedAt, ascending: false);

  return (result as List)
      .map((r) => CommunityComment.fromJson(r as Map<String, dynamic>))
      .toList();
});

/// Notifier to handle moderation actions.
class AdminModerationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state is idle.
  }

  Future<void> approvePost(String postId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);
      await client
          .from(SupabaseConstants.communityPostsTable)
          .update({SupabaseConstants.colNeedsReview: false})
          .eq(SupabaseConstants.colId, postId);
      
      ref.invalidate(adminPendingPostsProvider);
    });
  }

  Future<void> deletePost(String postId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);
      await client
          .from(SupabaseConstants.communityPostsTable)
          .update({
            SupabaseConstants.colIsDeleted: true,
            SupabaseConstants.colNeedsReview: false,
          })
          .eq(SupabaseConstants.colId, postId);
      
      ref.invalidate(adminPendingPostsProvider);
    });
  }

  Future<void> approveComment(String commentId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);
      await client
          .from(SupabaseConstants.communityCommentsTable)
          .update({SupabaseConstants.colNeedsReview: false})
          .eq(SupabaseConstants.colId, commentId);
      
      ref.invalidate(adminPendingCommentsProvider);
    });
  }

  Future<void> deleteComment(String commentId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);
      await client
          .from(SupabaseConstants.communityCommentsTable)
          .update({
            SupabaseConstants.colIsDeleted: true,
            SupabaseConstants.colNeedsReview: false,
          })
          .eq(SupabaseConstants.colId, commentId);
      
      ref.invalidate(adminPendingCommentsProvider);
    });
  }
}

final adminModerationProvider =
    AsyncNotifierProvider<AdminModerationNotifier, void>(
  AdminModerationNotifier.new,
);
