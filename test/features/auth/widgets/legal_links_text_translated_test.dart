import 'package:budgie_breeding_tracker/features/auth/widgets/legal_links_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_localization.dart';

/// These tests mount real translations. Keeping them in their own isolate
/// prevents easy_localization's process-static locale cache from changing the
/// raw-key assertions in legal_links_text_test.dart under shuffled ordering.
void main() {
  group('LegalLinksText (real translations)', () {
    for (final locale in const ['tr', 'en', 'de']) {
      testWidgets('wraps without overflow at 200% text scale in $locale', (
        tester,
      ) async {
        await pumpTranslatedWidget(
          tester,
          const MediaQuery(
            data: MediaQueryData(
              size: Size(320, 800),
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: SizedBox(width: 320, child: LegalLinksText()),
          ),
          locale: Locale(locale),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(TextButton), findsNWidgets(2));
      });
    }
  });
}
