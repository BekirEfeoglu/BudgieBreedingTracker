import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/screens/register_screen.dart';

import '../../../helpers/e2e_test_harness.dart';

void main() {
  late MockAuthActions mockAuth;
  late MockTwoFactorService mockTwoFactor;

  setUp(() {
    registerFallbackValue(OAuthProvider.google);

    mockAuth = MockAuthActions();
    when(
      () => mockAuth.signUpWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => AuthResponse());
    when(() => mockAuth.signInWithOAuth(any())).thenAnswer((_) async => true);

    mockTwoFactor = MockTwoFactorService();
    when(
      () => mockTwoFactor.needsVerification(),
    ).thenAnswer((_) async => false);
  });

  Widget createSubject() {
    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(
          path: '/email-verification',
          builder: (_, __) => const Scaffold(body: Text('EmailVerification')),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('Login')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authActionsProvider.overrideWithValue(mockAuth),
        twoFactorServiceProvider.overrideWithValue(mockTwoFactor),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('RegisterScreen', () {
    // RegisterScreen has repeating AnimationControllers and timers.
    // pumpAndSettle will never complete — use pump(Duration) instead.

    testWidgets('renders RegisterScreen widget without crashing', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('shows create_account title', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(l10n('auth.create_account')), findsOneWidget);
    });

    testWidgets('shows form with text fields', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('shows social login buttons', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(l10n('auth.sign_in_with_google')), findsOneWidget);
    });

    testWidgets('shows already_have_account text', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(l10n('auth.have_account')), findsOneWidget);
    });

    testWidgets('shows register submit button', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

      // FilledButton is the primary submit button
      expect(find.byType(FilledButton), findsAtLeastNWidgets(1));
    });

    testWidgets('does not call signUpWithEmail with empty form', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

      // Tap the register button without filling in fields
      final submitBtn = find.byType(FilledButton).first;
      await tester.tap(submitBtn);
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(
        () => mockAuth.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      );
    });

    testWidgets('shows age confirmation and consent checkboxes', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

      // Should find 2 checkboxes for age and consent
      expect(find.byType(Checkbox), findsNWidgets(2));
      expect(find.text(l10n('auth.age_confirm')), findsOneWidget);
      expect(find.text(l10n('auth.consent_checkbox')), findsOneWidget);
    });

    testWidgets('unchecked checkboxes block form submission', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

      // Fill in all text fields
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'Test123!@#');
      await tester.enterText(find.byType(TextFormField).at(3), 'Test123!@#');
      await tester.pump();

      // Scroll down to make submit button visible
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -400),
      );
      await tester.pump();

      // Submit without checking checkboxes
      final submitBtn = find.byType(FilledButton).first;
      await tester.tap(submitBtn, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      // Should not call signUp because checkboxes are unchecked
      verifyNever(
        () => mockAuth.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      );
    });
  });
}
