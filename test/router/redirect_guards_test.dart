import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/router/redirect_guards.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

void main() {
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
