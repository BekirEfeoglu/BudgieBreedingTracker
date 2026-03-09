import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/enums/admin_enums.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import 'admin_auth_utils.dart';

/// Admin feedback list — fetches all rows ordered by newest first.
final adminFeedbackProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      await requireAdmin(ref);
      final client = ref.watch(supabaseClientProvider);
      try {
        final result = await client
            .from(SupabaseConstants.feedbackTable)
            .select()
            .order('created_at', ascending: false)
            .limit(300);
        return List<Map<String, dynamic>>.from(result as List);
      } catch (e, st) {
        AppLogger.error('adminFeedbackProvider', e, st);
        rethrow;
      }
    });

/// Status filter for the admin feedback list (null = all).
class FeedbackStatusFilterNotifier extends Notifier<FeedbackStatus?> {
  @override
  FeedbackStatus? build() => null;
}

final feedbackStatusFilterProvider =
    NotifierProvider<FeedbackStatusFilterNotifier, FeedbackStatus?>(
      FeedbackStatusFilterNotifier.new,
    );
