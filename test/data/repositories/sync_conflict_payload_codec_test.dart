import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_service.dart';
import 'package:budgie_breeding_tracker/data/repositories/sync_conflict_payload_codec.dart';

class _MockEncryptionService extends Mock implements EncryptionService {}

void main() {
  late _MockEncryptionService encryption;
  late SyncConflictPayloadCodec codec;

  setUp(() {
    encryption = _MockEncryptionService();
    codec = SyncConflictPayloadCodec(encryption);
  });

  test('round-trips a versioned encrypted snapshot', () async {
    when(() => encryption.encrypt(any())).thenAnswer((invocation) async {
      return base64Encode(
        utf8.encode(invocation.positionalArguments.single as String),
      );
    });
    when(() => encryption.decrypt(any())).thenAnswer((invocation) async {
      return utf8.decode(
        base64Decode(invocation.positionalArguments.single as String),
      );
    });
    final payload = {
      'id': 'bird-1',
      'user_id': 'user-1',
      'name': 'Local name',
      'notes': 'sensitive note',
    };

    final encrypted = await codec.encode(
      tableName: 'birds',
      recordId: 'bird-1',
      userId: 'user-1',
      payload: payload,
    );
    final restored = await codec.decode(
      encryptedPayload: encrypted,
      payloadVersion: 1,
      tableName: 'birds',
      recordId: 'bird-1',
      userId: 'user-1',
    );

    expect(restored, payload);
    expect(encrypted, isNot(contains('sensitive note')));
  });

  test('rejects oversized payload before encryption', () async {
    final payload = {
      'id': 'bird-1',
      'user_id': 'user-1',
      'notes': List.filled(
        SyncConflictPayloadCodec.maxSnapshotBytes,
        'x',
      ).join(),
    };

    await expectLater(
      codec.encode(
        tableName: 'birds',
        recordId: 'bird-1',
        userId: 'user-1',
        payload: payload,
      ),
      throwsA(
        isA<SyncConflictPayloadException>().having(
          (e) => e.code,
          'code',
          'payload_too_large',
        ),
      ),
    );
    verifyNever(() => encryption.encrypt(any()));
  });

  test('returns sanitized failure for corrupt payload', () async {
    when(
      () => encryption.decrypt('corrupt'),
    ).thenAnswer((_) async => '{not-json');

    await expectLater(
      codec.decode(
        encryptedPayload: 'corrupt',
        payloadVersion: 1,
        tableName: 'birds',
        recordId: 'bird-1',
        userId: 'user-1',
      ),
      throwsA(
        isA<SyncConflictPayloadException>()
            .having((e) => e.code, 'code', 'payload_decode_failed')
            .having(
              (e) => e.toString(),
              'message',
              isNot(contains('{not-json')),
            ),
      ),
    );
  });
}
