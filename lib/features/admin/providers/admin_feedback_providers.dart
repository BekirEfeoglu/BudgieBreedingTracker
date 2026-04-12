import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/enums/admin_enums.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import '../constants/admin_constants.dart';
import 'admin_auth_utils.dart';
import 'admin_models.dart';

/// Query state for admin feedback list (server-side filtering).
class FeedbackQueryNotifier extends Notifier<FeedbackQuery> {
  @override
  FeedbackQuery build() =>
      const FeedbackQuery(limit: AdminConstants.feedbackPageSize);
}

final feedbackQueryProvider =
    NotifierProvider<FeedbackQueryNotifier, FeedbackQuery>(
  FeedbackQueryNotifier.new,
);

/// Admin feedback list with server-side filtering via [FeedbackQuery].
final adminFeedbackProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      await requireAdmin(ref);
      final client = ref.watch(supabaseClientProvider);
      final query = ref.watch(feedbackQueryProvider);

      // Build filter chain before order/limit (PostgREST filter methods are
      // only available on PostgrestFilterBuilder, not PostgrestTransformBuilder).
      var filterRequest = client
          .from(SupabaseConstants.feedbackTable)
          .select();

      if (query.statusFilter != null) {
        filterRequest = filterRequest.eq(
          'status',
          query.statusFilter!.toJson(),
        );
      }

      if (query.searchQuery.isNotEmpty) {
        // Sanitize PostgREST special characters to prevent filter injection.
        final sanitized = query.searchQuery
            .replaceAll(RegExp(r'[\x00-\x1f]'), '')
            .replaceAll(RegExp(r'[,.()\[\]\\]'), '')
            .replaceAll('%', r'\%')
            .replaceAll('_', r'\_');
        if (sanitized.isNotEmpty) {
          filterRequest = filterRequest.or(
            'message.ilike.%$sanitized%,subject.ilike.%$sanitized%',
          );
        }
      }

      final result = await filterRequest
          .order('created_at', ascending: false)
          .limit(query.limit);
      return List<Map<String, dynamic>>.from(result as List);
    });

/// Status filter for the admin feedback list (null = all).
/// Kept for backward compatibility — updates [feedbackQueryProvider] internally.
class FeedbackStatusFilterNotifier extends Notifier<FeedbackStatus?> {
  @override
  FeedbackStatus? build() => null;
}

final feedbackStatusFilterProvider =
    NotifierProvider<FeedbackStatusFilterNotifier, FeedbackStatus?>(
      FeedbackStatusFilterNotifier.new,
    );

/// State for admin feedback update operations.
class AdminFeedbackActionState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const AdminFeedbackActionState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  AdminFeedbackActionState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) => AdminFeedbackActionState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    isSuccess: isSuccess ?? this.isSuccess,
  );
}

/// Notifier that handles feedback update Supabase operations.
class AdminFeedbackActionNotifier extends Notifier<AdminFeedbackActionState> {
  @override
  AdminFeedbackActionState build() => const AdminFeedbackActionState();

  /// Update feedback status, priority, and optional admin response.
  Future<bool> updateFeedback({
    required String feedbackId,
    required String status,
    required String priority,
    String? adminResponse,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);
      final updates = <String, dynamic>{
        'status': status,
        'priority': priority,
        if (adminResponse != null && adminResponse.isNotEmpty)
          'admin_response': adminResponse,
      };
      await client
          .from(SupabaseConstants.feedbackTable)
          .update(updates)
          .eq('id', feedbackId);
      ref.invalidate(adminFeedbackProvider);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e, st) {
      AppLogger.error('AdminFeedbackAction.updateFeedback', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset() => state = const AdminFeedbackActionState();
}

/// Provider for admin feedback update actions.
final adminFeedbackActionProvider =
    NotifierProvider<AdminFeedbackActionNotifier, AdminFeedbackActionState>(
      AdminFeedbackActionNotifier.new,
    );
