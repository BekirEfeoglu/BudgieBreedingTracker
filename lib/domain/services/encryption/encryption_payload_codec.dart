part of 'encryption_service.dart';

// ---------------------------------------------------------------------------
// Payload encoding/decoding, HMAC, and constant-time comparison helpers.
// These are top-level private functions accessible within the library
// via the `part` directive.
// ---------------------------------------------------------------------------

/// Decodes an encrypted payload, verifying HMAC if present.
///
/// Supports two formats:
/// - **Authenticated**: `MAGIC(8) + IV(16) + ciphertext + HMAC_SHA256(32)`
/// - **Legacy**: `IV(16) + ciphertext` (no MAC — pre-rotation data)
(enc.Encrypted, enc.IV) _decodeEncryptedPayload(
  List<int> combined,
  Uint8List keyBytes,
) {
  // New authenticated format: MAGIC + IV + ciphertext + HMAC
  if (_hasMagicPrefix(combined)) {
    final minimumLength =
        EncryptionService._payloadMagicBytes.length +
            EncryptionService._ivLength +
            1 +
            EncryptionService._macLength;
    if (combined.length < minimumLength) {
      throw FormatException(
        'Invalid ciphertext: too short authenticated payload '
        '(${combined.length} bytes)',
      );
    }

    final payloadEnd = combined.length - EncryptionService._macLength;
    final payload = combined.sublist(0, payloadEnd);
    final providedMac = combined.sublist(payloadEnd);
    final expectedMac = _computeMac(payload, keyBytes);
    if (!_constantTimeEquals(providedMac, expectedMac)) {
      throw const FormatException(
        'Invalid ciphertext: integrity check failed',
      );
    }

    final ivStart = EncryptionService._payloadMagicBytes.length;
    final ivEnd = ivStart + EncryptionService._ivLength;
    final iv = enc.IV(Uint8List.fromList(combined.sublist(ivStart, ivEnd)));
    final cipherBytes = combined.sublist(ivEnd, payloadEnd);
    if (cipherBytes.isEmpty) {
      throw const FormatException('Invalid ciphertext: empty payload');
    }
    return (enc.Encrypted(Uint8List.fromList(cipherBytes)), iv);
  }

  // Legacy format: IV + ciphertext (no MAC)
  if (combined.length < EncryptionService._ivLength + 1) {
    throw FormatException(
      'Invalid ciphertext: too short (${combined.length} bytes, minimum 17)',
    );
  }
  AppLogger.warning(
    '[Encryption] Legacy payload without HMAC detected — recommend re-encryption',
  );
  final iv = enc.IV(
    Uint8List.fromList(combined.sublist(0, EncryptionService._ivLength)),
  );
  final cipherBytes = combined.sublist(EncryptionService._ivLength);
  return (enc.Encrypted(Uint8List.fromList(cipherBytes)), iv);
}

/// Checks whether [bytes] starts with the magic prefix `BBTENC1!`.
bool _hasMagicPrefix(List<int> bytes) {
  if (bytes.length < EncryptionService._payloadMagicBytes.length) return false;
  for (var i = 0; i < EncryptionService._payloadMagicBytes.length; i++) {
    if (bytes[i] != EncryptionService._payloadMagicBytes[i]) return false;
  }
  return true;
}

/// Computes HMAC-SHA256 over [payload] using [keyBytes].
List<int> _computeMac(List<int> payload, Uint8List keyBytes) {
  final hmac = crypto.Hmac(crypto.sha256, keyBytes);
  return hmac.convert(payload).bytes;
}

/// Constant-time comparison to prevent timing attacks on HMAC verification.
bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
