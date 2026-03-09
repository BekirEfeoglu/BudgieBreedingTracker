import 'package:budgie_breeding_tracker/core/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_helpers.dart';

void main() {
  group('StatusBadge', () {
    testWidgets('renders label text', (tester) async {
      await pumpWidgetSimple(
        tester,
        const StatusBadge(label: 'Active', color: Colors.green),
      );

      expect(find.text('Active'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('renders optional icon with themed style', (tester) async {
      await pumpWidgetSimple(
        tester,
        const StatusBadge(
          label: 'Done',
          color: Colors.blue,
          icon: Icon(Icons.check),
        ),
      );

      expect(find.text('Done'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      final iconTheme = tester.widget<IconTheme>(
        find
            .ancestor(
              of: find.byIcon(Icons.check),
              matching: find.byType(IconTheme),
            )
            .first,
      );
      expect(iconTheme.data.size, 14);
      expect(iconTheme.data.color, Colors.blue);
    });
  });
}
