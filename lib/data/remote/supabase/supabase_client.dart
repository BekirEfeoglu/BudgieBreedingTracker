import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/bootstrap.dart';

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

const _fallbackSupabaseUrl = 'https://example.invalid';
const _fallbackSupabaseAnonKey = 'offline-anon-key';
const _fallbackRecheckDelay = Duration(seconds: 5);
const _maxFallbackRechecks = 12;

final SupabaseClient _fallbackSupabaseClient = SupabaseClient(
  _fallbackSupabaseUrl,
  _fallbackSupabaseAnonKey,
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

int _fallbackRecheckAttempts = 0;
bool _fallbackRecheckScheduled = false;

Timer? _scheduleFallbackRecheck(Ref ref) {
  if (!hasSupabaseCredentials) return null;
  if (_fallbackRecheckScheduled) return null;
  if (_fallbackRecheckAttempts >= _maxFallbackRechecks) return null;

  _fallbackRecheckScheduled = true;
  _fallbackRecheckAttempts++;

  return Timer(_fallbackRecheckDelay, () {
    _fallbackRecheckScheduled = false;
    if (!ref.mounted) return;
    ref.invalidate(supabaseClientProvider);
  });
}

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  if (isSupabaseClientAvailable()) {
    _fallbackRecheckAttempts = 0;
    return Supabase.instance.client;
  }

  final timer = _scheduleFallbackRecheck(ref);
  ref.onDispose(() => timer?.cancel());
  return _fallbackSupabaseClient;
});
