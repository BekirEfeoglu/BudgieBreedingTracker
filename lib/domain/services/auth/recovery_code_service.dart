import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';

/// Manages MFA recovery (backup) codes — single-use codes that let a user who
/// lost their authenticator disable 2FA and regain access.
///
/// Codes are shown to the user exactly once (on generation); only their
/// SHA-256 hashes are persisted in `mfa_recovery_codes`. Redemption runs
/// server-side via the `redeem_mfa_recovery_code` RPC, which disables the
/// user's TOTP factors so an AAL1 session can complete.
class RecoveryCodeService {
  final SupabaseClient _client;

  RecoveryCodeService(this._client);

  /// Number of codes issued per generation.
  static const int codeCount = 10;

  /// Unambiguous alphabet (no 0/O/1/I/L) for hand-transcribable codes.
  static const String _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// Normalizes a code for hashing/comparison: strips separators, uppercases.
  /// Must mirror the SQL `upper(regexp_replace(p_code,'[^a-zA-Z0-9]','','g'))`
  /// in `redeem_mfa_recovery_code`.
  static String normalize(String code) =>
      code.replaceAll(RegExp('[^a-zA-Z0-9]'), '').toUpperCase();

  static String _hash(String code) =>
      sha256.convert(utf8.encode(normalize(code))).toString();

  /// Generates [codeCount] fresh codes for [userId], replacing any existing
  /// ones, and returns the plaintext codes for one-time display.
  ///
  /// The plaintext is never persisted — only hashes are stored.
  Future<List<String>> generate(String userId) async {
    try {
      final codes = _generatePlaintextCodes();

      // Replace any previous set so the count shown to the user is accurate.
      await _client
          .from(SupabaseConstants.mfaRecoveryCodesTable)
          .delete()
          .eq('user_id', userId);

      await _client.from(SupabaseConstants.mfaRecoveryCodesTable).insert([
        for (final code in codes) {'user_id': userId, 'code_hash': _hash(code)},
      ]);

      return codes;
    } catch (e, st) {
      AppLogger.error('recovery codes generate failed', e, st);
      Sentry.captureException(e, stackTrace: st);
      rethrow;
    }
  }

  /// Returns how many unused recovery codes remain for [userId].
  Future<int> remainingCount(String userId) async {
    try {
      final rows = await _client
          .from(SupabaseConstants.mfaRecoveryCodesTable)
          .select('id')
          .eq('user_id', userId)
          .isFilter('used_at', null);
      return (rows as List).length;
    } catch (e, st) {
      AppLogger.error('recovery codes count failed', e, st);
      return 0;
    }
  }

  /// Redeems [code] server-side: on success the user's MFA is disabled so the
  /// pending AAL1 session can proceed. Returns true when the code matched an
  /// unused code, false otherwise. Never logs the code itself.
  Future<bool> redeem(String code) async {
    try {
      final result = await _client.rpc<dynamic>(
        'redeem_mfa_recovery_code',
        params: {'p_code': code},
      );
      return result == true;
    } catch (e, st) {
      AppLogger.error('recovery code redeem failed', e, st);
      Sentry.captureException(e, stackTrace: st);
      return false;
    }
  }

  List<String> _generatePlaintextCodes() {
    final rng = Random.secure();
    return List.generate(codeCount, (_) {
      final buffer = StringBuffer();
      for (var i = 0; i < 10; i++) {
        if (i == 5) buffer.write('-');
        buffer.write(_alphabet[rng.nextInt(_alphabet.length)]);
      }
      return buffer.toString();
    });
  }
}
