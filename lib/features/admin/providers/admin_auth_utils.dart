import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../shared/providers/auth.dart';
import '../constants/admin_constants.dart';

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
  // Use profiles.role as the source of truth for admin status,
  // consistent with the is_admin() Postgres function and RLS policies.
  final result = await client
      .from(SupabaseConstants.profilesTable)
      .select('${SupabaseConstants.colRole}, ${SupabaseConstants.colIsActive}')
      .eq(SupabaseConstants.colId, userId)
      .maybeSingle();
  final role = (result?[SupabaseConstants.colRole] as String?)?.toLowerCase();
  final isActive = result?[SupabaseConstants.colIsActive] as bool?;
  if (isActive != true || (role != 'admin' && role != 'founder')) {
    throw Exception('admin.permission_denied'.tr());
  }
}

/// Verifies the current user is a founder. Throws if not.
///
/// Used for destructive operations (e.g., clearing audit logs)
/// that should be restricted to the founder role only.
Future<void> requireFounder(Ref ref) async {
  await requireAdmin(ref); // first check admin access
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserIdProvider);
  final result = await client
      .from(SupabaseConstants.adminUsersTable)
      .select(SupabaseConstants.colId)
      .eq(SupabaseConstants.colUserId, userId)
      .eq(SupabaseConstants.colRole, AdminConstants.roleFounder)
      .maybeSingle();
  if (result == null) {
    throw Exception('admin.founder_required'.tr());
  }
}
