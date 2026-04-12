part of 'encryption_service.dart';

// ---------------------------------------------------------------------------
// Private key management and internal helpers for [EncryptionService].
// Moved to part file to keep parent under 300 lines.
// ---------------------------------------------------------------------------

extension _EncryptionKeyHelpers on EncryptionService {
  void _zeroCachedKey() {
    _cachedKeyBytes?.fillRange(0, _cachedKeyBytes!.length, 0);
    _cachedKeyBytes = null;
    _cachedMasterKeyHash = null;
    _cachedSubKeys = null;
  }

  /// Returns the current key version number (0 for the original key).
  Future<int> _getCurrentKeyVersion() async {
    final versionStr = await _secureStorage.read(key: EncryptionService._keyVersionName);
    return int.tryParse(versionStr ?? '') ?? 0;
  }

  String _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(EncryptionService._keyLength, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Returns the raw 32-byte key as [Uint8List] for AES-256.
  ///
  /// The stored key is a Base64-encoded string of 32 random bytes.
  /// This method decodes it back to the raw bytes, ensuring exactly
  /// 32 bytes for AES-256 compatibility.
  ///
  /// The result is cached as [Uint8List] (not String) so that it can
  /// be zeroed on [dispose] / [deleteKey].
  Future<Uint8List> _getOrCreateKeyBytes() async {
    if (_cachedKeyBytes != null) return _cachedKeyBytes!;

    var keyString = await _secureStorage.read(key: EncryptionService._keyName);
    if (keyString == null) {
      keyString = _generateKey();
      await _secureStorage.write(key: EncryptionService._keyName, value: keyString);
      AppLogger.info('Encryption key generated and stored');
    }

    final decoded = base64Decode(keyString);

    // Ensure exactly 32 bytes for AES-256
    if (decoded.length < EncryptionService._keyLength) {
      AppLogger.error(
        'Active encryption key is corrupted '
        '(${decoded.length} bytes, expected ${EncryptionService._keyLength}) — regenerating',
        null,
        StackTrace.current,
      );
      // Archive corrupted key under current version before deleting,
      // so it can still be tried during decryption of old data.
      final currentVersion = await _getCurrentKeyVersion();
      await _secureStorage.write(
        key: '${EncryptionService._previousKeyPrefix}$currentVersion',
        value: keyString,
      );
      await _secureStorage.delete(key: EncryptionService._keyName);
      final freshKey = _generateKey();
      final newVersion = currentVersion + 1;
      await _secureStorage.write(key: EncryptionService._keyName, value: freshKey);
      await _secureStorage.write(
        key: EncryptionService._keyVersionName,
        value: newVersion.toString(),
      );
      final freshDecoded = base64Decode(freshKey);
      _cachedKeyBytes = Uint8List.fromList(
        freshDecoded.sublist(0, EncryptionService._keyLength),
      );
    } else {
      _cachedKeyBytes = Uint8List.fromList(decoded.sublist(0, EncryptionService._keyLength));
    }
    return _cachedKeyBytes!;
  }

  /// Loads all archived previous key versions from secure storage.
  Future<List<Uint8List>> _loadPreviousKeys() async {
    final keys = <Uint8List>[];
    try {
      final currentVersion = await _getCurrentKeyVersion();
      // Iterate from newest to oldest for faster match
      for (var v = currentVersion - 1; v >= 0; v--) {
        final keyString = await _secureStorage.read(
          key: '${EncryptionService._previousKeyPrefix}$v',
        );
        if (keyString != null) {
          final decoded = base64Decode(keyString);
          if (decoded.length < EncryptionService._keyLength) {
            AppLogger.warning(
              'Skipping corrupted archived key v$v '
              '(${decoded.length} bytes, expected ${EncryptionService._keyLength})',
            );
            continue;
          }
          keys.add(Uint8List.fromList(decoded.sublist(0, EncryptionService._keyLength)));
        }
      }
    } catch (_) {
      // No previous keys available (e.g. first install, storage error)
    }
    return keys;
  }

  String _decryptWithKey(String cipherText, Uint8List keyBytes) {
    final combined = base64Decode(cipherText);
    final isAuthenticated = _hasMagicPrefix(combined);

    if (isAuthenticated) {
      // Try derived sub-keys first (new format: BBTENC1! + AES(derivedEncKey) + HMAC(derivedMacKey)).
      try {
        final subKeys = _deriveSubKeys(keyBytes);
        final encKeyBytes = Uint8List.fromList(subKeys.encKey);
        final macKeyBytes = Uint8List.fromList(subKeys.macKey);
        final decrypted = _decodeEncryptedPayload(combined, macKeyBytes);
        final encrypter = enc.Encrypter(
          enc.AES(enc.Key(encKeyBytes), mode: enc.AESMode.cbc),
        );
        return encrypter.decrypt(decrypted.$1, iv: decrypted.$2);
      } on FormatException {
        // HMAC mismatch with derived keys — fall through to raw key attempt
        // for pre-separation payloads.
      }

      // Pre-separation fallback: BBTENC1! + AES(rawKey) + HMAC(rawKey).
      // Handles payloads encrypted before _deriveSubKeys was introduced.
      // HMAC is still verified inside _decodeEncryptedPayload using rawKey.
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'Pre-separation authenticated payload detected — HMAC uses raw key',
        category: 'encryption',
        level: SentryLevel.warning,
        data: {'payloadLength': combined.length},
      ));
      final rawDecrypted = _decodeEncryptedPayload(combined, keyBytes);
      final rawEncrypter = enc.Encrypter(
        enc.AES(enc.Key(keyBytes), mode: enc.AESMode.cbc),
      );
      return rawEncrypter.decrypt(rawDecrypted.$1, iv: rawDecrypted.$2);
    }

    // Legacy only: IV+ciphertext, no magic prefix, no HMAC verification.
    Sentry.addBreadcrumb(Breadcrumb(
      message: 'Legacy encryption payload without HMAC detected',
      category: 'encryption',
      level: SentryLevel.warning,
      data: {'payloadLength': combined.length},
    ));
    final legacyDecrypted = _decodeEncryptedPayload(combined, keyBytes);
    final legacyEncrypter = enc.Encrypter(
      enc.AES(enc.Key(keyBytes), mode: enc.AESMode.cbc),
    );
    return legacyEncrypter.decrypt(legacyDecrypted.$1, iv: legacyDecrypted.$2);
  }
}
