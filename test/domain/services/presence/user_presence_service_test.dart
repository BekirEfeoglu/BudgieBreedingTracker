import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/remote/api/user_presence_remote_source.dart';
import 'package:budgie_breeding_tracker/domain/services/presence/user_presence_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserPresenceRemoteSource extends Mock
    implements UserPresenceRemoteSource {}

void main() {
  group('UserPresenceService', () {
    late MockUserPresenceRemoteSource remoteSource;
    late UserPresenceService service;

    setUpAll(() {
      registerFallbackValue(<String, dynamic>{});
    });

    setUp(() {
      remoteSource = MockUserPresenceRemoteSource();
      service = UserPresenceService(remoteSource);
      when(() => remoteSource.currentAuthUserId).thenReturn('user-1');
      when(() => remoteSource.upsertSession(any())).thenAnswer((_) async {});
      when(
        () => remoteSource.updateSession(
          sessionId: any(named: 'sessionId'),
          userId: any(named: 'userId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});
    });

    test(
      'startSession upserts a client generated id without select roundtrip',
      () async {
        final sessionId = await service.startSession('user-1');

        expect(sessionId, isNotNull);
        final payload =
            verify(
                  () => remoteSource.upsertSession(captureAny()),
                ).captured.single
                as Map<String, dynamic>;
        expect(payload[SupabaseConstants.colId], sessionId);
        expect(payload[SupabaseConstants.colUserId], 'user-1');
        expect(payload[SupabaseConstants.colPlatform], isNotEmpty);
        expect(payload[SupabaseConstants.colIsActive], true);
        expect(payload[SupabaseConstants.colLastActiveAt], isA<String>());
        expect(payload[SupabaseConstants.colExpiresAt], isA<String>());
      },
    );

    test('startSession skips writes when auth user does not match', () async {
      final sessionId = await service.startSession('user-2');

      expect(sessionId, isNull);
      verifyNever(() => remoteSource.upsertSession(any()));
    });

    test('heartbeat updates only the owned session row', () async {
      await service.heartbeat(userId: 'user-1', sessionId: 'session-1');

      final captured = verify(
        () => remoteSource.updateSession(
          sessionId: captureAny(named: 'sessionId'),
          userId: captureAny(named: 'userId'),
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured[0], 'session-1');
      expect(captured[1], 'user-1');
      final payload = captured[2] as Map<String, dynamic>;
      expect(payload[SupabaseConstants.colIsActive], true);
      expect(payload[SupabaseConstants.colLastActiveAt], isA<String>());
      expect(payload[SupabaseConstants.colExpiresAt], isA<String>());
    });

    test('heartbeat skips writes when auth user does not match', () async {
      await service.heartbeat(userId: 'user-2', sessionId: 'session-1');

      verifyNever(
        () => remoteSource.updateSession(
          sessionId: any(named: 'sessionId'),
          userId: any(named: 'userId'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('endSession marks the owned session inactive', () async {
      await service.endSession(userId: 'user-1', sessionId: 'session-1');

      final captured = verify(
        () => remoteSource.updateSession(
          sessionId: captureAny(named: 'sessionId'),
          userId: captureAny(named: 'userId'),
          payload: captureAny(named: 'payload'),
        ),
      ).captured;
      expect(captured[0], 'session-1');
      expect(captured[1], 'user-1');
      final payload = captured[2] as Map<String, dynamic>;
      expect(payload[SupabaseConstants.colIsActive], false);
      expect(payload[SupabaseConstants.colLastActiveAt], isA<String>());
    });
  });
}
