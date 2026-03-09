import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/screens/two_factor_verify_screen.dart';

import '../../../helpers/e2e_test_harness.dart';

void main() {
  late MockTwoFactorService mockTwoFactor;

  setUp(() {
    mockTwoFactor = MockTwoFactorService();
    when(
      () => mockTwoFactor.challengeAndVerify(
        factorId: any(named: 'factorId'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async => false);
  });

  Widget createSubject({String factorId = 'test-factor-id'}) {
    final router = GoRouter(
      initialLocation: '/2fa-verify',
      routes: [
        GoRoute(
          path: '/2fa-verify',
          builder: (_, __) => TwoFactorVerifyScreen(factorId: factorId),
        ),
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [twoFactorServiceProvider.overrideWithValue(mockTwoFactor)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('TwoFactorVerifyScreen', () {
    testWidgets('renders TwoFactorVerifyScreen without crashing', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(TwoFactorVerifyScreen), findsOneWidget);
    });

    testWidgets('shows AppBar with 2fa_verify title', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('auth.2fa_verify'), findsOneWidget);
    });

    testWidgets('shows 2fa_verify_title heading', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('auth.2fa_verify_title'), findsOneWidget);
    });

    testWidgets('shows 2fa_verify_desc text', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('auth.2fa_verify_desc'), findsOneWidget);
    });

    testWidgets('shows 2fa_verify_hint text', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('auth.2fa_verify_hint'), findsOneWidget);
    });

    testWidgets('shows two_factor icon', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      // AppIcon widget renders the SVG icon
      expect(
        find.byType(Icon).evaluate().isNotEmpty ||
            find
                .byWidgetPredicate(
                  (w) => w.runtimeType.toString().contains('AppIcon'),
                )
                .evaluate()
                .isNotEmpty,
        isTrue,
      );
    });

    testWidgets('does not show loading or error initially', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      // No loading indicator at start (before any OTP entered)
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
