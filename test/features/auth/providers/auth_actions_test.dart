import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

// -- Mocks --

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockSession extends Mock implements Session {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late AuthActions actions;

  setUpAll(() {
    registerFallbackValue(OAuthProvider.google);
    registerFallbackValue(OtpType.signup);
    registerFallbackValue(UserAttributes());
    registerFallbackValue(SignOutScope.local);
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    actions = AuthActions(mockClient);
  });

  group('AuthActions.signInWithEmail', () {
    test('delegates to client.auth.signInWithPassword', () async {
      final response = AuthResponse();
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => response);

      final result = await actions.signInWithEmail(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, same(response));
      verify(
        () => mockAuth.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test('propagates AuthException from Supabase', () {
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Invalid login credentials'));

      expect(
        () => actions.signInWithEmail(
          email: 'bad@example.com',
          password: 'wrong',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthActions.signUpWithEmail', () {
    test('delegates to client.auth.signUp', () async {
      final response = AuthResponse();
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      final result = await actions.signUpWithEmail(
        email: 'new@example.com',
        password: 'pass1234',
        data: {'display_name': 'Test User'},
      );

      expect(result, same(response));
    });

    test('passes null data when not provided', () async {
      final response = AuthResponse();
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => response);

      await actions.signUpWithEmail(
        email: 'user@example.com',
        password: 'secure1234',
      );

      verify(
        () => mockAuth.signUp(
          email: 'user@example.com',
          password: 'secure1234',
          emailRedirectTo: any(named: 'emailRedirectTo'),
          data: null,
        ),
      ).called(1);
    });
  });

  group('AuthActions.resetPassword', () {
    test('calls client.auth.resetPasswordForEmail', () async {
      when(
        () => mockAuth.resetPasswordForEmail(
          any(),
          redirectTo: any(named: 'redirectTo'),
        ),
      ).thenAnswer((_) async {});

      await actions.resetPassword('user@example.com');

      verify(
        () => mockAuth.resetPasswordForEmail(
          'user@example.com',
          redirectTo: any(named: 'redirectTo'),
        ),
      ).called(1);
    });
  });

  group('AuthActions.resendVerification', () {
    test('calls client.auth.resend with signup OTP type', () async {
      final resendResponse = ResendResponse();
      when(
        () => mockAuth.resend(
          type: any(named: 'type'),
          email: any(named: 'email'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
        ),
      ).thenAnswer((_) async => resendResponse);

      final result = await actions.resendVerification('user@example.com');

      expect(result, same(resendResponse));
      verify(
        () => mockAuth.resend(
          type: OtpType.signup,
          email: 'user@example.com',
          emailRedirectTo: any(named: 'emailRedirectTo'),
        ),
      ).called(1);
    });
  });

  group('AuthActions.signOut', () {
    test('calls client.auth.signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await actions.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });
  });

  group('AuthActions.signOutAllSessions', () {
    test('calls signOut with global scope', () async {
      when(
        () => mockAuth.signOut(scope: any(named: 'scope')),
      ).thenAnswer((_) async {});

      await actions.signOutAllSessions();

      verify(() => mockAuth.signOut(scope: SignOutScope.global)).called(1);
    });
  });

  group('AuthActions.changePassword', () {
    test('throws AuthException when no authenticated user', () {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(
        () =>
            actions.changePassword(currentPassword: 'old', newPassword: 'new'),
        throwsA(isA<AuthException>()),
      );
    });

    test('re-authenticates then updates password', () async {
      final user = MockUser();
      when(() => user.email).thenReturn('user@example.com');
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
          'email': 'user@example.com',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': '2024-01-01T00:00:00Z',
        }),
      );

      await actions.changePassword(
        currentPassword: 'current123',
        newPassword: 'newSecure456',
      );

      // Re-authentication happens first
      verify(
        () => mockAuth.signInWithPassword(
          email: 'user@example.com',
          password: 'current123',
        ),
      ).called(1);

      // Then password update
      verify(() => mockAuth.updateUser(any())).called(1);
    });
  });

  group('AuthActions.revokeOAuthToken', () {
    test('does nothing when no session exists', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      // Should return without calling anything else
      await expectLater(actions.revokeOAuthToken(), completes);

      verifyNever(() => mockClient.functions);
    });

    test('does nothing when no provider token in session', () async {
      final session = MockSession();
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.providerToken).thenReturn(null);
      when(() => session.providerRefreshToken).thenReturn(null);

      await expectLater(actions.revokeOAuthToken(), completes);
    });
  });

  group('AuthActions.requestAccountDeletion', () {
    test('throws AuthException when no authenticated user', () {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(
        () => actions.requestAccountDeletion(),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('authActionsProvider', () {
    test('returns an AuthActions instance', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(mockClient),
          supabaseInitializedProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(authActionsProvider), isA<AuthActions>());
    });
  });

  group('InitStep enum', () {
    test('has profile, services, ready values', () {
      expect(
        InitStep.values,
        containsAll([InitStep.profile, InitStep.services, InitStep.ready]),
      );
    });
  });

  group('initStepProvider', () {
    test('initial state is InitStep.profile', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(initStepProvider), InitStep.profile);
    });

    test('can be updated to services', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(initStepProvider.notifier).state = InitStep.services;
      expect(container.read(initStepProvider), InitStep.services);
    });

    test('can be updated to ready', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(initStepProvider.notifier).state = InitStep.ready;
      expect(container.read(initStepProvider), InitStep.ready);
    });
  });

  group('initSkippedProvider', () {
    test('initial state is false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(initSkippedProvider), isFalse);
    });

    test('can be set to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(initSkippedProvider.notifier).state = true;
      expect(container.read(initSkippedProvider), isTrue);
    });
  });
}
