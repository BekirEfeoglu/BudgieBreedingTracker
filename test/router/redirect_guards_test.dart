import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';
import 'package:budgie_breeding_tracker/router/redirect_guards.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

class _TestSessionLockedNotifier extends SessionLockedNotifier {
  @override
  bool build() => false;
}

class _TestPasswordRecoveryNotifier extends PasswordRecoveryPendingNotifier {
  @override
  bool build() => true;
}

class _TestPasswordRecoveryFalseNotifier
    extends PasswordRecoveryPendingNotifier {
  @override
  bool build() => false;
}

class _TestPendingMfaNullNotifier extends PendingMfaFactorIdNotifier {
  @override
  String? build() => null;
}

class _TestPendingMfaNotifier extends PendingMfaFactorIdNotifier {
  @override
  String? build() => '141aa2f1-2db4-4fb0-a381-b4e14e65063b';
}

void main() {
  group('post-auth destination redirects', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(false),
          sessionLockedProvider.overrideWith(_TestSessionLockedNotifier.new),
          passwordRecoveryPendingProvider.overrideWith(
            _TestPasswordRecoveryFalseNotifier.new,
          ),
          pendingMfaFactorIdProvider.overrideWith(
            _TestPendingMfaNullNotifier.new,
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('preserves a protected deep link when redirecting to login', () {
      final redirectProvider = Provider<String?>((ref) {
        return authRedirect(
          ref,
          AppRoutes.birds,
          requestedLocation: '/birds/123?tab=health',
        );
      });

      final redirect = container.read(redirectProvider);
      expect(redirect, startsWith('${AppRoutes.login}?'));
      expect(
        Uri.parse(redirect!).queryParameters['returnTo'],
        '/birds/123?tab=health',
      );
    });

    test('does not preserve an external returnTo value', () {
      final redirectProvider = Provider<String?>((ref) {
        return authRedirect(
          ref,
          AppRoutes.birds,
          requestedLocation: 'https://evil.example/phish',
        );
      });

      expect(container.read(redirectProvider), AppRoutes.login);
    });

    test('authenticated login route restores its validated destination', () {
      final authenticated = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(true),
          sessionLockedProvider.overrideWith(_TestSessionLockedNotifier.new),
          passwordRecoveryPendingProvider.overrideWith(
            _TestPasswordRecoveryFalseNotifier.new,
          ),
          pendingMfaFactorIdProvider.overrideWith(
            _TestPendingMfaNullNotifier.new,
          ),
        ],
      );
      addTearDown(authenticated.dispose);
      final redirectProvider = Provider<String?>((ref) {
        return authRedirect(
          ref,
          AppRoutes.login,
          requestedLocation: '/login?returnTo=%2Fsettings',
        );
      });

      expect(authenticated.read(redirectProvider), AppRoutes.settings);
    });

    test('MFA redirect carries the original destination', () {
      final authenticated = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(true),
          passwordRecoveryPendingProvider.overrideWith(
            _TestPasswordRecoveryFalseNotifier.new,
          ),
          pendingMfaFactorIdProvider.overrideWith(_TestPendingMfaNotifier.new),
        ],
      );
      addTearDown(authenticated.dispose);
      final redirectProvider = Provider<String?>((ref) {
        return twoFactorRedirect(
          ref,
          AppRoutes.login,
          requestedLocation: '/login?returnTo=%2Fsettings',
        );
      });

      final redirect = authenticated.read(redirectProvider);
      expect(Uri.parse(redirect!).path, AppRoutes.twoFactorVerify);
      expect(
        Uri.parse(redirect).queryParameters['returnTo'],
        AppRoutes.settings,
      );
    });
  });

  group('password recovery redirects', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(true),
          sessionLockedProvider.overrideWith(_TestSessionLockedNotifier.new),
          passwordRecoveryPendingProvider.overrideWith(
            _TestPasswordRecoveryNotifier.new,
          ),
          pendingMfaFactorIdProvider.overrideWith(_TestPendingMfaNotifier.new),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('forces an authenticated recovery session onto the reset form', () {
      final redirectProvider = Provider<String?>(
        (ref) => authRedirect(ref, AppRoutes.home),
      );

      expect(container.read(redirectProvider), AppRoutes.forgotPassword);
    });

    test('allows the recovery session to remain on the reset form', () {
      final redirectProvider = Provider<String?>(
        (ref) => authRedirect(ref, AppRoutes.forgotPassword),
      );

      expect(container.read(redirectProvider), isNull);
    });

    test('does not let MFA routing interrupt password recovery', () {
      final redirectProvider = Provider<String?>(
        (ref) => twoFactorRedirect(ref, AppRoutes.forgotPassword),
      );

      expect(container.read(redirectProvider), isNull);
    });
  });

  group('isAnonymousAllowedRoute', () {
    test('allows the user guide index for guests', () {
      expect(isAnonymousAllowedRoute(AppRoutes.userGuide), isTrue);
    });

    test('allows a user guide topic detail sub-route for guests', () {
      expect(isAnonymousAllowedRoute('${AppRoutes.userGuide}/0'), isTrue);
      expect(isAnonymousAllowedRoute('${AppRoutes.userGuide}/12'), isTrue);
    });

    test('allows premium, legal, and maintenance routes for guests', () {
      expect(isAnonymousAllowedRoute(AppRoutes.premium), isTrue);
      expect(isAnonymousAllowedRoute(AppRoutes.maintenance), isTrue);
      expect(isAnonymousAllowedRoute(AppRoutes.privacyPolicy), isTrue);
      expect(isAnonymousAllowedRoute(AppRoutes.termsOfService), isTrue);
      expect(isAnonymousAllowedRoute(AppRoutes.communityGuidelines), isTrue);
    });

    test('does not allow unrelated authenticated routes for guests', () {
      expect(isAnonymousAllowedRoute('/birds'), isFalse);
      expect(isAnonymousAllowedRoute('/settings'), isFalse);
      // A route that merely starts with the same prefix but isn't actually
      // a guide sub-route must not slip through.
      expect(isAnonymousAllowedRoute('/user-guide-unrelated'), isFalse);
    });
  });
}
