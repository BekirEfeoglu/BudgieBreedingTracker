import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/buttons/fab_button.dart';
import '../../helpers/pump_helpers.dart';

void main() {
  group('FabButton', () {
    testWidgets('renders icon child', (tester) async {
      await pumpWidgetSimple(
        tester,
        FabButton(icon: const Icon(Icons.add), onPressed: () {}),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('triggers onPressed callback', (tester) async {
      var pressed = false;

      await pumpWidgetSimple(
        tester,
        FabButton(icon: const Icon(Icons.add), onPressed: () => pressed = true),
      );

      await tester.tap(find.byType(FloatingActionButton));
      expect(pressed, isTrue);
    });

    testWidgets('shows tooltip on long press', (tester) async {
      await pumpWidgetSimple(
        tester,
        FabButton(
          icon: const Icon(Icons.add),
          onPressed: () {},
          tooltip: 'Add item',
        ),
      );

      await tester.longPress(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add item'), findsOneWidget);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await pumpWidgetSimple(tester, const FabButton(icon: Icon(Icons.add)));

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.onPressed, isNull);
    });
  });
}
