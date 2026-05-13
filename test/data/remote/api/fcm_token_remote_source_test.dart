import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/remote/api/fcm_token_remote_source.dart';

import '../../../helpers/fake_supabase.dart';
import '../../../helpers/mocks.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _RpcTrackingClient extends Fake implements SupabaseClient {
  _RpcTrackingClient(this._auth);

  final GoTrueClient _auth;
  final rpcCalls = <({String fn, Map<String, dynamic>? params})>[];

  @override
  GoTrueClient get auth => _auth;

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    get = false,
  }) {
    rpcCalls.add((fn: fn, params: params));
    return FakeFilterBuilder<T>();
  }
}

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

      test(
        'claims token through RPC when auth user owns the request',
        () async {
          when(() => mockAuth.currentUser).thenReturn(mockUser);
          when(() => mockUser.id).thenReturn('user-1');
          final rpcClient = _RpcTrackingClient(mockAuth);
          final rpcSource = FcmTokenRemoteSource(rpcClient);

          await rpcSource.upsertToken(
            userId: 'user-1',
            token: 'token-abc',
            platform: 'android',
            deviceId: 'device-1',
          );

          expect(rpcClient.rpcCalls, hasLength(1));
          expect(rpcClient.rpcCalls.single.fn, 'claim_fcm_token');
          expect(rpcClient.rpcCalls.single.params, {
            'p_user_id': 'user-1',
            'p_token': 'token-abc',
            'p_platform': 'android',
            'p_device_id': 'device-1',
          });
        },
      );
    });
  });
}
