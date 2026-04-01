import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

const _keyName = 'budgie_encryption_key';
final _validBase64Key = base64Encode(List<int>.generate(32, (i) => i));

void main() {
  group('looksLikeEncrypted', () {
    test('returns false for empty string', () {
      expect(looksLikeEncrypted(''), isFalse);
    });

    test('returns false for plain text', () {
      expect(looksLikeEncrypted('TR-2024-001'), isFalse);
    });

    test('returns false for short base64', () {
      // 10 bytes encoded — less than 17 byte minimum
      final short = base64Encode(List<int>.generate(10, (i) => i));
      expect(looksLikeEncrypted(short), isFalse);
    });

    test('returns true for base64 with 17+ decoded bytes', () {
      // 17 bytes: IV(16) + 1 byte ciphertext minimum
      final valid = base64Encode(List<int>.generate(17, (i) => i));
      expect(looksLikeEncrypted(valid), isTrue);
    });

    test('returns true for long base64 payload', () {
      final long = base64Encode(List<int>.generate(100, (i) => i % 256));
      expect(looksLikeEncrypted(long), isTrue);
    });

    test('returns false for invalid base64', () {
      expect(looksLikeEncrypted('not-valid-base64!!!'), isFalse);
    });

    test('returns true for real encrypted output', () async {
      final mockStorage = MockFlutterSecureStorage();
      when(() => mockStorage.read(key: _keyName))
          .thenAnswer((_) async => _validBase64Key);
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final service = EncryptionService(mockStorage);
      final encrypted = await service.encrypt('test-data');
      expect(looksLikeEncrypted(encrypted), isTrue);
    });

    test('returns false for exactly 16 decoded bytes', () {
      // Exactly IV size, no ciphertext — should be false
      final ivOnly = base64Encode(List<int>.generate(16, (i) => i));
      expect(looksLikeEncrypted(ivOnly), isFalse);
    });
  });

  group('auditPayloads', () {
    late MockFlutterSecureStorage mockStorage;
    late EncryptionService service;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      when(() => mockStorage.read(key: _keyName))
          .thenAnswer((_) async => _validBase64Key);
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});
      service = EncryptionService(mockStorage);
    });

    test('returns all zeros for empty list', () {
      final result = service.auditPayloads([]);
      expect(result.current, 0);
      expect(result.legacy, 0);
      expect(result.invalid, 0);
    });

    test('classifies empty strings as invalid', () {
      final result = service.auditPayloads(['', '']);
      expect(result.invalid, 2);
      expect(result.current, 0);
      expect(result.legacy, 0);
    });

    test('classifies non-base64 strings as invalid', () {
      final result = service.auditPayloads(['not-base64!!!', '???']);
      expect(result.invalid, 2);
      expect(result.current, 0);
      expect(result.legacy, 0);
    });

    test('classifies current format payloads', () async {
      // Encrypt values to get current-format payloads (BBTENC1! prefix)
      final encrypted1 = await service.encrypt('value-1');
      final encrypted2 = await service.encrypt('value-2');

      final result = service.auditPayloads([encrypted1, encrypted2]);
      expect(result.current, 2);
      expect(result.legacy, 0);
      expect(result.invalid, 0);
    });

    test('classifies legacy format payloads (no magic prefix)', () {
      // Create a legacy payload: base64(IV + ciphertext) without BBTENC1! prefix
      final keyBytes = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final iv = enc.IV.fromLength(16);
      final encrypter = enc.Encrypter(
        enc.AES(enc.Key(keyBytes), mode: enc.AESMode.cbc),
      );
      final encrypted = encrypter.encrypt('legacy-data', iv: iv);
      final legacyPayload = <int>[...iv.bytes, ...encrypted.bytes];
      final legacyBase64 = base64Encode(legacyPayload);

      final result = service.auditPayloads([legacyBase64]);
      expect(result.legacy, 1);
      expect(result.current, 0);
      expect(result.invalid, 0);
    });

    test('classifies mixed payloads correctly', () async {
      // Current format
      final currentPayload = await service.encrypt('current-value');

      // Legacy format (no BBTENC1! prefix)
      final keyBytes = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final iv = enc.IV.fromLength(16);
      final encrypter = enc.Encrypter(
        enc.AES(enc.Key(keyBytes), mode: enc.AESMode.cbc),
      );
      final encrypted = encrypter.encrypt('legacy-data', iv: iv);
      final legacyPayload = <int>[...iv.bytes, ...encrypted.bytes];
      final legacyBase64 = base64Encode(legacyPayload);

      // Invalid
      const invalidPayload = '';
      const invalidBase64 = 'not-base64!!!';

      final result = service.auditPayloads([
        currentPayload,
        legacyBase64,
        invalidPayload,
        invalidBase64,
      ]);

      expect(result.current, 1);
      expect(result.legacy, 1);
      expect(result.invalid, 2);
    });
  });
}
