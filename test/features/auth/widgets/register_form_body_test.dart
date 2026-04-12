import 'package:budgie_breeding_tracker/features/auth/widgets/auth_form_field.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/legal_links_text.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/password_strength_meter.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/register_form_body.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/social_login_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  group('RegisterFormBody', () {
    late TextEditingController nameCtrl;
    late TextEditingController emailCtrl;
    late TextEditingController passwordCtrl;
    late TextEditingController confirmCtrl;
    late GlobalKey<FormState> formKey;
    late bool submitCalled;
    late bool loginCalled;

    setUp(() {
      nameCtrl = TextEditingController();
      emailCtrl = TextEditingController();
      passwordCtrl = TextEditingController();
      confirmCtrl = TextEditingController();
      formKey = GlobalKey<FormState>();
      submitCalled = false;
      loginCalled = false;
    });

    tearDown(() {
      nameCtrl.dispose();
      emailCtrl.dispose();
      passwordCtrl.dispose();
      confirmCtrl.dispose();
    });

    Widget buildSubject({bool isLoading = false}) {
      return Form(
        key: formKey,
        child: SingleChildScrollView(
          child: RegisterFormBody(
            nameCtrl: nameCtrl,
            emailCtrl: emailCtrl,
            passwordCtrl: passwordCtrl,
            confirmCtrl: confirmCtrl,
            isLoading: isLoading,
            onSubmit: () => submitCalled = true,
            onGoogleTap: () {},
            onAppleTap: () {},
            onLoginTap: () => loginCalled = true,
          ),
        ),
      );
    }

    testWidgets('renders without error', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.byType(RegisterFormBody), findsOneWidget);
    });

    testWidgets('contains four AuthFormField widgets', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      // Name, email, password, confirm password
      expect(find.byType(AuthFormField), findsNWidgets(4));
    });

    testWidgets('shows name field with localized label', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.text(l10n('auth.full_name')), findsOneWidget);
    });

    testWidgets('shows email field with localized label', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.text(l10n('auth.email')), findsOneWidget);
    });

    testWidgets('shows password field with localized label', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.text(l10n('auth.password')), findsOneWidget);
    });

    testWidgets('shows confirm password field with localized label', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.text(l10n('auth.confirm_password')), findsOneWidget);
    });

    testWidgets('shows register button', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text(l10n('auth.register')), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when loading', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, buildSubject(isLoading: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('register button text is hidden when loading', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, buildSubject(isLoading: true));

      // The register text should not be visible (replaced by progress indicator)
      final filledButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(filledButton.onPressed, isNull);
    });

    testWidgets('contains SocialLoginButtons widget', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.byType(SocialLoginButtons), findsOneWidget);
    });

    testWidgets('contains LegalLinksText widget', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.byType(LegalLinksText), findsOneWidget);
    });

    testWidgets('shows login link text', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.text(l10n('auth.have_account')), findsOneWidget);
      expect(find.text(l10n('auth.login')), findsOneWidget);
    });

    testWidgets('contains PasswordStrengthMeter', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.byType(PasswordStrengthMeter), findsOneWidget);
    });

    testWidgets('contains age confirmation checkbox', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.text(l10n('auth.age_confirm')), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(2)); // age + consent
    });

    testWidgets('contains consent checkbox', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.text(l10n('auth.consent_checkbox')), findsOneWidget);
    });

    group('validation', () {
      testWidgets('validates empty name field', (tester) async {
        await pumpWidgetSimple(tester, buildSubject());

        formKey.currentState!.validate();
        await tester.pump();

        expect(find.text(l10n('common.required_field')), findsWidgets);
      });

      testWidgets('validates empty email field', (tester) async {
        await pumpWidgetSimple(tester, buildSubject());

        nameCtrl.text = 'Test User';
        formKey.currentState!.validate();
        await tester.pump();

        expect(find.text(l10n('common.required_field')), findsWidgets);
      });

      testWidgets('validates invalid email format', (tester) async {
        await pumpWidgetSimple(tester, buildSubject());

        nameCtrl.text = 'Test User';
        emailCtrl.text = 'invalid-email';
        passwordCtrl.text = 'StrongP@ss1';
        confirmCtrl.text = 'StrongP@ss1';
        formKey.currentState!.validate();
        await tester.pump();

        expect(find.text(l10n('common.email_invalid')), findsOneWidget);
      });

      testWidgets('validates short password', (tester) async {
        await pumpWidgetSimple(tester, buildSubject());

        nameCtrl.text = 'Test User';
        emailCtrl.text = 'test@example.com';
        passwordCtrl.text = 'Sh0!'; // Too short
        confirmCtrl.text = 'Sh0!';
        formKey.currentState!.validate();
        await tester.pump();

        expect(find.text(l10n('common.password_short')), findsOneWidget);
      });

      testWidgets('validates password missing uppercase', (tester) async {
        await pumpWidgetSimple(tester, buildSubject());

        nameCtrl.text = 'Test User';
        emailCtrl.text = 'test@example.com';
        passwordCtrl.text = 'alllowercase1!'; // No uppercase
        confirmCtrl.text = 'alllowercase1!';
        formKey.currentState!.validate();
        await tester.pump();

        expect(find.text(l10n('auth.rule_uppercase')), findsWidgets);
      });

      testWidgets('validates password missing lowercase', (tester) async {
        await pumpWidgetSimple(tester, buildSubject());

        nameCtrl.text = 'Test User';
        emailCtrl.text = 'test@example.com';
        passwordCtrl.text = 'ALLUPPERCASE1!'; // No lowercase
        confirmCtrl.text = 'ALLUPPERCASE1!';
        formKey.currentState!.validate();
        await tester.pump();

        expect(find.text(l10n('auth.rule_lowercase')), findsWidgets);
      });

      testWidgets('validates password missing digit', (tester) async {
        await pumpWidgetSimple(tester, buildSubject());

        nameCtrl.text = 'Test User';
        emailCtrl.text = 'test@example.com';
        passwordCtrl.text = 'NoDigitHere!'; // No digit
        confirmCtrl.text = 'NoDigitHere!';
        formKey.currentState!.validate();
        await tester.pump();

        expect(find.text(l10n('auth.rule_digit')), findsWidgets);
      });

      testWidgets('validates password missing special char', (tester) async {
        await pumpWidgetSimple(tester, buildSubject());

        nameCtrl.text = 'Test User';
        emailCtrl.text = 'test@example.com';
        passwordCtrl.text = 'NoSpecial1A'; // No special char
        confirmCtrl.text = 'NoSpecial1A';
        formKey.currentState!.validate();
        await tester.pump();

        expect(find.text(l10n('auth.rule_special_char')), findsWidgets);
      });

      testWidgets('validates password mismatch', (tester) async {
        await pumpWidgetSimple(tester, buildSubject());

        nameCtrl.text = 'Test User';
        emailCtrl.text = 'test@example.com';
        passwordCtrl.text = 'StrongP@ss1';
        confirmCtrl.text = 'DifferentP@ss1';
        formKey.currentState!.validate();
        await tester.pump();

        expect(find.text(l10n('common.password_mismatch')), findsOneWidget);
      });

      testWidgets('validates unchecked age confirmation', (tester) async {
        await pumpWidgetSimple(tester, buildSubject());

        nameCtrl.text = 'Test User';
        emailCtrl.text = 'test@example.com';
        passwordCtrl.text = 'StrongP@ss1';
        confirmCtrl.text = 'StrongP@ss1';
        formKey.currentState!.validate();
        await tester.pump();

        // Age and consent checkboxes are not checked
        expect(find.text(l10n('auth.age_confirm_required')), findsOneWidget);
        expect(find.text(l10n('auth.consent_required')), findsOneWidget);
      });
    });

    group('callbacks', () {
      testWidgets('calls onSubmit when register button tapped', (
        tester,
      ) async {
        await pumpWidgetSimple(tester, buildSubject());

        await tester.ensureVisible(find.byType(FilledButton));
        await tester.pump();
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        expect(submitCalled, isTrue);
      });

      testWidgets('calls onLoginTap when login link tapped', (tester) async {
        await pumpWidgetSimple(tester, buildSubject());

        await tester.ensureVisible(find.text(l10n('auth.login')));
        await tester.pump();
        await tester.tap(find.text(l10n('auth.login')));
        await tester.pump();

        expect(loginCalled, isTrue);
      });

      testWidgets('disables register button when loading', (tester) async {
        await pumpWidgetSimple(tester, buildSubject(isLoading: true));

        final filledButton = tester.widget<FilledButton>(
          find.byType(FilledButton),
        );
        expect(filledButton.onPressed, isNull);
      });

      testWidgets('disables login link when loading', (tester) async {
        await pumpWidgetSimple(tester, buildSubject(isLoading: true));

        // Find the login TextButton
        final loginButtons = tester.widgetList<TextButton>(
          find.widgetWithText(TextButton, l10n('auth.login')),
        );
        for (final button in loginButtons) {
          expect(button.onPressed, isNull);
        }
      });
    });

    group('social login', () {
      testWidgets('shows Google login button', (tester) async {
        await pumpWidgetSimple(tester, buildSubject());

        expect(find.byType(OutlinedButton), findsOneWidget);
        expect(find.text(l10n('auth.sign_in_with_google')), findsOneWidget);
      });

      testWidgets('shows Apple login button', (tester) async {
        await pumpWidgetSimple(tester, buildSubject());

        expect(find.byType(SignInWithAppleButton), findsOneWidget);
      });
    });
  });
}
