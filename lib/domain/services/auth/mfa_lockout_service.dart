import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/edge_function_provider.dart';

class MfaLockoutResult {
  const MfaLockoutResult({
    required this.success,
    this.locked = false,
    this.remainingSeconds = 0,
  });

  final bool success;
  final bool locked;
  final int remainingSeconds;
}

final mfaLockoutServiceProvider = Provider<MfaLockoutService>((ref) {
  return MfaLockoutService(ref);
});

class MfaLockoutService {
  const MfaLockoutService(this._ref);

  final Ref _ref;

  Future<MfaLockoutResult> check() async {
    final result = await _ref
        .read(edgeFunctionClientProvider)
        .checkMfaLockout();
    return _parse(result.success, result.data);
  }

  Future<MfaLockoutResult> recordFailure() async {
    final result = await _ref
        .read(edgeFunctionClientProvider)
        .recordMfaFailure();
    return _parse(result.success, result.data);
  }

  Future<void> reset() async {
    await _ref.read(edgeFunctionClientProvider).resetMfaLockout();
  }

  MfaLockoutResult _parse(bool success, Map<String, dynamic>? data) {
    final hasLockoutPayload = data?['locked'] is bool;
    if (!success && !hasLockoutPayload) {
      throw StateError('MFA lockout check failed');
    }

    return MfaLockoutResult(
      success: success || hasLockoutPayload,
      locked: data?['locked'] as bool? ?? false,
      remainingSeconds: data?['remaining_seconds'] as int? ?? 0,
    );
  }
}
