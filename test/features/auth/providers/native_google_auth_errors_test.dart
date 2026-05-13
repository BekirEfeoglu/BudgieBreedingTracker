import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/native_google_auth_errors.dart';

void main() {
  group('shouldFallbackToBrowserGoogleOAuth', () {
    test('allows browser fallback for native Google failures', () {
      expect(
        shouldFallbackToBrowserGoogleOAuth(
          const AuthException(nativeGoogleSignInNotConfiguredMessage),
        ),
        isTrue,
      );
      expect(
        shouldFallbackToBrowserGoogleOAuth(
          const AuthException(nativeGoogleSignInFailedMessage),
        ),
        isTrue,
      );
      expect(
        shouldFallbackToBrowserGoogleOAuth(
          const AuthException(nativeGoogleNoIdTokenMessage),
        ),
        isTrue,
      );
      expect(
        shouldFallbackToBrowserGoogleOAuth(
          const AuthException(nativeGoogleNoAccessTokenMessage),
        ),
        isTrue,
      );
    });

    test('does not fallback for a user cancellation', () {
      expect(
        shouldFallbackToBrowserGoogleOAuth(const AuthException('Canceled')),
        isFalse,
      );
    });
  });

  group('shouldTreatNativeGoogleCancelAsUnavailable', () {
    test('treats Android native cancellation as unavailable', () {
      expect(
        shouldTreatNativeGoogleCancelAsUnavailable(
          isAndroid: true,
          description: null,
          details: null,
        ),
        isTrue,
      );
    });

    test('does not treat non-Android cancellation as unavailable', () {
      expect(
        shouldTreatNativeGoogleCancelAsUnavailable(
          isAndroid: false,
          description: 'The user canceled sign-in.',
          details: null,
        ),
        isFalse,
      );
    });
  });

  group('shouldUseNativeGoogleSignIn', () {
    test('skips native Google sign-in on Android', () {
      expect(shouldUseNativeGoogleSignIn(isAndroid: true), isFalse);
    });

    test('keeps native Google sign-in on non-Android platforms', () {
      expect(shouldUseNativeGoogleSignIn(isAndroid: false), isTrue);
    });
  });

  group('resolveOAuthLaunchMode', () {
    test('uses external application for Android browser OAuth', () {
      expect(
        resolveOAuthLaunchMode(isAndroid: true),
        LaunchMode.externalApplication,
      );
    });

    test('keeps in-app browser for non-Android browser OAuth', () {
      expect(
        resolveOAuthLaunchMode(isAndroid: false),
        LaunchMode.inAppBrowserView,
      );
    });
  });
}
