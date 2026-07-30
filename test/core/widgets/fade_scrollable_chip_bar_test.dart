import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

    testWidgets('shows a non-interactive overflow cue only when needed', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        const SizedBox(
          width: 180,
          child: FadeScrollableChipBar(
            children: [
              SizedBox(width: 120, child: Chip(label: Text('First'))),
              SizedBox(width: 120, child: Chip(label: Text('Second'))),
              SizedBox(width: 120, child: Chip(label: Text('Third'))),
            ],
          ),
        ),
      );
      await tester.pump();

      final cueIcon = find.byIcon(LucideIcons.chevronRight);
      expect(cueIcon, findsOneWidget);
      expect(
        tester
            .widgetList<IgnorePointer>(
              find.ancestor(of: cueIcon, matching: find.byType(IgnorePointer)),
            )
            .any((widget) => widget.ignoring),
        isTrue,
      );

      await tester.drag(find.byType(ListView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(cueIcon, findsNothing);
    });
  });
}
