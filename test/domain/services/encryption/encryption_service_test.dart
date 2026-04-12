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
final _validBase64Key = base64Encode(List<int>.generate(32, (i) => i));

void main() {
  late MockFlutterSecureStorage mockStorage;
  late EncryptionService service;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
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

  group('EncryptionService', () {
    test('encrypt/decrypt round-trips and reuses cached key', () async {
      when(
        () => mockStorage.read(key: _keyName),
      ).thenAnswer((_) async => _validBase64Key);

      final encrypted1 = await service.encrypt('sensitive-data');
      final encrypted2 = await service.encrypt('sensitive-data');
      final decrypted = await service.decrypt(encrypted1);

      expect(encrypted1, isNot('sensitive-data'));
      expect(encrypted2, isNot('sensitive-data'));
      expect(encrypted1, isNot(encrypted2));
      expect(base64Decode(encrypted1).length, greaterThan(16));
      expect(decrypted, 'sensitive-data');
      verify(() => mockStorage.read(key: _keyName)).called(1);
    });

    test('encrypt generates and stores key when no key exists', () async {
      when(() => mockStorage.read(key: _keyName)).thenAnswer((_) async => null);

      String? storedKey;
      when(
        () => mockStorage.write(
          key: _keyName,
          value: any(named: 'value'),
        ),
      ).thenAnswer((invocation) async {
        storedKey = invocation.namedArguments[#value] as String?;
      });

      final encrypted = await service.encrypt('new-secret');

      expect(encrypted, isNot('new-secret'));
      expect(storedKey, isNotNull);
      expect(base64Decode(storedKey!).length, 32);
      verify(
        () => mockStorage.write(
          key: _keyName,
          value: any(named: 'value'),
        ),
      ).called(1);
    });

    test('hasKey reflects secure storage state', () async {
      when(() => mockStorage.read(key: _keyName)).thenAnswer((_) async => null);
      expect(await service.hasKey(), isFalse);

      when(
        () => mockStorage.read(key: _keyName),
      ).thenAnswer((_) async => _validBase64Key);
      expect(await service.hasKey(), isTrue);
    });

    test('deleteKey clears cache and re-reads key on next operation', () async {
      when(
        () => mockStorage.read(key: _keyName),
      ).thenAnswer((_) async => _validBase64Key);

      await service.encrypt('before-delete');
      await service.deleteKey();
      await service.encrypt('after-delete');

      verify(() => mockStorage.delete(key: _keyName)).called(1);
      verify(() => mockStorage.read(key: _keyName)).called(2);
    });

    test(
      'decrypt throws FormatException for invalid ciphertext values',
      () async {
        when(
          () => mockStorage.read(key: _keyName),
        ).thenAnswer((_) async => _validBase64Key);

        const invalidBase64 = 'not-base64';
        final shortCipherText = base64Encode([1, 2, 3]);

        await expectLater(
          service.decrypt(invalidBase64),
          throwsA(isA<FormatException>()),
        );
        await expectLater(
          service.decrypt(shortCipherText),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('encrypt/decrypt throw when storage fails (never fallback)', () async {
      when(
        () => mockStorage.read(key: _keyName),
      ).thenThrow(Exception('storage error'));

      await expectLater(
        service.encrypt('plain-text'),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        service.decrypt('cipher-text'),
        throwsA(isA<Exception>()),
      );
    });

    test('short stored key is archived and regenerated', () async {
      final shortKey = base64Encode([1, 2, 3, 4]);
      when(
        () => mockStorage.read(key: _keyName),
      ).thenAnswer((_) async => shortKey);
      when(
        () => mockStorage.read(key: 'budgie_encryption_key_version'),
      ).thenAnswer((_) async => null);

      // After detecting the short key, the service archives it, generates
      // a fresh key, and increments the version.  encrypt() should succeed
      // with the new key.
      final encrypted = await service.encrypt('padded-key-data');
      expect(encrypted, isNot('padded-key-data'));

      // Verify: corrupted key was archived under version 0
      verify(
        () => mockStorage.write(
          key: 'budgie_encryption_key_v0',
          value: shortKey,
        ),
      ).called(1);

      // Verify: old key deleted and new key + version stored
      verify(() => mockStorage.delete(key: _keyName)).called(1);
      verify(
        () => mockStorage.write(
          key: _keyName,
          value: any(named: 'value'),
        ),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: 'budgie_encryption_key_version',
          value: '1',
        ),
      ).called(1);
    });

    test('decrypt rejects tampered authenticated payload', () async {
      when(
        () => mockStorage.read(key: _keyName),
      ).thenAnswer((_) async => _validBase64Key);

      final encrypted = await service.encrypt('tamper-check');
      final tamperedBytes = base64Decode(encrypted);
      tamperedBytes[tamperedBytes.length - 1] ^= 0x01;

      await expectLater(
        service.decrypt(base64Encode(tamperedBytes)),
        throwsA(isA<FormatException>()),
      );
    });

    test('decrypt supports legacy iv+ciphertext payload format', () async {
      when(
        () => mockStorage.read(key: _keyName),
      ).thenAnswer((_) async => _validBase64Key);

      final keyBytes = Uint8List.fromList(base64Decode(_validBase64Key));
      final iv = enc.IV.fromLength(16);
      final encrypter = enc.Encrypter(
        enc.AES(enc.Key(keyBytes), mode: enc.AESMode.cbc),
      );
      final encrypted = encrypter.encrypt('legacy-payload', iv: iv);
      final legacyCipher = base64Encode([...iv.bytes, ...encrypted.bytes]);

      final decrypted = await service.decrypt(legacyCipher);
      expect(decrypted, 'legacy-payload');
    });

    group('key separation fallback', () {
      /// Builds an authenticated payload using the RAW master key
      /// (pre-separation format): BBTENC1! + IV + ciphertext + HMAC(rawKey).
      /// This simulates data encrypted before _deriveSubKeys was introduced.
      // ignore: no_leading_underscores_for_local_identifiers
      String _buildPreSeparationPayload(String plainText, Uint8List rawKey) {
        final magicBytes = ascii.encode('BBTENC1!');
        final iv = enc.IV.fromSecureRandom(16);
        final encrypter = enc.Encrypter(
          enc.AES(enc.Key(rawKey), mode: enc.AESMode.cbc),
        );
        final encrypted = encrypter.encrypt(plainText, iv: iv);

        final payload = <int>[
          ...magicBytes,
          ...iv.bytes,
          ...encrypted.bytes,
        ];
        final hmac = crypto.Hmac(crypto.sha256, rawKey);
        final mac = hmac.convert(payload).bytes;
        return base64Encode([...payload, ...mac]);
      }

      /// Derives sub-keys the same way EncryptionService._deriveSubKeys does.
      // ignore: no_leading_underscores_for_local_identifiers
      ({List<int> encKey, List<int> macKey}) _deriveSubKeys(
        List<int> masterKey,
      ) {
        final hmac = crypto.Hmac(crypto.sha256, masterKey);
        final encKey = hmac.convert(utf8.encode('BBTENC')).bytes;
        final macKey = hmac.convert(utf8.encode('BBTMAC')).bytes;
        return (
          encKey: encKey.sublist(0, 32),
          macKey: macKey.sublist(0, 32),
        );
      }

      test(
        'new format round-trip uses derived sub-keys',
        () async {
          when(
            () => mockStorage.read(key: _keyName),
          ).thenAnswer((_) async => _validBase64Key);

          final encrypted = await service.encrypt('derived-key-data');
          final decrypted = await service.decrypt(encrypted);

          expect(decrypted, 'derived-key-data');

          // Verify the payload is authenticated (has BBTENC1! magic prefix)
          final payloadBytes = base64Decode(encrypted);
          final magic = ascii.decode(payloadBytes.sublist(0, 8));
          expect(magic, 'BBTENC1!');
        },
      );

      test(
        'decrypts pre-separation payload via raw-key fallback',
        () async {
          when(
            () => mockStorage.read(key: _keyName),
          ).thenAnswer((_) async => _validBase64Key);

          final rawKey =
              Uint8List.fromList(base64Decode(_validBase64Key));
          final preSepCipher =
              _buildPreSeparationPayload('before-separation', rawKey);

          // The service should fail with derived keys (HMAC mismatch),
          // then succeed with the raw master key fallback.
          final decrypted = await service.decrypt(preSepCipher);
          expect(decrypted, 'before-separation');
        },
      );

      test(
        'derived-key payload cannot be decrypted with raw key only',
        () async {
          when(
            () => mockStorage.read(key: _keyName),
          ).thenAnswer((_) async => _validBase64Key);

          // Encrypt with the current service (uses derived keys)
          final encrypted = await service.encrypt('derived-only');

          // Attempt to manually decrypt with the RAW master key —
          // HMAC check should fail because the MAC was computed with
          // the derived macKey, not the raw key.
          final rawKey =
              Uint8List.fromList(base64Decode(_validBase64Key));
          final combined = base64Decode(encrypted);

          final payloadEnd = combined.length - 32; // MAC length
          final payload = combined.sublist(0, payloadEnd);
          final providedMac = combined.sublist(payloadEnd);

          final rawHmac = crypto.Hmac(crypto.sha256, rawKey);
          final rawMac = rawHmac.convert(payload).bytes;

          // The MAC computed with the raw key should NOT match the
          // MAC in the payload (which was computed with derived macKey).
          expect(providedMac, isNot(equals(rawMac)));
        },
      );

      test(
        'derived encKey differs from raw master key',
        () {
          final rawKey = base64Decode(_validBase64Key);
          final sub = _deriveSubKeys(rawKey);

          // Sub-keys must not equal the master key
          expect(sub.encKey, isNot(equals(rawKey)));
          expect(sub.macKey, isNot(equals(rawKey)));
          // encKey and macKey must differ from each other
          expect(sub.encKey, isNot(equals(sub.macKey)));
        },
      );

      test(
        'reEncrypt upgrades pre-separation payload to new format',
        () async {
          when(
            () => mockStorage.read(key: _keyName),
          ).thenAnswer((_) async => _validBase64Key);

          final rawKey =
              Uint8List.fromList(base64Decode(_validBase64Key));
          final preSepCipher =
              _buildPreSeparationPayload('upgrade-me', rawKey);

          // Re-encrypt should decrypt (via fallback) then encrypt (with
          // derived keys).
          final reEncrypted = await service.reEncrypt(preSepCipher);
          expect(reEncrypted, isNotNull);
          expect(reEncrypted, isNot(preSepCipher));

          // The re-encrypted payload should decrypt successfully.
          final decrypted = await service.decrypt(reEncrypted!);
          expect(decrypted, 'upgrade-me');

          // Verify the re-encrypted payload uses derived-key HMAC.
          // Manually verify the HMAC matches derived macKey.
          final sub = _deriveSubKeys(rawKey);
          final combined = base64Decode(reEncrypted);
          final payloadEnd = combined.length - 32;
          final payload = combined.sublist(0, payloadEnd);
          final providedMac = combined.sublist(payloadEnd);
          final derivedHmac =
              crypto.Hmac(crypto.sha256, sub.macKey);
          final expectedMac = derivedHmac.convert(payload).bytes;
          expect(providedMac, equals(expectedMac));
        },
      );

      test(
        'reEncrypt returns null for completely invalid ciphertext',
        () async {
          when(
            () => mockStorage.read(key: _keyName),
          ).thenAnswer((_) async => _validBase64Key);

          final result = await service.reEncrypt(base64Encode([1, 2, 3]));
          expect(result, isNull);
        },
      );

      test(
        'pre-separation payload with wrong key is rejected',
        () async {
          when(
            () => mockStorage.read(key: _keyName),
          ).thenAnswer((_) async => _validBase64Key);

          // Build payload with a completely different key
          final wrongKey = Uint8List.fromList(
            List<int>.generate(32, (i) => 255 - i),
          );
          final wrongKeyCipher =
              _buildPreSeparationPayload('wrong-key-data', wrongKey);

          // Neither derived keys nor raw key should match — both should fail.
          await expectLater(
            service.decrypt(wrongKeyCipher),
            throwsA(isA<FormatException>()),
          );
        },
      );
    });
  });
}
