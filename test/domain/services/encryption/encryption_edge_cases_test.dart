import 'dart:convert';
import 'dart:math';

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
      () => mockStorage.read(key: _keyName),
    ).thenAnswer((_) async => _validBase64Key);
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

  group('EncryptionService edge cases', () {
    group('empty string handling', () {
      test('encrypt throws FormatException for empty string', () async {
        await expectLater(
          service.encrypt(''),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('empty'),
            ),
          ),
        );
      });

      test('decrypt throws FormatException for empty string', () async {
        await expectLater(
          service.decrypt(''),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('empty'),
            ),
          ),
        );
      });
    });

    group('very long strings', () {
      test('encrypts and decrypts 10KB string correctly', () async {
        final longString = 'A' * 10240;

        final encrypted = await service.encrypt(longString);
        final decrypted = await service.decrypt(encrypted);

        expect(decrypted, longString);
        expect(decrypted.length, 10240);
      });

      test('encrypts and decrypts 50KB string correctly', () async {
        final longString = List.generate(
          50 * 1024,
          (i) => String.fromCharCode(32 + (i % 95)),
        ).join();

        final encrypted = await service.encrypt(longString);
        final decrypted = await service.decrypt(encrypted);

        expect(decrypted, longString);
      });
    });

    group('unicode strings', () {
      test('emoji roundtrips correctly', () async {
        const emoji = '\u{1F600}\u{1F4A9}\u{1F680}\u{2764}\u{FE0F}\u{1F1F9}\u{1F1F7}';

        final encrypted = await service.encrypt(emoji);
        final decrypted = await service.decrypt(encrypted);

        expect(decrypted, emoji);
      });

      test('CJK characters roundtrip correctly', () async {
        const cjk = '\u4F60\u597D\u4E16\u754C\u3053\u3093\u306B\u3061\u306F';

        final encrypted = await service.encrypt(cjk);
        final decrypted = await service.decrypt(encrypted);

        expect(decrypted, cjk);
      });

      test('Arabic text roundtrips correctly', () async {
        const arabic = '\u0645\u0631\u062D\u0628\u0627 \u0628\u0627\u0644\u0639\u0627\u0644\u0645';

        final encrypted = await service.encrypt(arabic);
        final decrypted = await service.decrypt(encrypted);

        expect(decrypted, arabic);
      });

      test('mixed unicode and ASCII roundtrips correctly', () async {
        const mixed = 'Hello \u4E16\u754C \u{1F600} Merhaba';

        final encrypted = await service.encrypt(mixed);
        final decrypted = await service.decrypt(encrypted);

        expect(decrypted, mixed);
      });
    });

    group('special characters', () {
      test('newlines and tabs roundtrip correctly', () async {
        const special = 'line1\nline2\ttab\r\nwindows';

        final encrypted = await service.encrypt(special);
        final decrypted = await service.decrypt(encrypted);

        expect(decrypted, special);
      });

      test('null bytes roundtrip correctly', () async {
        const withNull = 'before\x00after';

        final encrypted = await service.encrypt(withNull);
        final decrypted = await service.decrypt(encrypted);

        expect(decrypted, withNull);
      });

      test('backslashes and quotes roundtrip correctly', () async {
        const special = 'path\\to\\file "quoted" and \\\'escaped\\\'';

        final encrypted = await service.encrypt(special);
        final decrypted = await service.decrypt(encrypted);

        expect(decrypted, special);
      });

      test('JSON string roundtrips correctly', () async {
        const json = '{"key": "value", "nested": {"arr": [1, 2, 3]}}';

        final encrypted = await service.encrypt(json);
        final decrypted = await service.decrypt(encrypted);

        expect(decrypted, json);
      });
    });

    group('corrupted ciphertext', () {
      test('random bytes throw on decrypt', () async {
        final random = Random.secure();
        final randomBytes = List<int>.generate(64, (_) => random.nextInt(256));
        final encoded = base64Encode(randomBytes);

        // Random bytes hit the legacy path (no magic prefix) and AES
        // decryption fails with either ArgumentError (bad padding) or
        // FormatException depending on the random data.
        await expectLater(
          service.decrypt(encoded),
          throwsA(anything),
        );
      });

      test('truncated ciphertext throws on decrypt', () async {
        final encrypted = await service.encrypt('test data');
        final bytes = base64Decode(encrypted);
        // Truncate to just the magic prefix + partial IV
        final truncated = base64Encode(bytes.sublist(0, 12));

        await expectLater(
          service.decrypt(truncated),
          throwsA(isA<FormatException>()),
        );
      });

      test('base64 of very short data throws FormatException', () async {
        final shortData = base64Encode([1, 2, 3]);

        await expectLater(
          service.decrypt(shortData),
          throwsA(isA<FormatException>()),
        );
      });

      test('base64 of data just under minimum length throws', () async {
        // Magic(8) + IV(16) + 1 byte ciphertext + HMAC(32) = 57 minimum
        // Provide magic prefix + partial data
        final magicBytes = ascii.encode('BBTENC1!');
        final tooShort = <int>[...magicBytes, ...List.filled(10, 0)];
        final encoded = base64Encode(tooShort);

        await expectLater(
          service.decrypt(encoded),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('HMAC tampering', () {
      test('modified HMAC throws FormatException with integrity message',
          () async {
        final encrypted = await service.encrypt('integrity test');
        final bytes = base64Decode(encrypted);

        // Flip a bit in the last byte (HMAC region)
        bytes[bytes.length - 1] ^= 0xFF;
        final tampered = base64Encode(bytes);

        await expectLater(
          service.decrypt(tampered),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('integrity'),
            ),
          ),
        );
      });

      test('zeroed HMAC throws FormatException with integrity message',
          () async {
        final encrypted = await service.encrypt('zero mac test');
        final bytes = base64Decode(encrypted);

        // Zero out the entire HMAC (last 32 bytes)
        for (var i = bytes.length - 32; i < bytes.length; i++) {
          bytes[i] = 0;
        }
        final tampered = base64Encode(bytes);

        await expectLater(
          service.decrypt(tampered),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('integrity'),
            ),
          ),
        );
      });
    });

    group('IV tampering', () {
      test('modified IV produces wrong output or throws', () async {
        final encrypted = await service.encrypt('iv tamper test');
        final bytes = base64Decode(encrypted);

        // Magic is 8 bytes, IV starts at offset 8
        // Flip bits in the IV region
        bytes[8] ^= 0xFF;
        bytes[9] ^= 0xFF;
        final tampered = base64Encode(bytes);

        // Modifying the IV changes the payload, so HMAC check should fail
        await expectLater(
          service.decrypt(tampered),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('double encryption', () {
      test('double encrypt then double decrypt roundtrips', () async {
        const original = 'double encrypted secret';

        final encrypted1 = await service.encrypt(original);
        final encrypted2 = await service.encrypt(encrypted1);

        final decrypted1 = await service.decrypt(encrypted2);
        final decrypted2 = await service.decrypt(decrypted1);

        expect(decrypted2, original);
      });
    });

    group('concurrent operations', () {
      test('concurrent encrypt calls produce valid distinct ciphertexts',
          () async {
        const plainText = 'concurrent test';

        final futures = List.generate(
          10,
          (_) => service.encrypt(plainText),
        );
        final results = await Future.wait(futures);

        // All results should be valid and distinct (random IVs)
        final uniqueResults = results.toSet();
        expect(uniqueResults.length, results.length);

        // All should decrypt to the same plaintext
        for (final cipher in results) {
          final decrypted = await service.decrypt(cipher);
          expect(decrypted, plainText);
        }
      });

      test('concurrent encrypt and decrypt calls work correctly', () async {
        // First create some ciphertexts
        final encrypted1 = await service.encrypt('msg1');
        final encrypted2 = await service.encrypt('msg2');
        final encrypted3 = await service.encrypt('msg3');

        // Now run encrypt + decrypt concurrently
        final results = await Future.wait([
          service.encrypt('new1'),
          service.decrypt(encrypted1),
          service.encrypt('new2'),
          service.decrypt(encrypted2),
          service.encrypt('new3'),
          service.decrypt(encrypted3),
        ]);

        // Verify decryptions (indices 1, 3, 5)
        expect(results[1], 'msg1');
        expect(results[3], 'msg2');
        expect(results[5], 'msg3');

        // Verify encryptions produced non-empty, different outputs
        expect(results[0], isNot(results[2]));
        expect(results[2], isNot(results[4]));
      });
    });
  });
}
