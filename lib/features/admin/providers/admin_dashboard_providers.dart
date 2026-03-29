import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../auth/providers/auth_providers.dart';
import '../constants/admin_constants.dart';
import 'admin_auth_utils.dart';
import 'admin_models.dart';

/// System alerts provider (unresolved alerts).
final adminSystemAlertsProvider = FutureProvider<List<SystemAlert>>((
  ref,
) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  final result = await client
      .from(SupabaseConstants.systemAlertsTable)
      .select()
      .eq('is_active', true)
      .eq('is_acknowledged', false)
      .order('created_at', ascending: false)
      .limit(AdminConstants.maxAlertsLimit);

  return (result as List)
      .map((row) => SystemAlert.fromJson(row as Map<String, dynamic>))
      .toList();
});

/// Pending content review count (posts + comments needing moderation).
final adminPendingReviewCountProvider = FutureProvider<int>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  final postsResult = await client
      .from(SupabaseConstants.communityPostsTable)
      .select('id')
      .eq('is_deleted', false)
      .eq('needs_review', true);

  final commentsResult = await client
      .from(SupabaseConstants.communityCommentsTable)
      .select('id')
      .eq('is_deleted', false)
      .eq('needs_review', true);

  return (postsResult as List).length + (commentsResult as List).length;
});

/// Recent admin actions provider (last [AdminConstants.recentActionsLimit] logs).
final recentAdminActionsProvider = FutureProvider<List<AdminLog>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  final result = await client
      .from(SupabaseConstants.adminLogsTable)
      .select()
      .order('created_at', ascending: false)
      .limit(AdminConstants.recentActionsLimit);

  return (result as List)
      .map((row) => AdminLog.fromJson(row as Map<String, dynamic>))
      .toList();
});

/// System settings provider with metadata per setting.
final adminSystemSettingsProvider =
    FutureProvider<Map<String, Map<String, dynamic>>>((ref) async {
      await requireAdmin(ref);
      final client = ref.watch(supabaseClientProvider);

      final result = await client
          .from(SupabaseConstants.systemSettingsTable)
          .select();

      final settings = <String, Map<String, dynamic>>{};
      for (final row in (result as List)) {
        final key = row['key'] as String;
        settings[key] = {
          'value': row['value'],
          'updated_at': row['updated_at'] as String?,
          'category': row['category'] as String?,
          'updated_by': row['updated_by'] as String?,
        };
      }
      return settings;
    });
