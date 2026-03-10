@Tags(['e2e'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/screens/email_verification_screen.dart';
import 'package:budgie_breeding_tracker/features/auth/screens/forgot_password_screen.dart';
import 'package:budgie_breeding_tracker/features/auth/screens/budgie_login_screen.dart';
import 'package:budgie_breeding_tracker/features/auth/screens/register_screen.dart';
import 'package:budgie_breeding_tracker/features/auth/screens/two_factor_verify_screen.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/otp_input_field.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

import '../helpers/e2e_test_harness.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  ensureE2EBinding();

  group('Auth Flow E2E', () {
    testWidgets(
      'GIVEN first launch and unauthenticated WHEN register succeeds THEN email verification is shown and signUp called once',
      (tester) async {
        final mockAuthActions = MockAuthActions();
        when(
          () => mockAuthActions.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => AuthResponse());
        when(
          () => mockAuthActions.signInWithOAuth(any()),
        ).thenAnswer((_) async => true);

        final container = createTestContainer(
          isAuthenticated: false,
          authActions: mockAuthActions,
        );
        addTearDown(container.dispose);

        final router = buildTestNavigator(
          initialLocation: AppRoutes.register,
          routes: [
            GoRoute(
              path: AppRoutes.register,
              builder: (_, __) => const RegisterScreen(),
            ),
            GoRoute(
              path: AppRoutes.emailVerification,
              builder: (_, state) => EmailVerificationScreen(
                email: state.uri.queryParameters['email'],
              ),
            ),
          ],
        );

        await pumpApp(tester, container, router: router);

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Test Kullanici');
        await tester.enterText(fields.at(1), 'test@example.com');
        await tester.enterText(fields.at(2), 'Test1234!');
        await tester.enterText(fields.at(3), 'Test1234!');

        await _tapVisible(
          tester,
          find.widgetWithText(FilledButton, 'auth.register'),
        );
        await tester.pump(const Duration(milliseconds: 900));

        expect(router.state.uri.path, AppRoutes.emailVerification);
        expect(find.byType(EmailVerificationScreen), findsWidgets);
        expect(find.text('auth.email_verification_title'), findsOneWidget);
        verify(
          () => mockAuthActions.signUpWithEmail(
            email: 'test@example.com',
            password: 'Test1234!',
            data: any(named: 'data'),
          ),
        ).called(1);
      },
      timeout: e2eTimeout,
    );

    testWidgets(
      'GIVEN register screen WHEN password is weak THEN validation error is shown and signUp is not called',
      (tester) async {
        final mockAuthActions = MockAuthActions();
        when(
          () => mockAuthActions.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async => AuthResponse());
        when(
          () => mockAuthActions.signInWithOAuth(any()),
        ).thenAnswer((_) async => true);

        final container = createTestContainer(
          isAuthenticated: false,
          authActions: mockAuthActions,
        );
        addTearDown(container.dispose);

        final router = buildTestNavigator(
          initialLocation: AppRoutes.register,
          routes: [
            GoRoute(
              path: AppRoutes.register,
              builder: (_, __) => const RegisterScreen(),
            ),
          ],
        );

        await pumpApp(tester, container, router: router);

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Test Kullanici');
        await tester.enterText(fields.at(1), 'test@example.com');
        await tester.enterText(fields.at(2), '123');
        await tester.enterText(fields.at(3), '123');

        await _tapVisible(
          tester,
          find.widgetWithText(FilledButton, 'auth.register'),
        );

        expect(find.text('common.password_short'), findsOneWidget);
        verifyNever(
          () => mockAuthActions.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          ),
        );
      },
      timeout: e2eTimeout,
    );

    testWidgets(
      'GIVEN verified account WHEN login with email/password succeeds THEN home and bottom navigation are visible',
      (tester) async {
        final mockAuthActions = MockAuthActions();
        when(
          () => mockAuthActions.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => AuthResponse());
        when(
          () => mockAuthActions.signInWithOAuth(any()),
        ).thenAnswer((_) async => true);

        final container = createTestContainer(
          isAuthenticated: false,
          authActions: mockAuthActions,
        );
        addTearDown(container.dispose);

        final router = buildTestNavigator(
          initialLocation: AppRoutes.login,
          routes: [
            GoRoute(
              path: AppRoutes.login,
              builder: (_, __) => const BudgieLoginScreen(),
            ),
            GoRoute(
              path: AppRoutes.home,
              builder: (_, __) => const _FakeHomeAfterLogin(),
            ),
          ],
        );

        await pumpApp(tester, container, router: router);

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'test@example.com');
        await tester.enterText(fields.at(1), 'Test1234!');

        await _tapVisible(
          tester,
          find.widgetWithText(FilledButton, 'auth.login'),
        );
        await tester.pump(const Duration(milliseconds: 1400));
        await tester.pumpAndSettle();

        expect(find.byType(_FakeHomeAfterLogin), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.destinations.length, 6);
        expect(find.text('profile_loaded'), findsOneWidget);
      },
      timeout: e2eTimeout,
    );

    testWidgets(
      'GIVEN login screen WHEN credentials are invalid THEN error is shown and user stays on login',
      (tester) async {
        final mockAuthActions = MockAuthActions();
        when(
          () => mockAuthActions.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthException('Invalid login credentials'));
        when(
          () => mockAuthActions.signInWithOAuth(any()),
        ).thenAnswer((_) async => true);

        final container = createTestContainer(
          isAuthenticated: false,
          authActions: mockAuthActions,
        );
        addTearDown(container.dispose);

        final router = buildTestNavigator(
          initialLocation: AppRoutes.login,
          routes: [
            GoRoute(
              path: AppRoutes.login,
              builder: (_, __) => const BudgieLoginScreen(),
            ),
          ],
        );

        await pumpApp(tester, container, router: router);

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'test@example.com');
        await tester.enterText(fields.at(1), 'wrong-pass');

        await _tapVisible(
          tester,
          find.widgetWithText(FilledButton, 'auth.login'),
        );

        expect(find.byType(BudgieLoginScreen), findsOneWidget);
        expect(find.text('auth.error_invalid_credentials'), findsOneWidget);
      },
      timeout: e2eTimeout,
    );

    testWidgets(
      'GIVEN login screen WHEN forgot-password flow is completed THEN success state is shown and resetPassword is called',
      (tester) async {
        final mockAuthActions = MockAuthActions();
        when(
          () => mockAuthActions.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => AuthResponse());
        when(
          () => mockAuthActions.signInWithOAuth(any()),
        ).thenAnswer((_) async => true);
        when(
          () => mockAuthActions.resetPassword(any()),
        ).thenAnswer((_) async {});

        final container = createTestContainer(
          isAuthenticated: false,
          authActions: mockAuthActions,
        );
        addTearDown(container.dispose);

        final router = buildTestNavigator(
          initialLocation: AppRoutes.login,
          routes: [
            GoRoute(
              path: AppRoutes.login,
              builder: (_, __) => const BudgieLoginScreen(),
            ),
            GoRoute(
              path: AppRoutes.forgotPassword,
              builder: (_, __) => const ForgotPasswordScreen(),
            ),
          ],
        );

        await pumpApp(tester, container, router: router);

        await _tapVisible(
          tester,
          find.widgetWithText(TextButton, 'auth.forgot_password'),
        );
        await tester.pump(const Duration(milliseconds: 700));

        expect(router.state.uri.path, AppRoutes.forgotPassword);
        expect(find.byType(ForgotPasswordScreen), findsWidgets);

        final forgotEmailField = find.descendant(
          of: find.byType(ForgotPasswordScreen),
          matching: find.byType(TextFormField),
        );
        await tester.enterText(forgotEmailField.first, 'test@example.com');
        await _tapVisible(
          tester,
          find.widgetWithText(FilledButton, 'auth.reset_password'),
        );

        verify(
          () => mockAuthActions.resetPassword('test@example.com'),
        ).called(1);
        expect(forgotEmailField, findsNothing);
      },
      timeout: e2eTimeout,
    );

    testWidgets(
      'GIVEN account with 2FA WHEN valid 6-digit code is entered THEN user is redirected to home',
      (tester) async {
        final mockTwoFactorService = MockTwoFactorService();
        when(
          () => mockTwoFactorService.challengeAndVerify(
            factorId: any(named: 'factorId'),
            code: any(named: 'code'),
          ),
        ).thenAnswer((_) async => true);

        final container = createTestContainer(
          isAuthenticated: true,
          twoFactorService: mockTwoFactorService,
        );
        addTearDown(container.dispose);

        final router = buildTestNavigator(
          initialLocation: AppRoutes.twoFactorVerify,
          routes: [
            GoRoute(
              path: AppRoutes.twoFactorVerify,
              builder: (_, __) =>
                  const TwoFactorVerifyScreen(factorId: 'factor-1'),
            ),
            GoRoute(
              path: AppRoutes.home,
              builder: (_, __) => const _FakeHomeAfterLogin(),
            ),
          ],
        );

        await pumpApp(tester, container, router: router);

        final otpInput = tester.widget<OtpInputField>(
          find.byType(OtpInputField),
        );
        otpInput.onCompleted('123456');
        await tester.pump(const Duration(milliseconds: 300));

        verify(
          () => mockTwoFactorService.challengeAndVerify(
            factorId: 'factor-1',
            code: '123456',
          ),
        ).called(1);
        await tester.pump(const Duration(milliseconds: 150));
        expect(router.state.uri.path, AppRoutes.home);
        expect(find.byType(_FakeHomeAfterLogin), findsOneWidget);
      },
      timeout: e2eTimeout,
    );

    testWidgets(
      'GIVEN authenticated user on home WHEN logout completes THEN login route is opened and signOut is called',
      (tester) async {
        final mockAuthActions = MockAuthActions();
        when(() => mockAuthActions.signOut()).thenAnswer((_) async {});

        final container = createTestContainer(
          isAuthenticated: true,
          authActions: mockAuthActions,
        );
        addTearDown(container.dispose);

        final router = buildTestNavigator(
          initialLocation: AppRoutes.home,
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, __) =>
                  _FakeLogoutScreen(authActions: mockAuthActions),
            ),
            GoRoute(
              path: AppRoutes.login,
              builder: (_, __) => const BudgieLoginScreen(),
            ),
          ],
        );

        await pumpApp(tester, container, router: router);

        await _tapVisible(tester, find.widgetWithText(FilledButton, 'logout'));
        await tester.pump(const Duration(milliseconds: 700));

        expect(router.state.uri.path, AppRoutes.login);
        expect(find.byType(BudgieLoginScreen), findsWidgets);
        verify(() => mockAuthActions.signOut()).called(1);
      },
      timeout: e2eTimeout,
    );
  });
}

class _FakeHomeAfterLogin extends StatelessWidget {
  const _FakeHomeAfterLogin();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('profile_loaded')),
      bottomNavigationBar: NavigationBar(
        destinations: List.generate(
          6,
          (index) => NavigationDestination(
            icon: const Icon(Icons.circle),
            label: 'tab_$index',
          ),
        ),
      ),
    );
  }
}

class _FakeLogoutScreen extends StatelessWidget {
  const _FakeLogoutScreen({required this.authActions});

  final AuthActions authActions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () async {
            await authActions.signOut();
            if (context.mounted) {
              context.go(AppRoutes.login);
            }
          },
          child: const Text('logout'),
        ),
      ),
    );
  }
}
