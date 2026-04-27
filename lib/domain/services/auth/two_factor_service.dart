import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';

/// Service handling two-factor authentication (MFA) via Supabase.
class TwoFactorService {
  final SupabaseClient _client;

  TwoFactorService(this._client);

  /// Enrolls a new TOTP factor for the current user.
  ///
  /// Returns the TOTP URI, factor ID, secret, and QR code SVG string.
  Future<({String factorId, String totpUri, String secret, String qrCode})>
  enroll({String friendlyName = 'Budgie Tracker'}) async {
    try {
      final response = await _client.auth.mfa.enroll(
        factorType: FactorType.totp,
        issuer: 'BudgieBreedingTracker',
        friendlyName: friendlyName,
      );

      final totp = response.totp;
      if (totp == null) {
        throw Exception('TOTP enrollment returned null');
      }

      return (
        factorId: response.id,
        totpUri: totp.uri,
        secret: totp.secret,
        qrCode: totp.qrCode,
      );
    } catch (e, st) {
      AppLogger.error('2FA enrollment failed', e, st);
      Sentry.captureException(e, stackTrace: st);
      rethrow;
    }
  }

  /// Verifies a TOTP code to complete factor enrollment.
  Future<bool> verifyEnrollment({
    required String factorId,
    required String code,
  }) async {
    try {
      final challenge = await _client.auth.mfa.challenge(factorId: factorId);

      await _client.auth.mfa.verify(
        factorId: factorId,
        challengeId: challenge.id,
        code: code,
      );

      return true;
    } catch (e, st) {
      AppLogger.error('2FA verification failed', e, st);
      Sentry.captureException(e, stackTrace: st);
      return false;
    }
  }

  /// Creates a challenge and verifies a TOTP code during login.
  Future<bool> challengeAndVerify({
    required String factorId,
    required String code,
  }) async {
    try {
      final challenge = await _client.auth.mfa.challenge(factorId: factorId);

      await _client.auth.mfa.verify(
        factorId: factorId,
        challengeId: challenge.id,
        code: code,
      );

      return true;
    } catch (e, st) {
      AppLogger.error('2FA challenge verification failed', e, st);
      Sentry.captureException(e, stackTrace: st);
      return false;
    }
  }

  /// Unenrolls (removes) a TOTP factor.
  Future<bool> unenroll(String factorId) async {
    try {
      await _client.auth.mfa.unenroll(factorId);
      return true;
    } catch (e, st) {
      AppLogger.error('2FA unenroll failed', e, st);
      Sentry.captureException(e, stackTrace: st);
      return false;
    }
  }

  /// Lists all enrolled MFA factors for the current user.
  Future<List<Factor>> getFactors() async {
    try {
      final response = await _client.auth.mfa.listFactors();
      return response.totp;
    } catch (e, st) {
      AppLogger.error('Failed to list MFA factors', e, st);
      return [];
    }
  }

  /// Checks if the user has any active TOTP factor.
  Future<bool> isEnabled() async {
    final factors = await getFactors();
    return factors.any((f) => f.status == FactorStatus.verified);
  }

  /// Gets the current MFA assurance level.
  Future<AuthMFAGetAuthenticatorAssuranceLevelResponse>
  getAssuranceLevel() async {
    return _client.auth.mfa.getAuthenticatorAssuranceLevel();
  }

  /// Whether the current session needs 2FA verification.
  ///
  /// Throws on assurance-level lookup failures so callers can fail closed.
  /// Treating this as "not required" would allow MFA bypass during transient
  /// auth/API failures.
  Future<bool> needsVerification() async {
    try {
      final aal = await getAssuranceLevel();
      return aal.currentLevel == AuthenticatorAssuranceLevels.aal1 &&
          aal.nextLevel == AuthenticatorAssuranceLevels.aal2;
    } catch (e, st) {
      AppLogger.warning(
        '[TwoFactorService] needsVerification check failed: $e',
      );
      Sentry.captureException(e, stackTrace: st);
      rethrow;
    }
  }
}
