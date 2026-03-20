import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/screens/budgie_login_screen.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/budgie_login_card.dart';

import '../../../helpers/e2e_test_harness.dart';

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

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const BudgieLoginScreen()),
        GoRoute(
          path: '/register',
          builder: (_, __) => const Scaffold(body: Text('Register')),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const Scaffold(body: Text('ForgotPassword')),
        ),
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
  }

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        authActionsProvider.overrideWithValue(mockAuth),
        twoFactorServiceProvider.overrideWithValue(mockTwoFactor),
        supabaseInitializedProvider.overrideWithValue(true),
      ],
      child: MaterialApp.router(routerConfig: buildRouter()),
    );
  }

  group('BudgieLoginScreen', () {
    // Note: BudgieLoginScreen has repeating AnimationControllers and
    // periodic timers, so pumpAndSettle will never complete.
    // Use pump() with a duration instead to let the widget tree build.

    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(BudgieLoginScreen), findsOneWidget);
    });

    testWidgets('shows BudgieLoginCard', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(BudgieLoginCard), findsOneWidget);
    });

    testWidgets('shows form with text fields', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('shows register navigation text', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // EasyLocalization returns key directly in test context
      expect(find.text('auth.no_account'), findsOneWidget);
      expect(find.text('auth.register'), findsOneWidget);
    });

    testWidgets('shows login button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('shows validation error on empty email submit', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      // Tap login button without filling fields
      final loginBtn = find.byType(FilledButton);
      await tester.tap(loginBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // Validation errors should appear (key returned without translation)
      expect(find.text('common.required_field'), findsWidgets);

      // signInWithEmail should NOT be called
      verifyNever(
        () => mockAuth.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets('calls signInWithEmail on valid form submit', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      // Fill in email and password fields
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'test@example.com');
      await tester.enterText(textFields.last, 'password123');
      await tester.pump(const Duration(milliseconds: 100));

      // Tap login button
      final loginBtn = find.byType(FilledButton);
      await tester.tap(loginBtn);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify signInWithEmail was called with correct parameters
      verify(
        () => mockAuth.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);

      // Advance timers to let the post-login Future.delayed(1200ms) fire
      // and navigate to home.
      await tester.pump(const Duration(seconds: 2));
      // Pump extra frames to ensure GoRouter navigation rebuild completes
      // and BudgieLoginScreen is fully disposed before blink timers fire.
      await tester.pump();
      await tester.pump();
      // Advance past the maximum blink timer delay (3-5s from pumpWidget).
      // Widget is now disposed so mounted==false; blink timers return early
      // without creating 200ms inner timers.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('shows social login buttons', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      // Google uses OutlinedButton, Apple uses official SignInWithAppleButton
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(SignInWithAppleButton), findsOneWidget);
      // Verify Google label (key returned in test context)
      expect(find.text('auth.sign_in_with_google'), findsOneWidget);
      // Note: SignInWithAppleButton renders its own internal label,
      // not our localized 'auth.sign_in_with_apple' text.
    });

    testWidgets('calls signInWithGoogle on Google button tap', (tester) async {
      when(
        () => mockAuth.signInWithGoogle(),
      ).thenAnswer((_) async => AuthResponse());

      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      final googleBtn = find.byType(OutlinedButton);
      await tester.ensureVisible(googleBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(googleBtn);
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockAuth.signInWithGoogle()).called(1);

      // Advance past success delay + blink timers to dispose cleanly
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('calls signInWithApple on Apple button tap', (tester) async {
      when(
        () => mockAuth.signInWithApple(),
      ).thenAnswer((_) async => AuthResponse());

      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      final appleBtn = find.byType(SignInWithAppleButton);
      await tester.ensureVisible(appleBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(appleBtn);
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockAuth.signInWithApple()).called(1);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('calls signInAnonymously on guest button tap', (tester) async {
      when(
        () => mockAuth.signInAnonymously(),
      ).thenAnswer((_) async => AuthResponse());

      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      final guestBtn = find.text('auth.continue_as_guest');
      await tester.ensureVisible(guestBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(guestBtn);
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockAuth.signInAnonymously()).called(1);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('falls back to browser OAuth when native Google fails', (
      tester,
    ) async {
      when(() => mockAuth.signInWithGoogle()).thenThrow(
        const AuthException('Google sign-in not configured', statusCode: '400'),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      final googleBtn = find.byType(OutlinedButton);
      await tester.ensureVisible(googleBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(googleBtn);
      await tester.pump(const Duration(milliseconds: 500));

      // Native failed → browser OAuth should be attempted
      verify(() => mockAuth.signInWithGoogle()).called(1);
      verify(() => mockAuth.signInWithOAuth(OAuthProvider.google)).called(1);

      await tester.pump(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Google OAuth cancel resets to idle', (tester) async {
      when(
        () => mockAuth.signInWithGoogle(),
      ).thenThrow(const AuthException('Canceled'));

      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      final googleBtn = find.byType(OutlinedButton);
      await tester.ensureVisible(googleBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(googleBtn);
      await tester.pump(const Duration(milliseconds: 500));

      // Canceled should not show error and should NOT fall back to browser
      expect(find.text('auth.login'), findsOneWidget);
      verifyNever(() => mockAuth.signInWithOAuth(any()));

      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('guest login error shows snackbar', (tester) async {
      when(
        () => mockAuth.signInAnonymously(),
      ).thenThrow(const AuthException('Anonymous sign-ins are disabled'));

      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));

      final guestBtn = find.text('auth.continue_as_guest');
      await tester.ensureVisible(guestBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(guestBtn);
      await tester.pump(const Duration(milliseconds: 500));

      // Error snackbar should appear
      expect(find.byType(SnackBar), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
