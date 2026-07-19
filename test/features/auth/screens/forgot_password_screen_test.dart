import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/screens/forgot_password_screen.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import '../../../helpers/e2e_test_harness.dart';

class _TestPasswordRecoveryNotifier extends PasswordRecoveryPendingNotifier {
  _TestPasswordRecoveryNotifier(this.initialValue);

  final bool initialValue;

  @override
  bool build() => initialValue;
}

void main() {
  late MockAuthActions mockAuth;

  setUp(() {
    mockAuth = MockAuthActions();
    when(() => mockAuth.resetPassword(any())).thenAnswer((_) async {});
    when(() => mockAuth.updatePasswordAfterRecovery(any())).thenAnswer(
      (_) async => UserResponse.fromJson({
        'id': 'u1',
        'email': 'user@example.com',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'aud': 'authenticated',
        'created_at': '2026-07-18T00:00:00Z',
      }),
    );
  });

  Widget createSubject({String? initialEmail, bool recoveryPending = false}) {
    final router = GoRouter(
      initialLocation: '/forgot-password',
      routes: [
        GoRoute(
          path: '/forgot-password',
          builder: (_, __) => ForgotPasswordScreen(initialEmail: initialEmail),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('Login')),
        ),
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authActionsProvider.overrideWithValue(mockAuth),
        passwordRecoveryPendingProvider.overrideWith(
          () => _TestPasswordRecoveryNotifier(recoveryPending),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('ForgotPasswordScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('prefills email received from verification flow', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(initialEmail: 'test@example.com'));
      await tester.pump();

      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller?.text, 'test@example.com');
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

    testWidgets('shows new-password form for a recovery session', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(recoveryPending: true));
      await tester.pump();

      expect(find.text(l10n('auth.update_password_title')), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text(l10n('auth.email')), findsNothing);
    });

    testWidgets('updates password and completes the recovery flow', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(recoveryPending: true));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).at(0), 'NewSecure123!');
      await tester.enterText(find.byType(TextFormField).at(1), 'NewSecure123!');
      await tester.tap(find.text(l10n('auth.update_password_action')));
      await tester.pumpAndSettle();

      verify(
        () => mockAuth.updatePasswordAfterRecovery('NewSecure123!'),
      ).called(1);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('does not update when confirmation does not match', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(recoveryPending: true));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).at(0), 'NewSecure123!');
      await tester.enterText(find.byType(TextFormField).at(1), 'Different123!');
      await tester.tap(find.text(l10n('auth.update_password_action')));
      await tester.pump();

      verifyNever(() => mockAuth.updatePasswordAfterRecovery(any()));
      expect(find.text(l10n('common.password_mismatch')), findsOneWidget);
    });
  });
}
