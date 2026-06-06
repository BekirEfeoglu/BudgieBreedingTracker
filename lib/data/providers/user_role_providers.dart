library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/supabase_constants.dart';
import '../../core/utils/logger.dart';
import '../remote/supabase/supabase_client.dart';
import 'auth_state_providers.dart';

/// User role providers (admin / founder) for cross-feature use.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final initialized = ref.watch(supabaseInitializedProvider);
  if (!initialized) return false;
  final client = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'anonymous') return false;

  try {
    final result = await client
        .from(SupabaseConstants.profilesTable)
        .select('role, is_active')
        .eq('id', userId)
        .maybeSingle();
    final role = (result?['role'] as String?)?.toLowerCase();
    final isActive = result?['is_active'] as bool?;
    return isActive == true && (role == 'admin' || role == 'founder');
  } catch (e, st) {
    AppLogger.error('isAdminProvider', e, st);
    return false;
  }
});

final isFounderProvider = FutureProvider<bool>((ref) async {
  final initialized = ref.watch(supabaseInitializedProvider);
  if (!initialized) return false;
  final client = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'anonymous') return false;

  try {
    final result = await client
        .from(SupabaseConstants.profilesTable)
        .select('role, is_active')
        .eq('id', userId)
        .maybeSingle();
    final role = (result?['role'] as String?)?.toLowerCase();
    final isActive = result?['is_active'] as bool?;
    return isActive == true && role == 'founder';
  } catch (e, st) {
    AppLogger.error('isFounderProvider', e, st);
    return false;
  }
});
