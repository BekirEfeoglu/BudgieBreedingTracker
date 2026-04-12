import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/fade_scrollable_chip_bar.dart';
import '../../helpers/pump_helpers.dart';

void main() {
  group('FadeScrollableChipBar', () {
    testWidgets('renders children chips', (tester) async {
      await pumpWidgetSimple(
        tester,
        const FadeScrollableChipBar(
          children: [
            Chip(label: Text('All')),
            Chip(label: Text('Male')),
            Chip(label: Text('Female')),
          ],
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
    });

    testWidgets('contains a horizontal ListView', (tester) async {
      await pumpWidgetSimple(
        tester,
        const FadeScrollableChipBar(children: [Chip(label: Text('A'))]),
      );

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('has gradient overlay via Stack', (tester) async {
      await pumpWidgetSimple(
        tester,
        const FadeScrollableChipBar(children: [Chip(label: Text('A'))]),
      );

      // FadeScrollableChipBar uses a Stack for gradient overlay
      expect(find.byType(Stack), findsAtLeast(1));
    });

    testWidgets('uses custom height when provided', (tester) async {
      await pumpWidgetSimple(
        tester,
        const FadeScrollableChipBar(
          height: 60,
          children: [Chip(label: Text('A'))],
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find
            .ancestor(of: find.byType(Stack), matching: find.byType(SizedBox))
            .first,
      );

      expect(sizedBox.height, 60);
    });

    testWidgets('has IgnorePointer on gradient to prevent tap interference', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        const FadeScrollableChipBar(children: [Chip(label: Text('A'))]),
      );

      // At least one IgnorePointer for gradient overlay
      expect(find.byType(IgnorePointer), findsAtLeast(1));
    });
  });
}
