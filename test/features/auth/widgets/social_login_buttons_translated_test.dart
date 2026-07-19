import 'package:budgie_breeding_tracker/features/auth/widgets/social_login_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../helpers/test_localization.dart';

/// These tests mount real translations. easy_localization caches translations
/// per locale in process-static state, so they must remain in a separate test
/// isolate from the raw-key assertions in social_login_buttons_test.dart.
void main() {
  group('SocialLoginButtons (real translations)', () {
    for (final locale in const ['tr', 'en', 'de']) {
      testWidgets('fits Apple and Google labels at 200% in $locale', (
        tester,
      ) async {
        await pumpTranslatedWidget(
          tester,
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: SizedBox(
              width: 320,
              child: SocialLoginButtons(
                onGoogleTap: () {},
                onAppleTap: () {},
                isLoading: false,
              ),
            ),
          ),
          locale: Locale(locale),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(SignInWithAppleButton), findsOneWidget);
      });
    }
  });
}
