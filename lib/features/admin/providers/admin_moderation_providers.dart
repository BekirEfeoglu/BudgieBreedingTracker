import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
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
///
/// State is the set of post/comment ids that currently have an in-flight
/// approve/delete action, so each card locks only itself instead of one global
/// flag freezing the whole queue while any single action runs (admin.md §Race
/// — "aynı entity'ye ikinci aksiyon: disable button + spinner").
class AdminModerationNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// Whether [id]'s card has an approve/delete action in flight.
  bool isProcessing(String id) => state.contains(id);

  Future<void> approvePost(String postId) => _run(postId, (client) async {
        await client
            .from(SupabaseConstants.communityPostsTable)
            .update({SupabaseConstants.colNeedsReview: false})
            .eq(SupabaseConstants.colId, postId);
        // Record the moderation decision in admin_logs (admin.md §Moderation
        // Queue — "Decision audit log'a düşer").
        await logAdminAction(
          client,
          ref.read(currentUserIdProvider),
          'community_post_approved',
          details: {'post_id': postId},
        );
        ref.invalidate(adminPendingPostsProvider);
      });

  Future<void> deletePost(String postId) => _run(postId, (client) async {
        await client
            .from(SupabaseConstants.communityPostsTable)
            .update({
              SupabaseConstants.colIsDeleted: true,
              SupabaseConstants.colNeedsReview: false,
            })
            .eq(SupabaseConstants.colId, postId);
        await logAdminAction(
          client,
          ref.read(currentUserIdProvider),
          'community_post_deleted',
          details: {'post_id': postId},
        );
        ref.invalidate(adminPendingPostsProvider);
      });

  Future<void> approveComment(String commentId) =>
      _run(commentId, (client) async {
        await client
            .from(SupabaseConstants.communityCommentsTable)
            .update({SupabaseConstants.colNeedsReview: false})
            .eq(SupabaseConstants.colId, commentId);
        await logAdminAction(
          client,
          ref.read(currentUserIdProvider),
          'community_comment_approved',
          details: {'comment_id': commentId},
        );
        ref.invalidate(adminPendingCommentsProvider);
      });

  Future<void> deleteComment(String commentId) =>
      _run(commentId, (client) async {
        await client
            .from(SupabaseConstants.communityCommentsTable)
            .update({
              SupabaseConstants.colIsDeleted: true,
              SupabaseConstants.colNeedsReview: false,
            })
            .eq(SupabaseConstants.colId, commentId);
        await logAdminAction(
          client,
          ref.read(currentUserIdProvider),
          'community_comment_deleted',
          details: {'comment_id': commentId},
        );
        ref.invalidate(adminPendingCommentsProvider);
      });

  /// Marks [id] as in-flight, runs [action], then clears it — so only the
  /// acting card shows a busy/disabled state. Errors are logged (not surfaced
  /// as a global error) and never leave [id] stuck in the processing set.
  Future<void> _run(
    String id,
    Future<void> Function(SupabaseClient client) action,
  ) async {
    if (state.contains(id)) return; // ignore double-tap on the same item
    state = {...state, id};
    try {
      await requireAdmin(ref);
      await action(ref.read(supabaseClientProvider));
    } catch (e, st) {
      AppLogger.error('[AdminModeration] action failed for $id', e, st);
    } finally {
      state = state.where((e) => e != id).toSet();
    }
  }
}

final adminModerationProvider =
    NotifierProvider<AdminModerationNotifier, Set<String>>(
  AdminModerationNotifier.new,
);
