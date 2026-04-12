import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/auth/widgets/auth_form_field.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/password_strength_meter.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/password_change_form.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('PasswordChangeForm', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PasswordChangeForm(
            onSubmit: ({
              required String currentPassword,
              required String newPassword,
            }) async {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PasswordChangeForm), findsOneWidget);
    });

    testWidgets('shows current password field', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PasswordChangeForm(
            onSubmit: ({
              required String currentPassword,
              required String newPassword,
            }) async {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text(l10n('profile.current_password')), findsOneWidget);
    });

    testWidgets('shows new password field', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PasswordChangeForm(
            onSubmit: ({
              required String currentPassword,
              required String newPassword,
            }) async {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text(l10n('profile.new_password')), findsOneWidget);
    });

    testWidgets('shows confirm password field', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PasswordChangeForm(
            onSubmit: ({
              required String currentPassword,
              required String newPassword,
            }) async {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text(l10n('profile.confirm_password')), findsOneWidget);
    });

    testWidgets('shows submit button with change password label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          PasswordChangeForm(
            onSubmit: ({
              required String currentPassword,
              required String newPassword,
            }) async {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text(l10n('profile.change_password')), findsOneWidget);
    });

    testWidgets('has three AuthFormField widgets', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PasswordChangeForm(
            onSubmit: ({
              required String currentPassword,
              required String newPassword,
            }) async {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AuthFormField), findsNWidgets(3));
    });

    testWidgets('validates empty current password', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PasswordChangeForm(
            onSubmit: ({
              required String currentPassword,
              required String newPassword,
            }) async {},
          ),
        ),
      );
      await tester.pump();

      // Tap the submit button without entering any text
      await tester.tap(find.text(l10n('profile.change_password')));
      await tester.pump();

      expect(
        find.text(l10n('profile.current_password_required')),
        findsOneWidget,
      );
    });

    testWidgets('validates empty new password', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PasswordChangeForm(
            onSubmit: ({
              required String currentPassword,
              required String newPassword,
            }) async {},
          ),
        ),
      );
      await tester.pump();

      // Enter current password but leave new password empty
      await tester.enterText(
        find.byType(TextFormField).first,
        'oldpassword',
      );
      await tester.tap(find.text(l10n('profile.change_password')));
      await tester.pump();

      expect(find.text(l10n('profile.new_password_required')), findsOneWidget);
    });

    testWidgets('validates new password minimum length', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PasswordChangeForm(
            onSubmit: ({
              required String currentPassword,
              required String newPassword,
            }) async {},
          ),
        ),
      );
      await tester.pump();

      // Enter current password and a short new password
      await tester.enterText(
        find.byType(TextFormField).first,
        'oldpassword',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'short');
      await tester.tap(find.text(l10n('profile.change_password')));
      await tester.pump();

      expect(find.text(l10n('auth.rule_min_length')), findsAtLeastNWidgets(1));
    });

    testWidgets('validates passwords do not match', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PasswordChangeForm(
            onSubmit: ({
              required String currentPassword,
              required String newPassword,
            }) async {},
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byType(TextFormField).first,
        'oldpassword',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'newpassword123',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'differentpassword',
      );
      await tester.tap(find.text(l10n('profile.change_password')));
      await tester.pump();

      expect(find.text(l10n('profile.passwords_not_match')), findsOneWidget);
    });

    testWidgets('validates empty confirm password', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PasswordChangeForm(
            onSubmit: ({
              required String currentPassword,
              required String newPassword,
            }) async {},
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byType(TextFormField).first,
        'oldpassword',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'newpassword123',
      );
      // Leave confirm password empty
      await tester.tap(find.text(l10n('profile.change_password')));
      await tester.pump();

      expect(
        find.text(l10n('profile.confirm_password_required')),
        findsOneWidget,
      );
    });

    testWidgets('calls onSubmit when form is valid', (tester) async {
      String? capturedCurrentPassword;
      String? capturedNewPassword;

      await tester.pumpWidget(
        _wrap(
          PasswordChangeForm(
            onSubmit: ({
              required String currentPassword,
              required String newPassword,
            }) async {
              capturedCurrentPassword = currentPassword;
              capturedNewPassword = newPassword;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byType(TextFormField).first,
        'oldpassword',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'newpassword123',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'newpassword123',
      );
      await tester.tap(find.text(l10n('profile.change_password')));
      await tester.pump();

      expect(capturedCurrentPassword, 'oldpassword');
      expect(capturedNewPassword, 'newpassword123');
    });

    testWidgets('shows password strength meter when new password entered', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          PasswordChangeForm(
            onSubmit: ({
              required String currentPassword,
              required String newPassword,
            }) async {},
          ),
        ),
      );
      await tester.pump();

      // Enter text in the new password field (second TextFormField)
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'StrongPass1!',
      );
      await tester.pump();

      expect(find.byType(PasswordStrengthMeter), findsOneWidget);
    });

    testWidgets('shows loading state on submit button', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PasswordChangeForm(
            isLoading: true,
            onSubmit: ({
              required String currentPassword,
              required String newPassword,
            }) async {},
          ),
        ),
      );
      await tester.pump();

      // PrimaryButton with isLoading shows a CircularProgressIndicator
      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
      );
    });

    testWidgets('wraps content in a Form widget', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PasswordChangeForm(
            onSubmit: ({
              required String currentPassword,
              required String newPassword,
            }) async {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Form), findsOneWidget);
    });
  });
}
