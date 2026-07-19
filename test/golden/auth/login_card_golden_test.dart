@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/theme/app_theme.dart';
import 'package:budgie_breeding_tracker/features/auth/screens/budgie_login_screen.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/budgie_login_card.dart';

import '../../helpers/test_localization.dart';

void main() {
  const surfaceSize = Size(430, 1100);

  Future<void> pumpCard(
    WidgetTester tester, {
    required String locale,
    required ThemeData theme,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final emailFocusNode = FocusNode();
    final passwordFocusNode = FocusNode();
    addTearDown(emailController.dispose);
    addTearDown(passwordController.dispose);
    addTearDown(emailFocusNode.dispose);
    addTearDown(passwordFocusNode.dispose);

    await pumpTranslatedWidget(
      tester,
      Builder(
        builder: (context) => RepaintBoundary(
          key: const ValueKey('login-card-golden'),
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: BudgieLoginCard(
                formKey: GlobalKey<FormState>(),
                emailController: emailController,
                passwordController: passwordController,
                emailFocusNode: emailFocusNode,
                passwordFocusNode: passwordFocusNode,
                loginState: LoginState.idle,
                onSubmit: () {},
                onGoogleTap: () {},
                onAppleTap: () {},
                onGuestTap: () {},
                onForgotPassword: () {},
                onRegister: () {},
              ),
            ),
          ),
        ),
      ),
      locale: Locale(locale),
      theme: theme,
    );
  }

  for (final locale in const ['tr', 'en', 'de']) {
    testWidgets('login card light $locale', (tester) async {
      await pumpCard(tester, locale: locale, theme: AppTheme.light());

      await expectLater(
        find.byKey(const ValueKey('login-card-golden')),
        matchesGoldenFile('goldens/login_card_light_$locale.png'),
      );
    });
  }

  testWidgets('login card dark tr', (tester) async {
    await pumpCard(tester, locale: 'tr', theme: AppTheme.dark());

    await expectLater(
      find.byKey(const ValueKey('login-card-golden')),
      matchesGoldenFile('goldens/login_card_dark_tr.png'),
    );
  });
}
