import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/router/guards/founder_guard.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

void main() {
  group('FounderGuard.redirect', () {
    test('redirects to splash while loading', () {
      expect(FounderGuard.redirect(const AsyncLoading()), AppRoutes.splash);
    });

    test('redirects to home on error', () {
      final redirect = FounderGuard.redirect(
        AsyncError(Exception('cannot verify founder'), StackTrace.current),
      );
      expect(redirect, AppRoutes.home);
    });

    test('redirects to home when user is not a founder', () {
      expect(FounderGuard.redirect(const AsyncData(false)), AppRoutes.home);
    });

    test('allows founder user (returns null)', () {
      expect(FounderGuard.redirect(const AsyncData(true)), isNull);
    });
  });
}
