import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

import '../../../helpers/fake_supabase.dart';
import '../../../helpers/mocks.dart';

/// Fake SupabaseClient that records RPC calls.
/// Avoids mocktail issues with Future-implementing return types.
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
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late AuthActions actions;

  setUpAll(() {
    registerFallbackValue(UserAttributes());
    registerFallbackValue(SignOutScope.local);
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    actions = AuthActions(mockClient);
  });

  group('_AuthAccountMixin.changePassword', () {
    test('throws AuthException when no authenticated user', () {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(
        () =>
            actions.changePassword(currentPassword: 'old', newPassword: 'new'),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws AuthException when user has no email', () {
      final user = MockUser();
      when(() => user.email).thenReturn(null);
      when(() => mockAuth.currentUser).thenReturn(user);

      expect(
        () =>
            actions.changePassword(currentPassword: 'old', newPassword: 'new'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'No authenticated user',
          ),
        ),
      );
    });

    test('re-authenticates with current password before updating', () async {
      final user = MockUser();
      when(() => user.email).thenReturn('user@test.com');
      when(() => mockAuth.currentUser).thenReturn(user);
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => AuthResponse());
      when(() => mockAuth.updateUser(any())).thenAnswer(
        (_) async => UserResponse.fromJson({
          'id': 'u1',
          'email': 'user@test.com',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': '2024-01-01T00:00:00Z',
        }),
      );
      when(
        () => mockAuth.signOut(scope: any(named: 'scope')),
      ).thenAnswer((_) async {});

      await actions.changePassword(
        currentPassword: 'oldPass123',
        newPassword: 'newPass456',
      );

      verify(
        () => mockAuth.signInWithPassword(
          email: 'user@test.com',
          password: 'oldPass123',
        ),
      ).called(1);
      verify(() => mockAuth.updateUser(any())).called(1);
      // Verify other sessions are invalidated after password change
      verify(() => mockAuth.signOut(scope: SignOutScope.others)).called(1);
    });

    test('propagates error when re-authentication fails', () async {
      final user = MockUser();
      when(() => user.email).thenReturn('user@test.com');
      when(() => mockAuth.currentUser).thenReturn(user);
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Invalid login credentials'));

      expect(
        () => actions.changePassword(
          currentPassword: 'wrong',
          newPassword: 'new',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('propagates error when password update fails', () async {
      final user = MockUser();
      when(() => user.email).thenReturn('user@test.com');
      when(() => mockAuth.currentUser).thenReturn(user);
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => AuthResponse());
      when(() => mockAuth.updateUser(any())).thenThrow(
        const AuthException('Weak password'),
      );

      expect(
        () => actions.changePassword(
          currentPassword: 'old',
          newPassword: '1',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('_AuthAccountMixin.signOut', () {
    test('calls client.auth.signOut with default (local) scope', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await actions.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });

    test('propagates error from signOut', () {
      when(() => mockAuth.signOut())
          .thenThrow(const AuthException('Sign out failed'));

      expect(() => actions.signOut(), throwsA(isA<AuthException>()));
    });
  });

  group('_AuthAccountMixin.signOutAllSessions', () {
    test('calls signOut with global scope', () async {
      when(
        () => mockAuth.signOut(scope: any(named: 'scope')),
      ).thenAnswer((_) async {});

      await actions.signOutAllSessions();

      verify(() => mockAuth.signOut(scope: SignOutScope.global)).called(1);
    });
  });

  group('_AuthAccountMixin.requestAccountDeletion', () {
    test('throws AuthException when no authenticated user', () {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(
        () => actions.requestAccountDeletion(currentPassword: 'pass'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'No authenticated user',
          ),
        ),
      );
    });

    test('throws AuthException when user has no email', () {
      final user = MockUser();
      when(() => user.email).thenReturn(null);
      when(() => user.id).thenReturn('user-id-123');
      when(() => mockAuth.currentUser).thenReturn(user);

      expect(
        () => actions.requestAccountDeletion(currentPassword: 'pass'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'No authenticated user',
          ),
        ),
      );
    });

    test('re-authenticates and calls RPC with user ID', () async {
      // Use _RpcTrackingClient to avoid mocktail Future-type issues with rpc()
      final rpcClient = _RpcTrackingClient(mockAuth);
      final rpcActions = AuthActions(rpcClient);

      final user = MockUser();
      when(() => user.email).thenReturn('user@test.com');
      when(() => user.id).thenReturn('user-id-123');
      when(() => mockAuth.currentUser).thenReturn(user);
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => AuthResponse());

      await rpcActions.requestAccountDeletion(currentPassword: 'myPass');

      verify(
        () => mockAuth.signInWithPassword(
          email: 'user@test.com',
          password: 'myPass',
        ),
      ).called(1);
      expect(rpcClient.rpcCalls, hasLength(1));
      expect(rpcClient.rpcCalls.first.fn, 'request_account_deletion');
      expect(rpcClient.rpcCalls.first.params, {'p_user_id': 'user-id-123'});
    });

    test('propagates error when re-authentication fails', () async {
      final rpcClient = _RpcTrackingClient(mockAuth);
      final rpcActions = AuthActions(rpcClient);

      final user = MockUser();
      when(() => user.email).thenReturn('user@test.com');
      when(() => user.id).thenReturn('user-id-123');
      when(() => mockAuth.currentUser).thenReturn(user);
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Invalid login credentials'));

      expect(
        () => rpcActions.requestAccountDeletion(currentPassword: 'wrong'),
        throwsA(isA<AuthException>()),
      );
      // RPC should never be called when re-auth fails
      expect(rpcClient.rpcCalls, isEmpty);
    });
  });
}
