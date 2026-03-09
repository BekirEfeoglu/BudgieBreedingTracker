import 'dart:convert';

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

    test('short stored key is padded and still decrypts correctly', () async {
      final shortKey = base64Encode([1, 2, 3, 4]);
      when(
        () => mockStorage.read(key: _keyName),
      ).thenAnswer((_) async => shortKey);

      final encrypted = await service.encrypt('padded-key-data');
      final decrypted = await service.decrypt(encrypted);

      expect(decrypted, 'padded-key-data');
    });
  });
}
