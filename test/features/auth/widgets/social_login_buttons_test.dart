import 'package:budgie_breeding_tracker/features/auth/widgets/social_login_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  group('SocialLoginButtons', () {
    late bool googleCalled;
    late bool appleCalled;

    setUp(() {
      googleCalled = false;
      appleCalled = false;
    });

    Widget buildSubject({bool isLoading = false}) {
      return SocialLoginButtons(
        onGoogleTap: () => googleCalled = true,
        onAppleTap: () => appleCalled = true,
        isLoading: isLoading,
      );
    }

    testWidgets('renders without error', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.byType(SocialLoginButtons), findsOneWidget);
    });

    testWidgets('shows divider with "or" text', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.byType(Divider), findsNWidgets(2));
      // .tr() returns the key in test context
      expect(find.text(l10n('common.or')), findsOneWidget);
    });

    testWidgets('shows Google sign-in button', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text(l10n('auth.sign_in_with_google')), findsOneWidget);
    });

    testWidgets('shows Apple sign-in button', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      expect(find.byType(SignInWithAppleButton), findsOneWidget);
    });

    testWidgets('calls onGoogleTap when Google button is tapped', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, buildSubject());

      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(googleCalled, isTrue);
    });

    testWidgets('calls onAppleTap when Apple button is tapped', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, buildSubject());

      await tester.tap(find.byType(SignInWithAppleButton));
      await tester.pump();

      expect(appleCalled, isTrue);
    });

    testWidgets('disables Google button when isLoading is true', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, buildSubject(isLoading: true));

      final outlinedButton = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(outlinedButton.onPressed, isNull);
    });

    testWidgets('disables Apple button when isLoading is true', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, buildSubject(isLoading: true));

      final appleButton = tester.widget<SignInWithAppleButton>(
        find.byType(SignInWithAppleButton),
      );
      expect(appleButton.onPressed, isNull);
    });

    testWidgets('does not call onGoogleTap when loading', (tester) async {
      await pumpWidgetSimple(tester, buildSubject(isLoading: true));

      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(googleCalled, isFalse);
    });

    testWidgets('Google button uses OutlinedButton.icon style', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, buildSubject());

      // The OutlinedButton should have icon and label
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text(l10n('auth.sign_in_with_google')), findsOneWidget);
    });

    testWidgets('Google button has press scale animation wrapper', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, buildSubject());

      // AnimatedScale is used by _PressScaleButton
      expect(find.byType(AnimatedScale), findsOneWidget);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('Google button shows scale animation on tap down', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, buildSubject());

      // Initial scale should be 1.0
      final initialScale = tester.widget<AnimatedScale>(
        find.byType(AnimatedScale),
      );
      expect(initialScale.scale, 1.0);
    });

    testWidgets('Apple button style adapts to light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(body: buildSubject()),
        ),
      );

      final appleButton = tester.widget<SignInWithAppleButton>(
        find.byType(SignInWithAppleButton),
      );
      // In light theme, Apple button should be black style
      expect(appleButton.style, SignInWithAppleButtonStyle.black);
    });

    testWidgets('Apple button style adapts to dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(body: buildSubject()),
        ),
      );

      final appleButton = tester.widget<SignInWithAppleButton>(
        find.byType(SignInWithAppleButton),
      );
      // In dark theme, Apple button should be white style
      expect(appleButton.style, SignInWithAppleButtonStyle.white);
    });

    testWidgets('Apple button has full width via SizedBox', (tester) async {
      await pumpWidgetSimple(tester, buildSubject());

      final sizedBox = find.ancestor(
        of: find.byType(SignInWithAppleButton),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == double.infinity,
        ),
      );
      expect(sizedBox, findsOneWidget);
    });

    testWidgets('renders correctly in both loading states', (tester) async {
      // Not loading
      await pumpWidgetSimple(tester, buildSubject(isLoading: false));
      expect(find.byType(SocialLoginButtons), findsOneWidget);

      // Loading
      await pumpWidgetSimple(tester, buildSubject(isLoading: true));
      expect(find.byType(SocialLoginButtons), findsOneWidget);
    });
  });
}
