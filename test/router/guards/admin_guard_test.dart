import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/router/guards/admin_guard.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

void main() {
  group('AdminGuard.redirect', () {
    test('allows navigation while loading', () {
      expect(AdminGuard.redirect(const AsyncLoading()), isNull);
    });

    test('redirects to home on error', () {
      final redirect = AdminGuard.redirect(
        AsyncError(Exception('x'), StackTrace.current),
      );
      expect(redirect, AppRoutes.home);
    });

    test('redirects to home when user is not admin', () {
      expect(AdminGuard.redirect(const AsyncData(false)), AppRoutes.home);
    });

    test('allows admin user', () {
      expect(AdminGuard.redirect(const AsyncData(true)), isNull);
    });
  });
}
