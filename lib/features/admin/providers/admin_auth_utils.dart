import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';

/// Verifies the current user is an admin. Throws if not.
///
/// Shared utility used by admin providers and action notifiers
/// to enforce admin permission checks at the data layer.
Future<void> requireAdmin(Ref ref) async {
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserIdProvider);
  if (userId == 'anonymous') {
    throw Exception('admin.auth_required'.tr());
  }
  final result = await client
      .from(SupabaseConstants.adminUsersTable)
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();
  if (result == null) {
    throw Exception('admin.permission_denied'.tr());
  }
}

/// Logs an admin action to admin_logs.
///
/// Shared utility to avoid duplicating this logic across admin providers.
Future<void> logAdminAction(
  SupabaseClient client,
  String userId,
  String action, {
  String? targetUserId,
  Map<String, dynamic>? details,
}) async {
  try {
    await client.from(SupabaseConstants.adminLogsTable).insert({
      'action': action,
      'admin_user_id': userId,
      if (targetUserId != null) 'target_user_id': targetUserId,
      if (details != null) 'details': details,
    });
  } catch (e, st) {
    AppLogger.error('logAdminAction', e, st);
  }
}
