import 'package:budgie_breeding_tracker/features/auth/screens/budgie_login_screen.dart'
    show LoginState;
import 'package:budgie_breeding_tracker/features/auth/widgets/auth_form_field.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/budgie_login_card.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/legal_links_text.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/social_login_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  group('BudgieLoginCard', () {
    late GlobalKey<FormState> formKey;
    late TextEditingController emailController;
    late TextEditingController passwordController;
    late FocusNode emailFocusNode;
    late FocusNode passwordFocusNode;
    late bool submitCalled;
    late bool guestCalled;
    late bool forgotPasswordCalled;
    late bool registerCalled;

    setUp(() {
      formKey = GlobalKey<FormState>();
      emailController = TextEditingController();
      passwordController = TextEditingController();
      emailFocusNode = FocusNode();
      passwordFocusNode = FocusNode();
      submitCalled = false;
      guestCalled = false;
      forgotPasswordCalled = false;
      registerCalled = false;
    });

    tearDown(() {
      emailController.dispose();
      passwordController.dispose();
      emailFocusNode.dispose();
      passwordFocusNode.dispose();
    });

    Widget buildSubject({LoginState loginState = LoginState.idle}) {
      return SingleChildScrollView(
        child: BudgieLoginCard(
          formKey: formKey,
          emailController: emailController,
          passwordController: passwordController,
          emailFocusNode: emailFocusNode,
          passwordFocusNode: passwordFocusNode,
          loginState: loginState,
          onSubmit: () => submitCalled = true,
          onGoogleTap: () {},
          onAppleTap: () {},
          onGuestTap: () => guestCalled = true,
          onForgotPassword: () => forgotPasswordCalled = true,
          onRegister: () => registerCalled = true,
        ),
      );
    }

    testWidgets('renders without error', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.byType(BudgieLoginCard), findsOneWidget);
    });

    testWidgets('contains a Form widget', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('contains two AuthFormField widgets (email and password)', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.byType(AuthFormField), findsNWidgets(2));
    });

    testWidgets('shows welcome_back title in idle state', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      // .tr() returns the key in test context
      expect(find.text('auth.welcome_back'), findsOneWidget);
    });

    testWidgets('shows logging_in title in loading state', (tester) async {
      await pumpWidgetSimple(
        tester,
        buildSubject(loginState: LoginState.loading),
      );

      expect(find.text('auth.logging_in'), findsOneWidget);
    });

    testWidgets('shows welcome_success title in success state', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        buildSubject(loginState: LoginState.success),
      );

      expect(find.text('auth.welcome_success'), findsOneWidget);
    });

    testWidgets('shows try_again title in error state', (tester) async {
      await pumpWidgetSimple(
        tester,
        buildSubject(loginState: LoginState.error),
      );

      expect(find.text('auth.try_again'), findsOneWidget);
    });

    testWidgets('shows register link text', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.text('auth.no_account'), findsOneWidget);
      expect(find.text('auth.register'), findsOneWidget);
    });

    testWidgets('shows forgot password button', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.text('auth.forgot_password'), findsOneWidget);
    });

    testWidgets('shows login button with text in idle state', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('auth.login'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator in loading state', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        buildSubject(loginState: LoginState.loading),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows check icon in success state', (tester) async {
      await pumpWidgetSimple(
        tester,
        buildSubject(loginState: LoginState.success),
      );

      // LucideIcons.check icon appears on success
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('contains SocialLoginButtons widget', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.byType(SocialLoginButtons), findsOneWidget);
    });

    testWidgets('contains LegalLinksText widget', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.byType(LegalLinksText), findsOneWidget);
    });

    testWidgets('shows guest login button', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.text('auth.continue_as_guest'), findsOneWidget);
    });

    testWidgets('shows guest limitation hint', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.text('auth.guest_limitation_hint'), findsOneWidget);
    });

    testWidgets('validates empty email field', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('common.required_field'), findsWidgets);
    });

    testWidgets('validates invalid email format', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      emailController.text = 'not-an-email';
      passwordController.text = 'password123';
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('common.email_invalid'), findsOneWidget);
    });

    testWidgets('validates short password', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      emailController.text = 'test@example.com';
      passwordController.text = '1234567'; // Less than 8 chars
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('common.password_short'), findsOneWidget);
    });

    testWidgets('passes validation with valid credentials', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      emailController.text = 'test@example.com';
      passwordController.text = 'password123';

      final isValid = formKey.currentState!.validate();
      await tester.pump();

      expect(isValid, isTrue);
    });

    testWidgets('calls onSubmit when login button is tapped', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(submitCalled, isTrue);
    });

    testWidgets('calls onForgotPassword when forgot password tapped', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, buildSubject());

      await tester.tap(find.text('auth.forgot_password'));
      await tester.pump();

      expect(forgotPasswordCalled, isTrue);
    });

    testWidgets('calls onRegister when register link tapped', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      await tester.tap(find.text('auth.register'));
      await tester.pump();

      expect(registerCalled, isTrue);
    });

    testWidgets('calls onGuestTap when guest button tapped', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      await tester.ensureVisible(find.text('auth.continue_as_guest'));
      await tester.pump();
      await tester.tap(find.text('auth.continue_as_guest'));
      await tester.pump();

      expect(guestCalled, isTrue);
    });

    testWidgets('disables buttons in loading state', (tester) async {
      await pumpWidgetSimple(
        tester,
        buildSubject(loginState: LoginState.loading),
      );

      // FilledButton is disabled in loading
      final filledButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(filledButton.onPressed, isNull);

      // Guest button is disabled
      final guestButtons = tester.widgetList<TextButton>(
        find.byType(TextButton),
      );
      // Find guest button by checking if it has null onPressed
      final disabledCount =
          guestButtons.where((b) => b.onPressed == null).length;
      expect(disabledCount, greaterThanOrEqualTo(1));
    });

    testWidgets('has Google and Apple social login buttons', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.byType(OutlinedButton), findsOneWidget); // Google
      expect(find.byType(SignInWithAppleButton), findsOneWidget); // Apple
    });

    testWidgets('uses AnimatedSwitcher for title transitions', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.byType(AnimatedSwitcher), findsWidgets);
    });

    testWidgets('has Semantics wrapper on login button', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      // The login button has a Semantics with label 'auth.login'
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'auth.login' &&
              w.properties.button == true,
        ),
        findsOneWidget,
      );
    });
  });
}
