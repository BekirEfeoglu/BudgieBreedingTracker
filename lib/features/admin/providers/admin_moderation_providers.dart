import 'package:easy_localization/easy_localization.dart';
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

class AdminModerationState {
  const AdminModerationState({this.processingIds = const {}, this.error});

  final Set<String> processingIds;
  final String? error;

  bool contains(String id) => processingIds.contains(id);

  AdminModerationState copyWith({
    Set<String>? processingIds,
    String? error,
    bool clearError = false,
  }) => AdminModerationState(
    processingIds: processingIds ?? this.processingIds,
    error: clearError ? null : error ?? this.error,
  );
}

/// Notifier to handle moderation actions.
///
/// The state tracks per-card in-flight ids and the latest visible action
/// error. Decisions are sent to audited server RPCs so the content mutation
/// and admin_logs row commit atomically.
class AdminModerationNotifier extends Notifier<AdminModerationState> {
  @override
  AdminModerationState build() => const AdminModerationState();

  /// Whether [id]'s card has an approve/delete action in flight.
  bool isProcessing(String id) => state.contains(id);

  Future<void> approvePost(String postId) => _run(postId, (client) async {
    await _moderate(
      client,
      entityType: 'post',
      entityId: postId,
      action: 'approve',
    );
    ref.invalidate(adminPendingPostsProvider);
  });

  Future<void> deletePost(String postId) => _run(postId, (client) async {
    await _moderate(
      client,
      entityType: 'post',
      entityId: postId,
      action: 'delete',
    );
    ref.invalidate(adminPendingPostsProvider);
  });

  Future<void> approveComment(String commentId) =>
      _run(commentId, (client) async {
        await _moderate(
          client,
          entityType: 'comment',
          entityId: commentId,
          action: 'approve',
        );
        ref.invalidate(adminPendingCommentsProvider);
      });

  Future<void> deleteComment(String commentId) =>
      _run(commentId, (client) async {
        await _moderate(
          client,
          entityType: 'comment',
          entityId: commentId,
          action: 'delete',
        );
        ref.invalidate(adminPendingCommentsProvider);
      });

  void clearError() {
    if (state.error == null) return;
    state = state.copyWith(clearError: true);
  }

  Future<void> _moderate(
    SupabaseClient client, {
    required String entityType,
    required String entityId,
    required String action,
  }) async {
    await client.rpc(
      'admin_moderate_community_content',
      params: {
        'p_entity_type': entityType,
        'p_entity_id': entityId,
        'p_action': action,
      },
    );
  }

  /// Marks [id] as in-flight, runs [action], then clears it so only the
  /// acting card shows a busy/disabled state. Errors are logged and surfaced
  /// through [AdminModerationState.error].
  Future<void> _run(
    String id,
    Future<void> Function(SupabaseClient client) action,
  ) async {
    if (state.contains(id)) return; // ignore double-tap on the same item
    state = state.copyWith(
      processingIds: {...state.processingIds, id},
      clearError: true,
    );
    try {
      await requireAdmin(ref);
      await action(ref.read(supabaseClientProvider));
    } catch (e, st) {
      AppLogger.error('[AdminModeration] action failed for $id', e, st);
      state = state.copyWith(error: 'admin.action_error'.tr());
    } finally {
      state = state.copyWith(
        processingIds: state.processingIds.where((e) => e != id).toSet(),
      );
    }
  }
}

final adminModerationProvider =
    NotifierProvider<AdminModerationNotifier, AdminModerationState>(
      AdminModerationNotifier.new,
    );
