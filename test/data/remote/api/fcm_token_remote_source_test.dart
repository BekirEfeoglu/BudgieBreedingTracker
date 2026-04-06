import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/remote/api/fcm_token_remote_source.dart';

import '../../../helpers/mocks.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late _MockSupabaseClient client;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late FcmTokenRemoteSource source;

  setUp(() {
    client = _MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    when(() => client.auth).thenReturn(mockAuth);
    source = FcmTokenRemoteSource(client);
  });

  group('FcmTokenRemoteSource', () {
    group('upsertToken ownership check', () {
      test('throws NetworkException when userId does not match auth user', () {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.id).thenReturn('different-user');

        expect(
          () => source.upsertToken(
            userId: 'user-1',
            token: 'token-abc',
            platform: 'ios',
          ),
          throwsA(isA<NetworkException>()),
        );
      });

      test('throws NetworkException when no auth user', () {
        when(() => mockAuth.currentUser).thenReturn(null);

        expect(
          () => source.upsertToken(
            userId: 'user-1',
            token: 'token-abc',
            platform: 'ios',
          ),
          throwsA(isA<NetworkException>()),
        );
      });

      test('throws NetworkException if auth returns empty user id', () {
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.id).thenReturn('');

        expect(
          () => source.upsertToken(
            userId: 'user-1',
            token: 'token-abc',
            platform: 'ios',
          ),
          throwsA(isA<NetworkException>()),
        );
      });
    });
  });
}
