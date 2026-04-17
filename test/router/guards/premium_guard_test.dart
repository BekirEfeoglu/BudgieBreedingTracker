import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/router/guards/premium_guard.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

void main() {
  group('PremiumGuard.redirect', () {
    test('returns null when user has effective access (active premium)', () {
      expect(PremiumGuard.redirect(true), isNull);
    });

    test('returns null when user has effective access (grace period)', () {
      // Grace period users pass true via effectivePremiumProvider at the
      // call site; the guard itself only sees the derived boolean.
      expect(PremiumGuard.redirect(true), isNull);
    });

    test('redirects to premium paywall when access has fully expired', () {
      expect(PremiumGuard.redirect(false), AppRoutes.premium);
    });
  });
}
