import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/native_google_auth_errors.dart';

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
    registerFallbackValue(LaunchMode.inAppBrowserView);
  });

  // Revocation goes through an injected callback rather than
  // `client.functions.invoke` so `features/` does not import `data/remote/`
  // and so the call picks up EdgeFunctionClient's stale-token refresh + 401
  // retry. These record what the mixin would send.
  late List<Map<String, String?>> revokeCalls;
  Object? revokeThrows;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockFunctions = MockFunctionsClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockClient.functions).thenReturn(mockFunctions);
    revokeCalls = [];
    revokeThrows = null;
    actions = AuthActions(
      mockClient,
      revokeOAuthToken:
          ({
            required String provider,
            String? providerToken,
            String? providerRefreshToken,
          }) async {
            revokeCalls.add({
              'provider': provider,
              if (providerToken != null) 'provider_token': providerToken,
              if (providerRefreshToken != null)
                'provider_refresh_token': providerRefreshToken,
            });
            final failure = revokeThrows;
            if (failure != null) throw failure;
          },
    );
  });

  group('_AuthOAuthMixin.revokeOAuthToken', () {
    test('does nothing when no session exists', () async {
      when(() => mockAuth.currentSession).thenReturn(null);

      await actions.revokeOAuthToken();

      verifyNever(() => mockClient.functions);
    });

    test('does nothing when no provider tokens in session', () async {
      final session = MockSession();
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.providerToken).thenReturn(null);
      when(() => session.providerRefreshToken).thenReturn(null);

      await actions.revokeOAuthToken();

      verifyNever(() => mockFunctions.invoke(any(), body: any(named: 'body')));
    });

    test('does nothing when provider is not google or apple', () async {
      final session = MockSession();
      final user = MockUser();
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.providerToken).thenReturn('token123');
      when(() => session.providerRefreshToken).thenReturn(null);
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.appMetadata).thenReturn({'provider': 'email'});

      await actions.revokeOAuthToken();

      verifyNever(() => mockFunctions.invoke(any(), body: any(named: 'body')));
    });

    test('invokes edge function for google provider', () async {
      final session = MockSession();
      final user = MockUser();
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.providerToken).thenReturn('google-token');
      when(() => session.providerRefreshToken).thenReturn('google-refresh');
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.appMetadata).thenReturn({'provider': 'google'});
      await actions.revokeOAuthToken();

      expect(revokeCalls, [
        {
          'provider': 'google',
          'provider_token': 'google-token',
          'provider_refresh_token': 'google-refresh',
        },
      ]);
    });

    test('invokes edge function for apple provider', () async {
      final session = MockSession();
      final user = MockUser();
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.providerToken).thenReturn('apple-token');
      when(() => session.providerRefreshToken).thenReturn(null);
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.appMetadata).thenReturn({'provider': 'apple'});
      await actions.revokeOAuthToken();

      expect(revokeCalls, [
        {'provider': 'apple', 'provider_token': 'apple-token'},
      ]);
    });

    test('includes only non-null tokens in request body', () async {
      final session = MockSession();
      final user = MockUser();
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.providerToken).thenReturn(null);
      when(() => session.providerRefreshToken).thenReturn('refresh-only');
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.appMetadata).thenReturn({'provider': 'google'});
      await actions.revokeOAuthToken();

      expect(revokeCalls, [
        {'provider': 'google', 'provider_refresh_token': 'refresh-only'},
      ]);
    });

    test('silently handles edge function errors', () async {
      final session = MockSession();
      final user = MockUser();
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.providerToken).thenReturn('token');
      when(() => session.providerRefreshToken).thenReturn(null);
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.appMetadata).thenReturn({'provider': 'google'});
      revokeThrows = Exception('Edge function unavailable');

      // Should NOT throw — errors are caught and logged
      await actions.revokeOAuthToken();

      expect(revokeCalls, hasLength(1));
    });

    test('does nothing when provider is null in metadata', () async {
      final session = MockSession();
      final user = MockUser();
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.providerToken).thenReturn('token');
      when(() => session.providerRefreshToken).thenReturn(null);
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.appMetadata).thenReturn(<String, dynamic>{});

      await actions.revokeOAuthToken();

      verifyNever(() => mockFunctions.invoke(any(), body: any(named: 'body')));
    });

    test(
      'does not crash when provider is a non-string (malformed payload)',
      () async {
        // Regression: `appMetadata['provider'] as String?` would throw a
        // TypeError if the server returned an int/bool/list. Safe cast must
        // fall through to the no-op branch instead.
        final session = MockSession();
        final user = MockUser();
        when(() => mockAuth.currentSession).thenReturn(session);
        when(() => session.providerToken).thenReturn('token');
        when(() => session.providerRefreshToken).thenReturn(null);
        when(() => mockAuth.currentUser).thenReturn(user);
        when(
          () => user.appMetadata,
        ).thenReturn(<String, dynamic>{'provider': 42});

        await actions.revokeOAuthToken();

        verifyNever(
          () => mockFunctions.invoke(any(), body: any(named: 'body')),
        );
      },
    );

    test('does not crash when provider is a nested object', () async {
      final session = MockSession();
      final user = MockUser();
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.providerToken).thenReturn('token');
      when(() => session.providerRefreshToken).thenReturn(null);
      when(() => mockAuth.currentUser).thenReturn(user);
      when(() => user.appMetadata).thenReturn(<String, dynamic>{
        'provider': {'name': 'google'},
      });

      await actions.revokeOAuthToken();

      verifyNever(() => mockFunctions.invoke(any(), body: any(named: 'body')));
    });

    test('treats empty-string provider as missing', () async {
      final session = MockSession();
      final user = MockUser();
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.providerToken).thenReturn('token');
      when(() => session.providerRefreshToken).thenReturn(null);
      when(() => mockAuth.currentUser).thenReturn(user);
      when(
        () => user.appMetadata,
      ).thenReturn(<String, dynamic>{'provider': '   '});

      await actions.revokeOAuthToken();

      verifyNever(() => mockFunctions.invoke(any(), body: any(named: 'body')));
    });
  });

  group('_AuthOAuthMixin.signInWithOAuth', () {
    test('uses Android external browser and non-Android in-app browser', () {
      expect(
        resolveOAuthLaunchMode(isAndroid: true),
        LaunchMode.externalApplication,
      );
      expect(
        resolveOAuthLaunchMode(isAndroid: false),
        AuthActions.oAuthLaunchMode,
      );
    });
  });
}
