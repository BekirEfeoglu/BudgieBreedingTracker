import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

const _keyName = 'budgie_encryption_key';
const _keyVersionName = 'budgie_encryption_key_version';
const _previousKeyPrefix = 'budgie_encryption_key_v';
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

  group('Key management helpers', () {
    group('_getOrCreateKeyBytes', () {
      test('creates and stores new key when no key exists', () async {
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => null);

        String? storedKey;
        when(
          () => mockStorage.write(key: _keyName, value: any(named: 'value')),
        ).thenAnswer((invocation) async {
          storedKey = invocation.namedArguments[#value] as String?;
        });

        // Trigger key creation via encrypt
        final encrypted = await service.encrypt('test-data');
        expect(encrypted, isNotEmpty);
        expect(storedKey, isNotNull);

        // Stored key should decode to exactly 32 bytes
        final decoded = base64Decode(storedKey!);
        expect(decoded.length, 32);
      });

      test('caches key bytes and does not re-read storage', () async {
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => _validBase64Key);

        await service.encrypt('first');
        await service.encrypt('second');
        await service.encrypt('third');

        // Storage should be read only once due to caching
        verify(() => mockStorage.read(key: _keyName)).called(1);
      });

      test('regenerates key when stored key is corrupted (too short)',
          () async {
        final shortKey = base64Encode([1, 2, 3, 4, 5]);
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => shortKey);
        when(() => mockStorage.read(key: _keyVersionName))
            .thenAnswer((_) async => null);

        final encrypted = await service.encrypt('data-after-recovery');
        expect(encrypted, isNotEmpty);

        // Corrupted key should be archived under version 0
        verify(
          () => mockStorage.write(
            key: '${_previousKeyPrefix}0',
            value: shortKey,
          ),
        ).called(1);

        // Old key deleted, new key and version stored
        verify(() => mockStorage.delete(key: _keyName)).called(1);
        verify(
          () =>
              mockStorage.write(key: _keyName, value: any(named: 'value')),
        ).called(1);
        verify(
          () => mockStorage.write(key: _keyVersionName, value: '1'),
        ).called(1);
      });

      test(
          'regenerates key with correct version increment when existing version is non-zero',
          () async {
        final shortKey = base64Encode([10, 20]);
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => shortKey);
        when(() => mockStorage.read(key: _keyVersionName))
            .thenAnswer((_) async => '3');

        await service.encrypt('data');

        // Should archive under version 3
        verify(
          () => mockStorage.write(
            key: '${_previousKeyPrefix}3',
            value: shortKey,
          ),
        ).called(1);
        // New version should be 4
        verify(
          () => mockStorage.write(key: _keyVersionName, value: '4'),
        ).called(1);
      });
    });

    group('_zeroCachedKey (via dispose/deleteKey)', () {
      test('dispose clears cache and forces re-read on next operation',
          () async {
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => _validBase64Key);

        await service.encrypt('before-dispose');
        service.dispose();
        await service.encrypt('after-dispose');

        // Two reads: once before dispose, once after
        verify(() => mockStorage.read(key: _keyName)).called(2);
      });

      test('deleteKey clears cache and removes from storage', () async {
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => _validBase64Key);

        await service.encrypt('before-delete');
        await service.deleteKey();

        verify(() => mockStorage.delete(key: _keyName)).called(1);

        // Next encrypt should re-read storage
        await service.encrypt('after-delete');
        verify(() => mockStorage.read(key: _keyName)).called(2);
      });
    });

    group('_getCurrentKeyVersion', () {
      test('returns 0 when no version is stored', () async {
        // Version is checked indirectly through rotateKey
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => _validBase64Key);
        when(() => mockStorage.read(key: _keyVersionName))
            .thenAnswer((_) async => null);

        final newVersion = await service.rotateKey();
        expect(newVersion, 1); // 0 + 1

        verify(
          () => mockStorage.write(key: _keyVersionName, value: '1'),
        ).called(1);
      });

      test('returns stored version number', () async {
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => _validBase64Key);
        when(() => mockStorage.read(key: _keyVersionName))
            .thenAnswer((_) async => '5');

        final newVersion = await service.rotateKey();
        expect(newVersion, 6); // 5 + 1
      });

      test('handles non-numeric version string gracefully', () async {
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => _validBase64Key);
        when(() => mockStorage.read(key: _keyVersionName))
            .thenAnswer((_) async => 'invalid');

        // Should fallback to 0
        final newVersion = await service.rotateKey();
        expect(newVersion, 1);
      });
    });

    group('_generateKey', () {
      test('generated keys are unique across multiple rotations', () async {
        when(() => mockStorage.read(key: _keyVersionName))
            .thenAnswer((_) async => '0');

        final storedKeys = <String>[];
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => _validBase64Key);
        when(
          () => mockStorage.write(key: _keyName, value: any(named: 'value')),
        ).thenAnswer((invocation) async {
          storedKeys.add(invocation.namedArguments[#value] as String);
        });

        await service.rotateKey();
        // Reset version for second rotation
        when(() => mockStorage.read(key: _keyVersionName))
            .thenAnswer((_) async => '1');
        await service.rotateKey();

        expect(storedKeys.length, 2);
        expect(storedKeys[0], isNot(storedKeys[1]));

        // Both should decode to 32 bytes
        for (final key in storedKeys) {
          expect(base64Decode(key).length, 32);
        }
      });
    });

    group('_loadPreviousKeys (via decrypt fallback)', () {
      test('falls back to previous key version when active key fails',
          () async {
        // Key used for original encryption
        final originalKeyBytes =
            Uint8List.fromList(List<int>.generate(32, (i) => i));
        final originalBase64 = base64Encode(originalKeyBytes);

        // New active key (different)
        final newKeyBytes =
            Uint8List.fromList(List<int>.generate(32, (i) => 255 - i));
        final newBase64 = base64Encode(newKeyBytes);

        // Encrypt with original key (legacy format for simplicity)
        final iv = enc.IV.fromLength(16);
        final encrypter = enc.Encrypter(
          enc.AES(enc.Key(originalKeyBytes), mode: enc.AESMode.cbc),
        );
        final encrypted = encrypter.encrypt('old-key-data', iv: iv);
        final legacyCipher = base64Encode([...iv.bytes, ...encrypted.bytes]);

        // Setup: active key is new, previous key v0 is original
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => newBase64);
        when(() => mockStorage.read(key: _keyVersionName))
            .thenAnswer((_) async => '1');
        when(() => mockStorage.read(key: '${_previousKeyPrefix}0'))
            .thenAnswer((_) async => originalBase64);

        final decrypted = await service.decrypt(legacyCipher);
        expect(decrypted, 'old-key-data');
      });

      test('throws when no previous key can decrypt the data', () async {
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => _validBase64Key);
        when(() => mockStorage.read(key: _keyVersionName))
            .thenAnswer((_) async => '1');
        when(() => mockStorage.read(key: '${_previousKeyPrefix}0'))
            .thenAnswer((_) async => null);

        // Random ciphertext that no key can decrypt
        final badCipher = base64Encode(List<int>.generate(64, (i) => i));

        await expectLater(
          service.decrypt(badCipher),
          throwsA(anything),
        );
      });

      test('skips corrupted archived keys during fallback', () async {
        final newKeyBytes =
            Uint8List.fromList(List<int>.generate(32, (i) => 200 + (i % 56)));
        final newBase64 = base64Encode(newKeyBytes);

        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => newBase64);
        when(() => mockStorage.read(key: _keyVersionName))
            .thenAnswer((_) async => '2');

        // v1 is corrupted (too short)
        when(() => mockStorage.read(key: '${_previousKeyPrefix}1'))
            .thenAnswer((_) async => base64Encode([1, 2, 3]));
        // v0 does not exist
        when(() => mockStorage.read(key: '${_previousKeyPrefix}0'))
            .thenAnswer((_) async => null);

        final badCipher = base64Encode(List<int>.generate(48, (i) => i));

        // Should fail since no valid previous key exists
        await expectLater(
          service.decrypt(badCipher),
          throwsA(anything),
        );
      });
    });

    group('rotateKey', () {
      test('archives current key and generates new one', () async {
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => _validBase64Key);
        when(() => mockStorage.read(key: _keyVersionName))
            .thenAnswer((_) async => '0');

        final newVersion = await service.rotateKey();
        expect(newVersion, 1);

        // Current key archived under v0
        verify(
          () => mockStorage.write(
            key: '${_previousKeyPrefix}0',
            value: _validBase64Key,
          ),
        ).called(1);

        // New key written
        verify(
          () => mockStorage.write(key: _keyName, value: any(named: 'value')),
        ).called(1);

        // Version updated
        verify(
          () => mockStorage.write(key: _keyVersionName, value: '1'),
        ).called(1);
      });

      test('handles rotation when no current key exists', () async {
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => null);
        when(() => mockStorage.read(key: _keyVersionName))
            .thenAnswer((_) async => null);

        final newVersion = await service.rotateKey();
        expect(newVersion, 1);

        // No archive write for null key
        verifyNever(
          () => mockStorage.write(
            key: '${_previousKeyPrefix}0',
            value: any(named: 'value'),
          ),
        );
      });

      test('clears cache so next operation uses new key', () async {
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => _validBase64Key);
        when(() => mockStorage.read(key: _keyVersionName))
            .thenAnswer((_) async => '0');

        // Warm cache
        await service.encrypt('before-rotation');
        verify(() => mockStorage.read(key: _keyName)).called(1);

        await service.rotateKey();

        // After rotation, cache is cleared; next encrypt re-reads
        await service.encrypt('after-rotation');
        verify(() => mockStorage.read(key: _keyName)).called(2);
      });
    });

    group('needsReEncryption', () {
      test('returns false for empty string', () {
        expect(service.needsReEncryption(''), isFalse);
      });

      test('returns false for invalid base64', () {
        expect(service.needsReEncryption('not-valid-base64!!!'), isFalse);
      });

      test('returns false for current format payload', () async {
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => _validBase64Key);

        final encrypted = await service.encrypt('current-format');
        expect(service.needsReEncryption(encrypted), isFalse);
      });

      test('returns true for legacy format payload', () {
        final keyBytes =
            Uint8List.fromList(base64Decode(_validBase64Key));
        final iv = enc.IV.fromLength(16);
        final encrypter = enc.Encrypter(
          enc.AES(enc.Key(keyBytes), mode: enc.AESMode.cbc),
        );
        final encrypted = encrypter.encrypt('legacy', iv: iv);
        final legacy = base64Encode([...iv.bytes, ...encrypted.bytes]);

        expect(service.needsReEncryption(legacy), isTrue);
      });
    });

    group('reEncrypt', () {
      test('re-encrypts successfully and produces different ciphertext',
          () async {
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => _validBase64Key);

        final original = await service.encrypt('re-encrypt-me');
        final reEncrypted = await service.reEncrypt(original);

        expect(reEncrypted, isNotNull);
        expect(reEncrypted, isNot(original));

        final decrypted = await service.decrypt(reEncrypted!);
        expect(decrypted, 're-encrypt-me');
      });

      test('returns null for undecryptable ciphertext', () async {
        when(() => mockStorage.read(key: _keyName))
            .thenAnswer((_) async => _validBase64Key);
        when(() => mockStorage.read(key: _keyVersionName))
            .thenAnswer((_) async => '0');

        // No previous keys
        final result = await service.reEncrypt(base64Encode([1, 2, 3]));
        expect(result, isNull);
      });
    });
  });
}
