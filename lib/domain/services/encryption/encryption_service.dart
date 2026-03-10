import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';

/// Provides AES-256-CBC encryption for sensitive fields.
///
/// Uses [FlutterSecureStorage] for key management. The encryption key is
/// generated once and stored securely in the platform keychain/keystore.
///
/// A random 16-byte IV is generated for each encryption call and prepended
/// to the ciphertext. On decryption, the IV is extracted from the first
/// 16 bytes of the decoded data.
///
/// Typical fields to encrypt: ring_number, genetic_info, pedigree_info.
class EncryptionService {
  final FlutterSecureStorage _secureStorage;

  static const String _keyName = 'budgie_encryption_key';
  static const int _keyLength = 32; // 256 bits for AES-256
  static const int _ivLength = 16;
  static const int _macLength = 32; // HMAC-SHA256 output size
  static const String _payloadMagic = 'BBTENC1!';
  static final List<int> _payloadMagicBytes = ascii.encode(_payloadMagic);

  String? _cachedKey;

  EncryptionService([FlutterSecureStorage? secureStorage])
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Encrypts [plainText] using AES-256-CBC with a random IV.
  ///
  /// Returns a Base64-encoded payload:
  /// `MAGIC(8) + IV(16) + ciphertext + HMAC_SHA256(32)`.
  ///
  /// The MAC protects encrypted backups against tampering.
  Future<String> encrypt(String plainText) async {
    if (plainText.isEmpty) return plainText;

    try {
      final keyBytes = await _getOrCreateKeyBytes();
      final key = enc.Key(keyBytes);
      final iv = enc.IV.fromSecureRandom(_ivLength);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final encrypted = encrypter.encrypt(plainText, iv: iv);

      final payload = <int>[
        ..._payloadMagicBytes,
        ...iv.bytes,
        ...encrypted.bytes,
      ];
      final mac = _computeMac(payload, keyBytes);
      final combined = <int>[...payload, ...mac];
      return base64Encode(combined);
    } catch (e, st) {
      AppLogger.error('Encryption failed', e, st);
      rethrow; // Never fallback to plaintext — caller must handle
    }
  }

  /// Decrypts a Base64-encoded [cipherText] back to plain text.
  ///
  /// Extracts the IV from the first 16 bytes, then decrypts the
  /// remaining bytes using AES-256-CBC.
  Future<String> decrypt(String cipherText) async {
    if (cipherText.isEmpty) return cipherText;

    try {
      final keyBytes = await _getOrCreateKeyBytes();
      final key = enc.Key(keyBytes);

      final combined = base64Decode(cipherText);
      final encrypted = _decodeEncryptedPayload(combined, keyBytes);

      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(encrypted.$1, iv: encrypted.$2);
    } catch (e, st) {
      AppLogger.error('Decryption failed', e, st);
      rethrow; // Never fallback to ciphertext — caller must handle
    }
  }

  (enc.Encrypted, enc.IV) _decodeEncryptedPayload(
    List<int> combined,
    Uint8List keyBytes,
  ) {
    // New authenticated format: MAGIC + IV + ciphertext + HMAC
    if (_hasMagicPrefix(combined)) {
      final minimumLength =
          _payloadMagicBytes.length + _ivLength + 1 + _macLength;
      if (combined.length < minimumLength) {
        throw FormatException(
          'Invalid ciphertext: too short authenticated payload '
          '(${combined.length} bytes)',
        );
      }

      final payloadEnd = combined.length - _macLength;
      final payload = combined.sublist(0, payloadEnd);
      final providedMac = combined.sublist(payloadEnd);
      final expectedMac = _computeMac(payload, keyBytes);
      if (!_constantTimeEquals(providedMac, expectedMac)) {
        throw const FormatException(
          'Invalid ciphertext: integrity check failed',
        );
      }

      final ivStart = _payloadMagicBytes.length;
      final ivEnd = ivStart + _ivLength;
      final iv = enc.IV(Uint8List.fromList(combined.sublist(ivStart, ivEnd)));
      final cipherBytes = combined.sublist(ivEnd, payloadEnd);
      if (cipherBytes.isEmpty) {
        throw const FormatException('Invalid ciphertext: empty payload');
      }
      return (enc.Encrypted(Uint8List.fromList(cipherBytes)), iv);
    }

    // Legacy format: IV + ciphertext (no MAC)
    if (combined.length < _ivLength + 1) {
      throw FormatException(
        'Invalid ciphertext: too short (${combined.length} bytes, minimum 17)',
      );
    }
    final iv = enc.IV(Uint8List.fromList(combined.sublist(0, _ivLength)));
    final cipherBytes = combined.sublist(_ivLength);
    return (enc.Encrypted(Uint8List.fromList(cipherBytes)), iv);
  }

  bool _hasMagicPrefix(List<int> bytes) {
    if (bytes.length < _payloadMagicBytes.length) return false;
    for (var i = 0; i < _payloadMagicBytes.length; i++) {
      if (bytes[i] != _payloadMagicBytes[i]) return false;
    }
    return true;
  }

  List<int> _computeMac(List<int> payload, Uint8List keyBytes) {
    final hmac = crypto.Hmac(crypto.sha256, keyBytes);
    return hmac.convert(payload).bytes;
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Returns whether the encryption key exists in secure storage.
  ///
  /// Returns `false` if the storage is unavailable or throws an error.
  Future<bool> hasKey() async {
    try {
      final key = await _secureStorage.read(key: _keyName);
      return key != null;
    } catch (e) {
      AppLogger.warning('Failed to check encryption key: $e');
      return false;
    }
  }

  /// Deletes the encryption key from secure storage.
  ///
  /// **Warning:** This will make all previously encrypted data unreadable.
  Future<void> deleteKey() async {
    await _secureStorage.delete(key: _keyName);
    _cachedKey = null;
  }

  /// Returns the raw 32-byte key as [Uint8List] for AES-256.
  ///
  /// The stored key is a Base64-encoded string of 32 random bytes.
  /// This method decodes it back to the raw bytes, ensuring exactly
  /// 32 bytes for AES-256 compatibility.
  Future<Uint8List> _getOrCreateKeyBytes() async {
    final keyString = await _getOrCreateKey();
    final decoded = base64Decode(keyString);

    // Ensure exactly 32 bytes for AES-256
    if (decoded.length >= _keyLength) {
      return Uint8List.fromList(decoded.sublist(0, _keyLength));
    }

    // Pad with zeros if somehow shorter (should not happen with _generateKey)
    final padded = Uint8List(_keyLength);
    for (int i = 0; i < decoded.length; i++) {
      padded[i] = decoded[i];
    }
    return padded;
  }

  Future<String> _getOrCreateKey() async {
    if (_cachedKey != null) return _cachedKey!;

    var key = await _secureStorage.read(key: _keyName);
    if (key == null) {
      key = _generateKey();
      await _secureStorage.write(key: _keyName, value: key);
      AppLogger.info('Encryption key generated and stored');
    }

    _cachedKey = key;
    return key;
  }

  String _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(_keyLength, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }
}
