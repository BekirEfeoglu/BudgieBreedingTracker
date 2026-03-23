import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

import '../../../helpers/mocks.dart';

class MockSession extends Mock implements Session {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockFunctionsClient mockFunctions;
  late AuthActions actions;

  setUpAll(() {
    registerFallbackValue(OAuthProvider.google);
    registerFallbackValue(LaunchMode.externalApplication);
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockFunctions = MockFunctionsClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockClient.functions).thenReturn(mockFunctions);
    actions = AuthActions(mockClient);
  });

  group('_AuthOAuthMixin.revokeOAuthToken', () {
    test('does nothing when no session exists', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      await expectLater(actions.revokeOAuthToken(), completes);

      verifyNever(() => mockClient.functions);
    });

    test('does nothing when no provider tokens in session', () async {
      final session = MockSession();
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.providerToken).thenReturn(null);
      when(() => session.providerRefreshToken).thenReturn(null);

      await expectLater(actions.revokeOAuthToken(), completes);

      verifyNever(
        () => mockFunctions.invoke(any(), body: any(named: 'body')),
      );
    });

    test('does nothing when provider is not google or apple', () async {
      final session = MockSession();
      final user = MockUser();
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.providerToken).thenReturn('token123');
      when(() => session.providerRefreshToken).thenReturn(null);
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.appMetadata).thenReturn({'provider': 'email'});

      await expectLater(actions.revokeOAuthToken(), completes);

      verifyNever(
        () => mockFunctions.invoke(any(), body: any(named: 'body')),
      );
    });

    test('invokes edge function for google provider', () async {
      final session = MockSession();
      final user = MockUser();
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.providerToken).thenReturn('google-token');
      when(() => session.providerRefreshToken).thenReturn('google-refresh');
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.appMetadata).thenReturn({'provider': 'google'});
      when(
        () => mockFunctions.invoke(any(), body: any(named: 'body')),
      ).thenAnswer((_) async => FunctionResponse(status: 200, data: {}));

      await actions.revokeOAuthToken();

      verify(
        () => mockFunctions.invoke(
          'revoke-oauth-token',
          body: {
            'provider': 'google',
            'provider_token': 'google-token',
            'provider_refresh_token': 'google-refresh',
          },
        ),
      ).called(1);
    });

    test('invokes edge function for apple provider', () async {
      final session = MockSession();
      final user = MockUser();
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.providerToken).thenReturn('apple-token');
      when(() => session.providerRefreshToken).thenReturn(null);
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.appMetadata).thenReturn({'provider': 'apple'});
      when(
        () => mockFunctions.invoke(any(), body: any(named: 'body')),
      ).thenAnswer((_) async => FunctionResponse(status: 200, data: {}));

      await actions.revokeOAuthToken();

      verify(
        () => mockFunctions.invoke(
          'revoke-oauth-token',
          body: {
            'provider': 'apple',
            'provider_token': 'apple-token',
          },
        ),
      ).called(1);
    });

    test('includes only non-null tokens in request body', () async {
      final session = MockSession();
      final user = MockUser();
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.providerToken).thenReturn(null);
      when(() => session.providerRefreshToken).thenReturn('refresh-only');
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.appMetadata).thenReturn({'provider': 'google'});
      when(
        () => mockFunctions.invoke(any(), body: any(named: 'body')),
      ).thenAnswer((_) async => FunctionResponse(status: 200, data: {}));

      await actions.revokeOAuthToken();

      verify(
        () => mockFunctions.invoke(
          'revoke-oauth-token',
          body: {
            'provider': 'google',
            'provider_refresh_token': 'refresh-only',
          },
        ),
      ).called(1);
    });

    test('silently handles edge function errors', () async {
      final session = MockSession();
      final user = MockUser();
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.providerToken).thenReturn('token');
      when(() => session.providerRefreshToken).thenReturn(null);
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.appMetadata).thenReturn({'provider': 'google'});
      when(
        () => mockFunctions.invoke(any(), body: any(named: 'body')),
      ).thenThrow(Exception('Edge function unavailable'));

      // Should NOT throw — errors are caught and logged
      await expectLater(actions.revokeOAuthToken(), completes);
    });

    test('does nothing when provider is null in metadata', () async {
      final session = MockSession();
      final user = MockUser();
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.providerToken).thenReturn('token');
      when(() => session.providerRefreshToken).thenReturn(null);
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.appMetadata).thenReturn(<String, dynamic>{});

      await expectLater(actions.revokeOAuthToken(), completes);

      verifyNever(
        () => mockFunctions.invoke(any(), body: any(named: 'body')),
      );
    });
  });
}
