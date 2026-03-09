import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../auth/providers/auth_providers.dart';

/// Verifies the current user is an admin. Throws if not.
///
/// Shared utility used by admin providers and action notifiers
/// to enforce admin permission checks at the data layer.
Future<void> requireAdmin(Ref ref) async {
  final client = ref.read(supabaseClientProvider);
  final userId = ref.read(currentUserIdProvider);
  if (userId == 'anonymous') {
    throw Exception('Authentication required');
  }
  final result = await client
      .from(SupabaseConstants.adminUsersTable)
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();
  if (result == null) {
    throw Exception('Admin permission denied');
  }
}
