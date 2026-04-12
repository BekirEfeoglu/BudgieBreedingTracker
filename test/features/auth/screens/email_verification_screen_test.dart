import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/screens/email_verification_screen.dart';

import '../../../helpers/e2e_test_harness.dart';

void main() {
  late MockAuthActions mockAuth;

  setUp(() {
    mockAuth = MockAuthActions();
    when(
      () => mockAuth.resendVerification(any()),
    ).thenAnswer((_) async => ResendResponse());
  });

  Widget createSubject({String? email}) {
    final router = GoRouter(
      initialLocation: '/email-verification',
      routes: [
        GoRoute(
          path: '/email-verification',
          builder: (_, __) => EmailVerificationScreen(email: email),
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

  group('EmailVerificationScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(EmailVerificationScreen), findsOneWidget);
    });

    testWidgets('shows email_verification_title', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text(l10n('auth.email_verification_title')), findsOneWidget);
    });

    testWidgets('shows email_verification_desc', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text(l10n('auth.email_verification_desc')), findsOneWidget);
    });

    testWidgets('shows back_to_login button', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text(l10n('auth.back_to_login')), findsOneWidget);
    });

    testWidgets('shows provided email address', (tester) async {
      await tester.pumpWidget(createSubject(email: 'test@example.com'));
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('shows resend_email button when email is provided', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(email: 'test@example.com'));
      await tester.pump();

      expect(find.text(l10n('auth.resend_email')), findsOneWidget);
    });

    testWidgets('does not show resend button when no email', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text(l10n('auth.resend_email')), findsNothing);
    });

    testWidgets('shows mail icon', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(Icon), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping back_to_login navigates to login screen', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      await tester.tap(find.text(l10n('auth.back_to_login')));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('calls resendVerification on resend button tap', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(email: 'test@example.com'));
      await tester.pump();

      await tester.tap(find.text(l10n('auth.resend_email')));
      await tester.pump();

      verify(() => mockAuth.resendVerification('test@example.com')).called(1);
    });
  });
}
