import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Returns `true` when Supabase singleton has been initialized.
///
/// This check reads the real runtime singleton and is resilient to provider
/// overrides used in tests.
bool isSupabaseClientAvailable() {
  try {
    Supabase.instance.client;
    return true;
  } catch (_) {
    return false;
  }
}

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
