import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/domain/services/auth/two_factor_service.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

/// Provider for [TwoFactorService].
final twoFactorServiceProvider = Provider<TwoFactorService>((ref) {
  return TwoFactorService(ref.watch(supabaseClientProvider));
});

/// Holds the factor ID when 2FA verification is pending after login.
///
/// Set after successful password login when user has TOTP enrolled (AAL1 → AAL2).
/// Cleared after successful 2FA verification.
/// Read synchronously in router redirect to enforce 2FA gate.
class PendingMfaFactorIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
}

final pendingMfaFactorIdProvider =
    NotifierProvider<PendingMfaFactorIdNotifier, String?>(
  PendingMfaFactorIdNotifier.new,
);
