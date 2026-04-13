import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/screens/budgie_login_screen.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/auth_form_field.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/budgie_login_card.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/legal_links_text.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/social_login_buttons.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthActions mockAuth;
  late MockTwoFactorService mockTwoFactor;

  setUp(() {
    registerFallbackValue(OAuthProvider.google);

    mockAuth = MockAuthActions();
    when(
      () => mockAuth.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => AuthResponse());
    when(() => mockAuth.signInWithOAuth(any())).thenAnswer((_) async => true);

    mockTwoFactor = MockTwoFactorService();
    when(
      () => mockTwoFactor.needsVerification(),
    ).thenAnswer((_) async => false);
    when(() => mockTwoFactor.getFactors()).thenAnswer((_) async => []);
  });

  GoRouter buildRouter({String? initialLocation}) {
    return GoRouter(
      initialLocation: initialLocation ?? '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const BudgieLoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (_, __) => const Scaffold(body: Text('RegisterScreen')),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const Scaffold(body: Text('ForgotPasswordScreen')),
        ),
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/auth/2fa/verify',
          builder: (_, __) => const Scaffold(body: Text('2FAVerify')),
        ),
      ],
    );
  }

  Widget buildSubject({GoRouter? router}) {
    return ProviderScope(
      overrides: [
        authActionsProvider.overrideWithValue(mockAuth),
        twoFactorServiceProvider.overrideWithValue(mockTwoFactor),
        supabaseInitializedProvider.overrideWithValue(true),
      ],
      child: MaterialApp.router(routerConfig: router ?? buildRouter()),
    );
  }

  // Helper to pump and let initial animations run without pumpAndSettle
  // (repeating animations prevent pumpAndSettle from completing).
  Future<void> pumpLogin(WidgetTester tester, {GoRouter? router}) async {
    await tester.pumpWidget(buildSubject(router: router));
    await tester.pump(const Duration(milliseconds: 500));
  }

  // Helper to dispose cleanly — advances past blink/peek timers.
  Future<void> disposeCleanly(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  group('BudgieLoginScreen — rendering', () {
    testWidgets('renders Scaffold with BudgieLoginCard', (tester) async {
      await pumpLogin(tester);
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(BudgieLoginCard), findsOneWidget);
      await disposeCleanly(tester);
    });

    testWidgets('renders two AuthFormField widgets (email and password)',
        (tester) async {
      await pumpLogin(tester);
      expect(find.byType(AuthFormField), findsNWidgets(2));
      await disposeCleanly(tester);
    });

    testWidgets('renders email field with correct label', (tester) async {
      await pumpLogin(tester);
      expect(find.text(l10n('auth.email')), findsOneWidget);
      await disposeCleanly(tester);
    });

    testWidgets('renders password field with correct label', (tester) async {
      await pumpLogin(tester);
      expect(find.text(l10n('auth.password')), findsOneWidget);
      await disposeCleanly(tester);
    });

    testWidgets('renders forgot password button', (tester) async {
      await pumpLogin(tester);
      expect(find.text(l10n('auth.forgot_password')), findsOneWidget);
      await disposeCleanly(tester);
    });

    testWidgets('renders guest login button and hint', (tester) async {
      await pumpLogin(tester);
      expect(find.text(l10n('auth.continue_as_guest')), findsOneWidget);
      expect(find.text(l10n('auth.guest_limitation_hint')), findsOneWidget);
      await disposeCleanly(tester);
    });

    testWidgets('renders social login buttons section', (tester) async {
      await pumpLogin(tester);
      expect(find.byType(SocialLoginButtons), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget); // Google
      expect(find.byType(SignInWithAppleButton), findsOneWidget); // Apple
      await disposeCleanly(tester);
    });

    testWidgets('renders legal links', (tester) async {
      await pumpLogin(tester);
      expect(find.byType(LegalLinksText), findsOneWidget);
      await disposeCleanly(tester);
    });

    testWidgets('renders welcome title in idle state', (tester) async {
      await pumpLogin(tester);
      expect(find.text(l10n('auth.welcome_back')), findsOneWidget);
      await disposeCleanly(tester);
    });
  });

  group('BudgieLoginScreen — form validation', () {
    testWidgets('shows required field error for empty email', (tester) async {
      await pumpLogin(tester);

      // Enter only password, leave email empty
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.last, 'password123');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(l10n('common.required_field')), findsOneWidget);
      verifyNever(
        () => mockAuth.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
      await disposeCleanly(tester);
    });

    testWidgets('shows invalid email error for malformed email',
        (tester) async {
      await pumpLogin(tester);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'not-an-email');
      await tester.enterText(textFields.last, 'password123');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(l10n('common.email_invalid')), findsOneWidget);
      verifyNever(
        () => mockAuth.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
      await disposeCleanly(tester);
    });

    testWidgets('shows required field error for empty password',
        (tester) async {
      await pumpLogin(tester);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(l10n('common.required_field')), findsOneWidget);
      verifyNever(
        () => mockAuth.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
      await disposeCleanly(tester);
    });

    testWidgets('shows password too short error for < 8 chars',
        (tester) async {
      await pumpLogin(tester);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.enterText(textFields.last, 'short');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(l10n('common.password_short')), findsOneWidget);
      verifyNever(
        () => mockAuth.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
      await disposeCleanly(tester);
    });

    testWidgets('accepts valid email and password without validation errors',
        (tester) async {
      await pumpLogin(tester);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'user@example.com');
      await tester.enterText(textFields.last, 'securePass1');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 300));

      // No validation error texts visible
      expect(find.text(l10n('common.required_field')), findsNothing);
      expect(find.text(l10n('common.email_invalid')), findsNothing);
      expect(find.text(l10n('common.password_short')), findsNothing);

      verify(
        () => mockAuth.signInWithEmail(
          email: 'user@example.com',
          password: 'securePass1',
        ),
      ).called(1);

      // Clean up post-login timers
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('BudgieLoginScreen — loading state', () {
    // Helper to enter credentials and trigger loading state.
    // Uses a Completer so we control when signIn completes.
    Future<Completer<AuthResponse>> triggerLoading(WidgetTester tester) async {
      final completer = Completer<AuthResponse>();
      when(
        () => mockAuth.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) => completer.future);

      await pumpLogin(tester);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.enterText(textFields.last, 'password123');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 300));

      return completer;
    }

    testWidgets('shows CircularProgressIndicator during login', (tester) async {
      final completer = await triggerLoading(tester);

      // Loading indicator should be visible inside the FilledButton
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Title should change to logging_in
      expect(find.text(l10n('auth.logging_in')), findsOneWidget);

      // Complete to avoid pending timer errors
      completer.completeError(
        const AuthException('test cancel', statusCode: '499'),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 4));
      await disposeCleanly(tester);
    });

    testWidgets('login button is disabled during loading state',
        (tester) async {
      final completer = await triggerLoading(tester);

      final filledButton =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(filledButton.onPressed, isNull);

      completer.completeError(
        const AuthException('test cancel', statusCode: '499'),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 4));
      await disposeCleanly(tester);
    });

    testWidgets('register button is disabled during loading', (tester) async {
      final completer = await triggerLoading(tester);

      final registerBtn = find.widgetWithText(
        TextButton,
        l10n('auth.register'),
      );
      expect(registerBtn, findsOneWidget);
      final registerWidget = tester.widget<TextButton>(registerBtn);
      expect(registerWidget.onPressed, isNull);

      completer.completeError(
        const AuthException('test cancel', statusCode: '499'),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 4));
      await disposeCleanly(tester);
    });

    testWidgets('guest button is disabled during loading', (tester) async {
      final completer = await triggerLoading(tester);

      final guestBtn = find.widgetWithText(
        TextButton,
        l10n('auth.continue_as_guest'),
      );
      expect(guestBtn, findsOneWidget);
      final guestWidget = tester.widget<TextButton>(guestBtn);
      expect(guestWidget.onPressed, isNull);

      completer.completeError(
        const AuthException('test cancel', statusCode: '499'),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 4));
      await disposeCleanly(tester);
    });
  });

  group('BudgieLoginScreen — navigation', () {
    testWidgets('tapping register navigates to register screen',
        (tester) async {
      final router = buildRouter();
      await pumpLogin(tester, router: router);

      final registerBtn = find.widgetWithText(
        TextButton,
        l10n('auth.register'),
      );
      await tester.ensureVisible(registerBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(registerBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      // After navigation, register screen should be visible
      expect(find.text('RegisterScreen'), findsOneWidget);

      await disposeCleanly(tester);
    });

    testWidgets('tapping forgot password navigates to forgot password screen',
        (tester) async {
      final router = buildRouter();
      await pumpLogin(tester, router: router);

      final forgotBtn = find.widgetWithText(
        TextButton,
        l10n('auth.forgot_password'),
      );
      await tester.ensureVisible(forgotBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(forgotBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('ForgotPasswordScreen'), findsOneWidget);

      await disposeCleanly(tester);
    });
  });

  group('BudgieLoginScreen — password visibility', () {
    testWidgets('password field is obscured by default', (tester) async {
      await pumpLogin(tester);

      // The password EditableText should have obscureText = true
      // eyeOff icon indicates the field is currently obscured
      expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);

      // Find the password EditableText (the one with obscureText)
      final editableTexts = find.byType(EditableText);
      final passwordEditable =
          tester.widget<EditableText>(editableTexts.last);
      expect(passwordEditable.obscureText, isTrue);

      await disposeCleanly(tester);
    });

    testWidgets('tapping eye icon toggles password visibility',
        (tester) async {
      await pumpLogin(tester);

      // Initially obscured — eyeOff icon should be visible
      expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);

      // Tap the visibility toggle
      await tester.tap(find.byIcon(LucideIcons.eyeOff));
      await tester.pump(const Duration(milliseconds: 100));

      // Now eye icon (not eyeOff) should be visible
      expect(find.byIcon(LucideIcons.eye), findsOneWidget);
      expect(find.byIcon(LucideIcons.eyeOff), findsNothing);

      // The password EditableText should no longer be obscured
      final editableTexts = find.byType(EditableText);
      final passwordEditable =
          tester.widget<EditableText>(editableTexts.last);
      expect(passwordEditable.obscureText, isFalse);

      await disposeCleanly(tester);
    });
  });

  group('BudgieLoginScreen — error handling', () {
    testWidgets('network error shows error snackbar', (tester) async {
      when(
        () => mockAuth.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const SocketException('Connection refused'));

      await pumpLogin(tester);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.enterText(textFields.last, 'password123');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 300)); // AnimatedSwitcher

      // Should show error snackbar
      expect(find.byType(SnackBar), findsOneWidget);

      // Wait for error reset timer (3s) + extra
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 500));

      await disposeCleanly(tester);
    });

    testWidgets('auth error shows error snackbar', (tester) async {
      when(
        () => mockAuth.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const AuthException('Invalid login credentials', statusCode: '400'),
      );

      await pumpLogin(tester);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.enterText(textFields.last, 'wrongpass1');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 500));

      // Error snackbar should be visible
      expect(find.byType(SnackBar), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 500));
      await disposeCleanly(tester);
    });

    testWidgets('error state resets login button text after 3 seconds',
        (tester) async {
      when(
        () => mockAuth.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const AuthException('Bad request', statusCode: '400'),
      );

      await pumpLogin(tester);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.enterText(textFields.last, 'password123');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 500));

      // In error state — login button text should still be visible
      // (error state shows same label text in FilledButton)
      expect(find.byType(SnackBar), findsOneWidget);

      // After 3 seconds error reset timer fires, state returns to idle
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));

      // Login button should show label text again (idle state)
      expect(find.text(l10n('auth.login')), findsOneWidget);

      await disposeCleanly(tester);
    });
  });

  group('BudgieLoginScreen — field input', () {
    testWidgets('email field accepts text input', (tester) async {
      await pumpLogin(tester);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'hello@world.com');
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('hello@world.com'), findsOneWidget);

      await disposeCleanly(tester);
    });

    testWidgets('password field accepts text input', (tester) async {
      await pumpLogin(tester);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.last, 'mypassword');
      await tester.pump(const Duration(milliseconds: 100));

      // Password text exists in the editing controller even though obscured
      final editableTexts = find.byType(EditableText);
      final passwordEditable =
          tester.widget<EditableText>(editableTexts.last);
      expect(passwordEditable.controller.text, 'mypassword');

      await disposeCleanly(tester);
    });

    testWidgets('email field trims whitespace before submission',
        (tester) async {
      await pumpLogin(tester);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, '  user@test.com  ');
      await tester.enterText(textFields.last, 'password123');
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 500));

      verify(
        () => mockAuth.signInWithEmail(
          email: 'user@test.com',
          password: 'password123',
        ),
      ).called(1);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
