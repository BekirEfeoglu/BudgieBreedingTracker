import 'package:budgie_breeding_tracker/core/widgets/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_helpers.dart';

void main() {
  group('AppProgressBar', () {
    testWidgets('renders optional label and percentage', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AppProgressBar(
          value: 0.42,
          label: 'Sync Progress',
          showPercentage: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sync Progress'), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);
    });

    testWidgets('hides header when label and percentage are disabled', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, const AppProgressBar(value: 0.42));
      await tester.pumpAndSettle();

      expect(find.textContaining('%'), findsNothing);
      expect(find.text('Sync Progress'), findsNothing);
    });

    testWidgets('clamps indicator value to upper bound', (tester) async {
      await pumpWidgetSimple(tester, const AppProgressBar(value: 1.8));
      await tester.pumpAndSettle();

      // Filled bar width saturates at the full track width (value 1.0).
      final trackWidth = tester.getSize(find.byType(AppProgressBar)).width;
      final fillWidth = tester.getSize(_fillFinder).width;
      expect(fillWidth, moreOrLessEquals(trackWidth, epsilon: 0.5));
    });

    testWidgets('clamps indicator value to lower bound', (tester) async {
      await pumpWidgetSimple(tester, const AppProgressBar(value: -0.4));
      await tester.pumpAndSettle();

      // Filled bar width collapses to zero (value 0.0).
      expect(
        tester.getSize(_fillFinder).width,
        moreOrLessEquals(0.0, epsilon: 0.5),
      );
    });

    testWidgets('uses provided background color', (tester) async {
      const backgroundColor = Colors.black12;

      await pumpWidgetSimple(
        tester,
        const AppProgressBar(value: 0.5, backgroundColor: backgroundColor),
      );
      await tester.pumpAndSettle();

      final track = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == backgroundColor,
        ),
      );
      expect((track.decoration as BoxDecoration).color, backgroundColor);
    });
  });
}

/// The filled portion is the only [Container] carrying a drop shadow.
final Finder _fillFinder = find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).boxShadow != null,
);
