import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';

part 'encryption_payload_codec.dart';
part 'encryption_migration.dart';
part 'encryption_service_helpers.dart';

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
  static const String _keyVersionName = 'budgie_encryption_key_version';
  static const String _previousKeyPrefix = 'budgie_encryption_key_v';
  static const int _keyLength = 32; // 256 bits for AES-256
  static const int _ivLength = 16;
  static const int _macLength = 32; // HMAC-SHA256 output size
  static const String _payloadMagic = 'BBTENC1!';
  static final List<int> _payloadMagicBytes = ascii.encode(_payloadMagic);

  Uint8List? _cachedKeyBytes;

  // Sub-key cache to avoid recomputing HMAC-SHA256 on every encrypt/decrypt call.
  List<int>? _cachedMasterKeyHash;
  ({List<int> encKey, List<int> macKey})? _cachedSubKeys;

  /// Derives separate encryption and MAC keys from master key using HMAC-SHA256 PRF.
  ({List<int> encKey, List<int> macKey}) _deriveSubKeys(List<int> masterKey) {
    final keyHash = crypto.sha256.convert(masterKey).bytes;
    if (_cachedSubKeys != null && _listEquals(_cachedMasterKeyHash!, keyHash)) {
      return _cachedSubKeys!;
    }

    final hmac = crypto.Hmac(crypto.sha256, masterKey);
    final encKey = hmac.convert(utf8.encode('BBTENC')).bytes;
    final macKey = hmac.convert(utf8.encode('BBTMAC')).bytes;

    _cachedMasterKeyHash = keyHash;
    _cachedSubKeys = (encKey: encKey.sublist(0, 32), macKey: macKey.sublist(0, 32));
    return _cachedSubKeys!;
  }

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  EncryptionService([FlutterSecureStorage? secureStorage])
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Encrypts [plainText] using AES-256-CBC with a random IV.
  ///
  /// Returns a Base64-encoded payload:
  /// `MAGIC(8) + IV(16) + ciphertext + HMAC_SHA256(32)`.
  ///
  /// The MAC protects encrypted backups against tampering.
  Future<String> encrypt(String plainText) async {
    if (plainText.isEmpty) {
      throw const FormatException('Cannot encrypt empty string');
    }

    try {
      final keyBytes = await _getOrCreateKeyBytes();
      final subKeys = _deriveSubKeys(keyBytes);
      final key = enc.Key(Uint8List.fromList(subKeys.encKey));
      final iv = enc.IV.fromSecureRandom(_ivLength);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      final encrypted = encrypter.encrypt(plainText, iv: iv);

      final payload = <int>[
        ..._payloadMagicBytes,
        ...iv.bytes,
        ...encrypted.bytes,
      ];
      final mac = _computeMac(payload, Uint8List.fromList(subKeys.macKey));
      final combined = <int>[...payload, ...mac];
      return base64Encode(combined);
    } catch (e, st) {
      AppLogger.error('Encryption failed', e, st);
      rethrow; // Never fallback to plaintext — caller must handle
    }
  }

  /// Decrypts a Base64-encoded [cipherText] back to plain text.
  ///
  /// Tries the active key first. If decryption or HMAC verification fails,
  /// falls back to previous key versions (for post-rotation compatibility).
  Future<String> decrypt(String cipherText) async {
    if (cipherText.isEmpty) {
      throw const FormatException('Cannot decrypt empty string');
    }

    final Object firstError;
    final StackTrace firstStack;
    try {
      final keyBytes = await _getOrCreateKeyBytes();
      return _decryptWithKey(cipherText, keyBytes);
    } catch (e, st) {
      AppLogger.warning('[Encryption] Active key decrypt failed, trying previous keys: $e');
      firstError = e;
      firstStack = st;
    }

    // Active key failed — try previous versions
    final previousKeys = await _loadPreviousKeys();
    for (final prevKey in previousKeys) {
      try {
        return _decryptWithKey(cipherText, prevKey);
      } catch (_) {
        continue;
      }
    }

    // All keys exhausted — throw original error
    AppLogger.error('Decryption failed with all key versions', firstError, firstStack);
    Error.throwWithStackTrace(firstError, firstStack);
  }

  // Payload codec methods are in encryption_payload_codec.dart (part file)
  // Private key helpers are in encryption_service_helpers.dart (part file)
  // Batch re-encryption and audit methods are in encryption_migration.dart (part file)

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
    _zeroCachedKey();
  }

  /// Rotates the encryption key: saves the current key as a previous version
  /// and generates a new active key.
  ///
  /// After rotation, [encrypt] uses the new key while [decrypt] tries the
  /// active key first, then falls back to previous versions.
  /// Call [reEncrypt] on each encrypted value to migrate to the new key.
  Future<int> rotateKey() async {
    final currentVersion = await _getCurrentKeyVersion();
    final currentKeyString = await _secureStorage.read(key: _keyName);

    // Archive current key under its version number
    if (currentKeyString != null) {
      await _secureStorage.write(
        key: '$_previousKeyPrefix$currentVersion',
        value: currentKeyString,
      );
    }

    // Generate and store new key
    _zeroCachedKey();
    final newKey = _generateKey();
    final newVersion = currentVersion + 1;
    await _secureStorage.write(key: _keyName, value: newKey);
    await _secureStorage.write(
      key: _keyVersionName,
      value: newVersion.toString(),
    );
    AppLogger.info('Encryption key rotated to version $newVersion');
    return newVersion;
  }

  /// Re-encrypts a value: decrypts with any matching key, re-encrypts with
  /// the current active key using derived sub-keys and HMAC.
  ///
  /// Handles both key rotation (old key → new key) and format migration
  /// (legacy IV+ciphertext → authenticated BBTENC1! format).
  /// Returns null if the value cannot be decrypted.
  Future<String?> reEncrypt(String cipherText) async {
    try {
      final plainText = await decrypt(cipherText);
      return encrypt(plainText);
    } catch (e) {
      AppLogger.warning('Re-encryption failed: $e');
      return null;
    }
  }

  /// Returns `true` if [encryptedData] uses the legacy format (no BBTENC1!
  /// magic prefix) and should be re-encrypted with the current format.
  ///
  /// This is a cheap check that only inspects the first few bytes of the
  /// Base64-decoded payload — no decryption or key access is performed.
  /// Returns `false` for empty/invalid input instead of throwing.
  bool needsReEncryption(String encryptedData) {
    if (encryptedData.isEmpty) return false;
    try {
      final combined = base64Decode(encryptedData);
      return !_hasMagicPrefix(combined);
    } catch (_) {
      // Not valid Base64 — caller should handle separately
      return false;
    }
  }

  /// Clears the in-memory key cache, overwriting bytes with zeros.
  void dispose() => _zeroCachedKey();
}
