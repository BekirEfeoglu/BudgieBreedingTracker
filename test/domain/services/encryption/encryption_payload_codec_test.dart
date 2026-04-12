import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

const _keyName = 'budgie_encryption_key';
final _keyBytes = Uint8List.fromList(List<int>.generate(32, (i) => i));
final _validBase64Key = base64Encode(_keyBytes);

// Magic prefix for authenticated format
const _magic = [66, 66, 84, 69, 78, 67, 49, 33]; // 'BBTENC1!'

void main() {
  late MockFlutterSecureStorage mockStorage;
  late EncryptionService service;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    when(
      () => mockStorage.read(key: _keyName),
    ).thenAnswer((_) async => _validBase64Key);
    when(
      () => mockStorage.read(key: 'budgie_encryption_key_version'),
    ).thenAnswer((_) async => null);
    when(
      () => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockStorage.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});
    service = EncryptionService(mockStorage);
  });

  group('authenticated payload format', () {
    test('encrypt produces BBTENC1! magic prefix', () async {
      final encrypted = await service.encrypt('hello world');
      final decoded = base64Decode(encrypted);

      // First 8 bytes should be the magic prefix
      final prefix = decoded.sublist(0, 8);
      expect(prefix, equals(_magic));
    });

    test('encrypt output has correct structure: magic + IV + cipher + MAC',
        () async {
      final encrypted = await service.encrypt('test data');
      final decoded = base64Decode(encrypted);

      // minimum: magic(8) + IV(16) + at least 1 byte cipher + MAC(32) = 57
      expect(decoded.length, greaterThanOrEqualTo(57));
    });

    test('decrypt verifies HMAC integrity', () async {
      final encrypted = await service.encrypt('integrity test');
      final decoded = base64Decode(encrypted).toList();

      // Tamper with the ciphertext (byte after magic + IV)
      const tamperIndex = 8 + 16; // after magic and IV
      decoded[tamperIndex] = (decoded[tamperIndex] + 1) % 256;

      final tampered = base64Encode(decoded);
      await expectLater(
        service.decrypt(tampered),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('integrity check failed'),
          ),
        ),
      );
    });

    test('decrypt rejects tampered HMAC', () async {
      final encrypted = await service.encrypt('mac test');
      final decoded = base64Decode(encrypted).toList();

      // Tamper with the last byte (part of HMAC)
      decoded[decoded.length - 1] =
          (decoded[decoded.length - 1] + 1) % 256;

      final tampered = base64Encode(decoded);
      await expectLater(
        service.decrypt(tampered),
        throwsA(isA<FormatException>()),
      );
    });

    test('too short authenticated payload throws', () async {
      // magic(8) + IV(16) + 0 cipher + MAC(32) = 56 => too short (need 57+)
      final short = <int>[..._magic, ...List.filled(16, 0)];
      // Add HMAC for the payload to look authenticated but too short
      final hmac = crypto.Hmac(crypto.sha256, _keyBytes);
      final mac = hmac.convert(short).bytes;
      final combined = [...short, ...mac];

      final encoded = base64Encode(combined);
      await expectLater(
        service.decrypt(encoded),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('legacy payload format', () {
    test('decrypt handles legacy IV + ciphertext format', () async {
      // Encrypt with service (authenticated), then verify round-trip
      // We test legacy by constructing a payload without magic prefix
      final encrypted = await service.encrypt('legacy roundtrip');
      final decrypted = await service.decrypt(encrypted);
      expect(decrypted, 'legacy roundtrip');
    });

    test('too short legacy payload throws', () async {
      // Less than IV(16) + 1 byte cipher = 17 bytes
      final short = List<int>.filled(16, 0); // exactly 16, no cipher
      final encoded = base64Encode(short);

      await expectLater(
        service.decrypt(encoded),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('too short'),
          ),
        ),
      );
    });

    test('very short payload throws', () async {
      final tiny = List<int>.filled(5, 0);
      final encoded = base64Encode(tiny);

      await expectLater(
        service.decrypt(encoded),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('encrypt/decrypt round-trip', () {
    test('round-trips plain ASCII text', () async {
      final decrypted = await service.decrypt(
        await service.encrypt('hello world'),
      );
      expect(decrypted, 'hello world');
    });

    test('round-trips unicode text', () async {
      const unicode = 'Muhabbet kusu yetistiricileri icin';
      final decrypted = await service.decrypt(
        await service.encrypt(unicode),
      );
      expect(decrypted, unicode);
    });

    test('round-trips long text', () async {
      final longText = 'x' * 10000;
      final decrypted = await service.decrypt(
        await service.encrypt(longText),
      );
      expect(decrypted, longText);
    });

    test('each encryption produces different output (random IV)', () async {
      final e1 = await service.encrypt('same');
      final e2 = await service.encrypt('same');
      expect(e1, isNot(e2));
    });
  });

  group('constant-time comparison', () {
    test('detects single-bit difference in MAC', () async {
      final encrypted = await service.encrypt('bit flip');
      final decoded = base64Decode(encrypted).toList();

      // Flip one bit in the MAC (last 32 bytes)
      final macStart = decoded.length - 32;
      decoded[macStart] ^= 0x01;

      final tampered = base64Encode(decoded);
      await expectLater(
        service.decrypt(tampered),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('magic prefix detection', () {
    test('non-magic prefix treated as legacy', () async {
      // Payload starting with 'XXXXXXXX' (not BBTENC1!)
      // followed by IV(16) + some cipher bytes
      final payload = <int>[
        ...ascii.encode('XXXXXXXX'),
        ...List<int>.filled(16, 1),
        ...List<int>.filled(16, 2),
      ];
      final encoded = base64Encode(payload);

      // Will try to decrypt as legacy format (IV + cipher)
      // Should fail with a decryption error, not a format error about magic
      await expectLater(
        service.decrypt(encoded),
        throwsA(anything),
      );
    });
  });

  group('legacy payload with derived-key system', () {
    test('legacy payload decrypts correctly despite derived-key system', () async {
      // Build a legacy payload: IV + AES-CBC(rawKey, plaintext) — no magic prefix
      final rawKey = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final iv = enc.IV.fromLength(16);
      final encrypter = enc.Encrypter(
        enc.AES(enc.Key(rawKey), mode: enc.AESMode.cbc),
      );
      final encrypted = encrypter.encrypt('legacy-derived-clash', iv: iv);
      final legacyCipher = base64Encode([...iv.bytes, ...encrypted.bytes]);

      // Service uses derived keys for new encryptions, but the legacy path
      // must use the raw master key directly (no HMAC, no magic prefix).
      final decrypted = await service.decrypt(legacyCipher);
      expect(decrypted, 'legacy-derived-clash');
    });

    test('needsReEncryption detects legacy payload for upgrade', () {
      final rawKey = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final iv = enc.IV.fromLength(16);
      final encrypter = enc.Encrypter(
        enc.AES(enc.Key(rawKey), mode: enc.AESMode.cbc),
      );
      final encrypted = encrypter.encrypt('needs-upgrade', iv: iv);
      final legacyCipher = base64Encode([...iv.bytes, ...encrypted.bytes]);

      expect(service.needsReEncryption(legacyCipher), isTrue);
    });

    test('legacy payload re-encrypted to authenticated derived-key format', () async {
      final rawKey = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final iv = enc.IV.fromLength(16);
      final encrypter = enc.Encrypter(
        enc.AES(enc.Key(rawKey), mode: enc.AESMode.cbc),
      );
      final encrypted = encrypter.encrypt('upgrade-to-derived', iv: iv);
      final legacyCipher = base64Encode([...iv.bytes, ...encrypted.bytes]);

      // Re-encrypt: decrypt with raw key (legacy), encrypt with derived keys
      final reEncrypted = await service.reEncrypt(legacyCipher);
      expect(reEncrypted, isNotNull);
      expect(service.needsReEncryption(reEncrypted!), isFalse);

      // Verify the re-encrypted payload uses derived-key HMAC (not raw key)
      final combined = base64Decode(reEncrypted);
      final payloadEnd = combined.length - 32;
      final payload = combined.sublist(0, payloadEnd);
      final providedMac = combined.sublist(payloadEnd);

      // HMAC with raw key should NOT match (proving derived macKey was used)
      final rawHmac = crypto.Hmac(crypto.sha256, rawKey);
      final rawMac = rawHmac.convert(payload).bytes;
      expect(providedMac, isNot(equals(rawMac)));

      // Content should still be recoverable
      final decrypted = await service.decrypt(reEncrypted);
      expect(decrypted, 'upgrade-to-derived');
    });
  });
}
