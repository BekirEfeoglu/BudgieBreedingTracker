import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/screens/forgot_password_screen.dart';

import '../../../helpers/e2e_test_harness.dart';

void main() {
  late MockAuthActions mockAuth;

  setUp(() {
    mockAuth = MockAuthActions();
    when(() => mockAuth.resetPassword(any())).thenAnswer((_) async {});
  });

  Widget createSubject() {
    final router = GoRouter(
      initialLocation: '/forgot-password',
      routes: [
        GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('Login')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [authActionsProvider.overrideWithValue(mockAuth)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('ForgotPasswordScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('shows AppBar', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows email text field', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows submit button', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(
        find.byWidgetPredicate((w) => w is FilledButton || w is ElevatedButton),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows form widget', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('validates empty email on submit', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      // Tap submit without entering email
      final submitButton = find.byWidgetPredicate(
        (w) => w is FilledButton || w is ElevatedButton,
      );
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.first);
        await tester.pumpAndSettle();
      }

      // Validation error should appear (no API call made)
      verifyNever(() => mockAuth.resetPassword(any()));
    });
  });
}
