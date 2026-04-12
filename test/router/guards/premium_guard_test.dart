import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/router/guards/premium_guard.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

void main() {
  group('PremiumGuard.redirect', () {
    test('returns null for premium users', () {
      expect(PremiumGuard.redirect(true), isNull);
    });

    test('redirects to premium paywall for non-premium users', () {
      expect(PremiumGuard.redirect(false), AppRoutes.premium);
    });
  });
}
