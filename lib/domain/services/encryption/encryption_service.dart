import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

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

  String? _cachedKey;

  EncryptionService([
    FlutterSecureStorage? secureStorage,
  ]) : _secureStorage =
            secureStorage ?? const FlutterSecureStorage();

  /// Encrypts [plainText] using AES-256-CBC with a random IV.
  ///
  /// Returns a Base64-encoded string containing the IV (first 16 bytes)
  /// followed by the ciphertext. Each call produces different output
  /// due to the random IV, even for the same plaintext.
  Future<String> encrypt(String plainText) async {
    if (plainText.isEmpty) return plainText;

    try {
      final keyBytes = await _getOrCreateKeyBytes();
      final key = enc.Key(keyBytes);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Prepend IV to ciphertext so we can extract it during decryption
      final combined = iv.bytes + encrypted.bytes;
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
      if (combined.length < 17) {
        // Too short to contain IV + at least 1 block
        throw FormatException(
          'Invalid ciphertext: too short (${combined.length} bytes, minimum 17)',
        );
      }

      final iv = enc.IV(combined.sublist(0, 16));
      final cipherBytes = combined.sublist(16);
      final encrypted = enc.Encrypted(cipherBytes);

      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e, st) {
      AppLogger.error('Decryption failed', e, st);
      rethrow; // Never fallback to ciphertext — caller must handle
    }
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
    final bytes =
        List<int>.generate(_keyLength, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }
}
