import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/screens/two_factor_setup_screen.dart';

import '../../../helpers/e2e_test_harness.dart';

void main() {
  late MockTwoFactorService mockTwoFactor;

  // Minimal valid SVG string for QR code
  const fakeSvg =
      '<svg xmlns="http://www.w3.org/2000/svg">'
      '<rect width="100" height="100" fill="black"/>'
      '</svg>';

  setUp(() {
    mockTwoFactor = MockTwoFactorService();
    when(() => mockTwoFactor.enroll()).thenAnswer(
      (_) async => (
        factorId: 'test-factor-id',
        totpUri: 'otpauth://totp/BudgieBreedingTracker:test@example.com',
        secret: 'TESTSECRETKEY1234',
        qrCode: fakeSvg,
      ),
    );
    when(
      () => mockTwoFactor.verifyEnrollment(
        factorId: any(named: 'factorId'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async => false);
  });

  Widget createSubject() {
    final router = GoRouter(
      initialLocation: '/2fa-setup',
      routes: [
        GoRoute(
          path: '/2fa-setup',
          builder: (_, __) => const TwoFactorSetupScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const Scaffold(body: Text('Profile')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [twoFactorServiceProvider.overrideWithValue(mockTwoFactor)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('TwoFactorSetupScreen', () {
    testWidgets('renders TwoFactorSetupScreen without crashing', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(TwoFactorSetupScreen), findsOneWidget);
    });

    testWidgets('shows AppBar with 2fa_setup title', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('auth.2fa_setup'), findsOneWidget);
    });

    testWidgets('shows loading indicator while enrolling', (tester) async {
      // Use Completer to control when enroll() resolves
      final completer =
          Completer<
            ({String factorId, String totpUri, String secret, String qrCode})
          >();
      when(() => mockTwoFactor.enroll()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createSubject());
      await tester.pump(); // first frame — completer not yet complete

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

      // Complete to avoid pending future warning
      completer.complete((
        factorId: 'test-factor-id',
        totpUri: 'otpauth://totp/test',
        secret: 'TESTSECRETKEY1234',
        qrCode: fakeSvg,
      ));
      await tester.pump();
    });

    testWidgets('shows setup view after enrollment completes', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump(); // start loading
      await tester.pump(const Duration(milliseconds: 100)); // enroll() resolves

      // After enrollment, the scan QR label should appear
      expect(find.text('auth.2fa_scan_qr'), findsOneWidget);
    });

    testWidgets('shows secret key after enrollment', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('TESTSECRETKEY1234'), findsOneWidget);
    });

    testWidgets('shows manual key label after enrollment', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('auth.2fa_manual_key'), findsOneWidget);
    });

    testWidgets('shows enter code prompt', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('auth.2fa_enter_code'), findsOneWidget);
    });

    testWidgets('shows error view and retry button when enrollment fails', (
      tester,
    ) async {
      when(
        () => mockTwoFactor.enroll(),
      ).thenAnswer((_) async => throw Exception('enroll failed'));

      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('auth.2fa_enrollment_error'), findsOneWidget);
      expect(find.text('auth.2fa_retry'), findsOneWidget);
    });
  });
}
