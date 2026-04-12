import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/utils/logger.dart';
import '../../../domain/services/auth/two_factor_service.dart';
import 'auth_providers.dart';

/// Result of post-login MFA check.
sealed class PostLoginMfaResult {
  const PostLoginMfaResult();
}

/// User has no MFA requirement — navigate to home.
class MfaNotRequired extends PostLoginMfaResult {
  const MfaNotRequired();
}

/// User needs MFA verification — navigate to 2FA screen.
class MfaVerificationNeeded extends PostLoginMfaResult {
  final String factorId;
  const MfaVerificationNeeded(this.factorId);
}

/// MFA check failed — user was signed out for security.
class MfaCheckFailed extends PostLoginMfaResult {
  final bool didSignOut;
  const MfaCheckFailed({required this.didSignOut});
}

/// Encapsulates the post-login 2FA check logic for testability.
///
/// After successful password authentication, checks whether the user
/// has TOTP enrolled and needs AAL2 verification. On failure, signs
/// the user out as a security measure.
class PostLoginMfaChecker {
  final TwoFactorService _twoFactorService;
  final AuthActions _authActions;

  const PostLoginMfaChecker({
    required TwoFactorService twoFactorService,
    required AuthActions authActions,
  })  : _twoFactorService = twoFactorService,
        _authActions = authActions;

  Future<PostLoginMfaResult> check() async {
    try {
      final needs2FA = await _twoFactorService.needsVerification();
      if (needs2FA) {
        final factors = await _twoFactorService.getFactors();
        if (factors.isNotEmpty) {
          return MfaVerificationNeeded(factors.first.id);
        }
        // 2FA required but no factors found — inconsistent state.
        // Sign out as precaution to prevent MFA bypass.
        AppLogger.warning(
          '[Login] 2FA required but no factors found — signing out',
        );
        Sentry.addBreadcrumb(Breadcrumb(
          message: '2FA required but no factors found — signing out',
          category: 'auth.mfa',
          level: SentryLevel.warning,
        ));
        var didSignOut = false;
        try {
          await _authActions.signOut();
          didSignOut = true;
        } catch (signOutError) {
          AppLogger.debug(
            '[Login] Sign-out after empty factors also failed: $signOutError',
          );
        }
        return MfaCheckFailed(didSignOut: didSignOut);
      }
      return const MfaNotRequired();
    } catch (e, st) {
      AppLogger.error(
        '[Login] 2FA check failed, signing out for security',
        e,
        st,
      );
      // Fire-and-forget — never await Sentry to avoid blocking the UI.
      Sentry.captureException(e, stackTrace: st);

      var didSignOut = false;
      try {
        await _authActions.signOut();
        didSignOut = true;
      } catch (signOutError) {
        AppLogger.debug(
          '[Login] Sign-out after 2FA failure also failed: $signOutError',
        );
      }
      return MfaCheckFailed(didSignOut: didSignOut);
    }
  }
}
