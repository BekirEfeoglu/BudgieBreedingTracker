import 'package:budgie_breeding_tracker/features/auth/widgets/legal_links_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  group('LegalLinksText', () {
    testWidgets('renders without error', (tester) async {
      await pumpWidgetSimple(tester, const LegalLinksText());

      expect(find.byType(LegalLinksText), findsOneWidget);
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('shows legal text content with all spans', (tester) async {
      await pumpWidgetSimple(tester, const LegalLinksText());

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final textSpan = richText.text as TextSpan;

      // RichText contains 5 children spans
      expect(textSpan.children, hasLength(5));

      // In test context .tr() returns the key itself
      final spanTexts = textSpan.children!
          .map((s) => (s as TextSpan).text)
          .toList();
      expect(spanTexts[0], 'auth.agree_terms_prefix');
      expect(spanTexts[1], 'auth.terms_of_service');
      expect(spanTexts[2], 'auth.agree_terms_and');
      expect(spanTexts[3], 'auth.privacy_policy');
      expect(spanTexts[4], 'auth.agree_terms_suffix');
    });

    testWidgets('contains tappable terms of service link', (tester) async {
      await pumpWidgetSimple(tester, const LegalLinksText());

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final textSpan = richText.text as TextSpan;

      // Find the terms of service span (second child)
      final termsSpan = textSpan.children![1] as TextSpan;

      // Verify it has a tap recognizer
      expect(termsSpan.recognizer, isA<TapGestureRecognizer>());
    });

    testWidgets('contains tappable privacy policy link', (tester) async {
      await pumpWidgetSimple(tester, const LegalLinksText());

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final textSpan = richText.text as TextSpan;

      // Find the privacy policy span (fourth child)
      final privacySpan = textSpan.children![3] as TextSpan;

      // Verify it has a tap recognizer
      expect(privacySpan.recognizer, isA<TapGestureRecognizer>());
    });

    testWidgets('link spans have underline decoration', (tester) async {
      await pumpWidgetSimple(tester, const LegalLinksText());

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final textSpan = richText.text as TextSpan;

      final termsSpan = textSpan.children![1] as TextSpan;
      final privacySpan = textSpan.children![3] as TextSpan;

      expect(termsSpan.style?.decoration, TextDecoration.underline);
      expect(privacySpan.style?.decoration, TextDecoration.underline);
    });

    testWidgets('non-link spans have no tap recognizer', (tester) async {
      await pumpWidgetSimple(tester, const LegalLinksText());

      final richText = tester.widget<RichText>(find.byType(RichText).first);
      final textSpan = richText.text as TextSpan;

      // Prefix (index 0), "and" (index 2), suffix (index 4) should have no recognizer
      final prefixSpan = textSpan.children![0] as TextSpan;
      final andSpan = textSpan.children![2] as TextSpan;
      final suffixSpan = textSpan.children![4] as TextSpan;

      expect(prefixSpan.recognizer, isNull);
      expect(andSpan.recognizer, isNull);
      expect(suffixSpan.recognizer, isNull);
    });
  });
}
