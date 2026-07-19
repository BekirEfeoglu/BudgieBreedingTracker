import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/auth/widgets/legal_links_text.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  group('LegalLinksText', () {
    testWidgets('renders legal copy and two explicit link controls', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, const LegalLinksText());

      expect(find.byType(LegalLinksText), findsOneWidget);
      expect(find.byType(TextButton), findsNWidgets(2));
      expect(find.text('auth.agree_terms_prefix'), findsOneWidget);
      expect(find.text('auth.terms_of_service'), findsOneWidget);
      expect(find.text('auth.agree_terms_and'), findsOneWidget);
      expect(find.text('auth.privacy_policy'), findsOneWidget);
      expect(find.text('auth.agree_terms_suffix'), findsOneWidget);
    });

    testWidgets('legal links expose link semantics', (tester) async {
      await pumpWidgetSimple(tester, const LegalLinksText());

      final linkSemantics = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.link == true,
      );
      expect(linkSemantics, findsNWidgets(2));
    });

    testWidgets('legal links meet the 48dp project touch target', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, const LegalLinksText());

      for (final element in find.byType(TextButton).evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });
  });
}
