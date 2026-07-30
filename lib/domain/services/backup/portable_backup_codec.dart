import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as enc;

/// Password-derived, device-independent encryption for portable backups.
///
/// The JSON envelope is authenticated before decryption. PBKDF2-HMAC-SHA256
/// derives a master key; domain-separated HMAC labels derive independent
/// AES-256-CBC and HMAC-SHA256 keys from it.
class PortableBackupCodec {
  static const format = 'BBT_PORTABLE_BACKUP';
  static const formatVersion = 1;
  static const kdf = 'PBKDF2-HMAC-SHA256';
  static const iterations = 100000;
  static const minimumPasswordLength = 10;
  static const _saltLength = 16;
  static const _ivLength = 16;
  static const _keyLength = 32;

  const PortableBackupCodec();

  /// Encrypts [plainText] on a worker isolate to avoid blocking rendering.
  Future<String> encrypt(String plainText, String password) async {
    _validatePassword(password);
    if (plainText.isEmpty) {
      throw const FormatException('Cannot encrypt an empty backup');
    }

    final random = Random.secure();
    final salt = Uint8List.fromList(
      List<int>.generate(_saltLength, (_) => random.nextInt(256)),
    );
    final iv = Uint8List.fromList(
      List<int>.generate(_ivLength, (_) => random.nextInt(256)),
    );
    return Isolate.run(() => _encryptPortable(plainText, password, salt, iv));
  }

  /// Authenticates and decrypts [envelope] on a worker isolate.
  Future<String> decrypt(String envelope, String password) async {
    _validatePassword(password);
    return Isolate.run(() => _decryptPortable(envelope, password));
  }

  /// Returns true only for the versioned portable-backup JSON envelope.
  static bool looksPortable(String content) {
    try {
      final decoded = jsonDecode(content);
      return decoded is Map<String, dynamic> && decoded['format'] == format;
    } catch (_) {
      return false;
    }
  }

  static void _validatePassword(String password) {
    if (password.length < minimumPasswordLength) {
      throw const FormatException('Backup password is too short');
    }
  }
}

String _encryptPortable(
  String plainText,
  String password,
  Uint8List salt,
  Uint8List iv,
) {
  final keys = _derivePortableKeys(password, salt);
  final encrypter = enc.Encrypter(
    enc.AES(
      enc.Key(Uint8List.fromList(keys.encryption)),
      mode: enc.AESMode.cbc,
    ),
  );
  final cipherText = encrypter.encrypt(plainText, iv: enc.IV(iv)).bytes;
  final saltText = base64Encode(salt);
  final ivText = base64Encode(iv);
  final cipherTextValue = base64Encode(cipherText);
  final authenticated = _authenticatedEnvelopeBytes(
    salt: saltText,
    iv: ivText,
    cipherText: cipherTextValue,
  );
  final mac = crypto.Hmac(
    crypto.sha256,
    keys.authentication,
  ).convert(authenticated).bytes;

  return const JsonEncoder.withIndent('  ').convert({
    'format': PortableBackupCodec.format,
    'format_version': PortableBackupCodec.formatVersion,
    'kdf': PortableBackupCodec.kdf,
    'iterations': PortableBackupCodec.iterations,
    'salt': saltText,
    'iv': ivText,
    'ciphertext': cipherTextValue,
    'mac': base64Encode(mac),
  });
}

String _decryptPortable(String envelope, String password) {
  try {
    final decoded = jsonDecode(envelope);
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != PortableBackupCodec.format ||
        decoded['format_version'] != PortableBackupCodec.formatVersion ||
        decoded['kdf'] != PortableBackupCodec.kdf ||
        decoded['iterations'] != PortableBackupCodec.iterations) {
      throw const FormatException('Unsupported portable backup envelope');
    }

    final saltText = decoded['salt'];
    final ivText = decoded['iv'];
    final cipherTextValue = decoded['ciphertext'];
    final macText = decoded['mac'];
    if (saltText is! String ||
        ivText is! String ||
        cipherTextValue is! String ||
        macText is! String) {
      throw const FormatException('Malformed portable backup envelope');
    }

    final salt = base64Decode(saltText);
    final iv = base64Decode(ivText);
    final cipherText = base64Decode(cipherTextValue);
    final expectedMac = base64Decode(macText);
    if (salt.length != 16 ||
        iv.length != 16 ||
        expectedMac.length != 32 ||
        cipherText.isEmpty) {
      throw const FormatException('Malformed portable backup payload');
    }

    final keys = _derivePortableKeys(password, salt);
    final actualMac = crypto.Hmac(crypto.sha256, keys.authentication)
        .convert(
          _authenticatedEnvelopeBytes(
            salt: saltText,
            iv: ivText,
            cipherText: cipherTextValue,
          ),
        )
        .bytes;
    if (!_constantTimeEquals(expectedMac, actualMac)) {
      throw const FormatException('Portable backup authentication failed');
    }

    final encrypter = enc.Encrypter(
      enc.AES(
        enc.Key(Uint8List.fromList(keys.encryption)),
        mode: enc.AESMode.cbc,
      ),
    );
    return encrypter.decrypt(
      enc.Encrypted(Uint8List.fromList(cipherText)),
      iv: enc.IV(Uint8List.fromList(iv)),
    );
  } on FormatException {
    rethrow;
  } catch (_) {
    throw const FormatException('Malformed portable backup');
  }
}

({List<int> encryption, List<int> authentication}) _derivePortableKeys(
  String password,
  List<int> salt,
) {
  final master = _pbkdf2Sha256(
    utf8.encode(password),
    salt,
    PortableBackupCodec.iterations,
    PortableBackupCodec._keyLength,
  );
  final separator = crypto.Hmac(crypto.sha256, master);
  return (
    encryption: separator.convert(utf8.encode('BBT-BACKUP-ENC')).bytes,
    authentication: separator.convert(utf8.encode('BBT-BACKUP-MAC')).bytes,
  );
}

List<int> _pbkdf2Sha256(
  List<int> password,
  List<int> salt,
  int iterationCount,
  int derivedKeyLength,
) {
  final hmac = crypto.Hmac(crypto.sha256, password);
  final output = <int>[];
  var blockIndex = 1;

  while (output.length < derivedKeyLength) {
    final block = ByteData(4)..setUint32(0, blockIndex, Endian.big);
    var u = hmac.convert([...salt, ...block.buffer.asUint8List()]).bytes;
    final value = List<int>.from(u);
    for (var iteration = 1; iteration < iterationCount; iteration++) {
      u = hmac.convert(u).bytes;
      for (var i = 0; i < value.length; i++) {
        value[i] ^= u[i];
      }
    }
    output.addAll(value);
    blockIndex++;
  }

  return output.sublist(0, derivedKeyLength);
}

List<int> _authenticatedEnvelopeBytes({
  required String salt,
  required String iv,
  required String cipherText,
}) {
  return utf8.encode(
    '${PortableBackupCodec.format}|'
    '${PortableBackupCodec.formatVersion}|'
    '${PortableBackupCodec.kdf}|'
    '${PortableBackupCodec.iterations}|'
    '$salt|$iv|$cipherText',
  );
}

bool _constantTimeEquals(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  var difference = 0;
  for (var i = 0; i < left.length; i++) {
    difference |= left[i] ^ right[i];
  }
  return difference == 0;
}
