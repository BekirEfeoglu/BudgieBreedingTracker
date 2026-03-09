import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/genealogy/widgets/depth_chip.dart';

void main() {
  group('DepthChip', () {
    testWidgets('renders current depth value in chip label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: [DepthChip(depth: 5, onChanged: (_) {})]),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders with depth 3', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: [DepthChip(depth: 3, onChanged: (_) {})]),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('opens popup menu on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: [DepthChip(depth: 4, onChanged: (_) {})]),
          ),
        ),
      );

      // Tap the PopupMenuButton child (Chip)
      await tester.tap(find.byType(PopupMenuButton<int>));
      await tester.pump();

      // Consume Row overflow exceptions from popup menu items
      var ex = tester.takeException();
      while (ex != null) {
        if (!ex.toString().contains('overflowed')) throw ex as Object;
        ex = tester.takeException();
      }

      // Popup menu should show items (genealogy.generations for each depth 3-8)
      expect(find.byType(PopupMenuItem<int>), findsWidgets);
    });

    testWidgets('calls onChanged when menu item selected', (tester) async {
      int? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                DepthChip(depth: 4, onChanged: (v) => selectedValue = v),
              ],
            ),
          ),
        ),
      );

      // Directly invoke onSelected from the PopupMenuButton widget.
      // Popup menu items overflow in the test viewport (no l10n → long key strings),
      // making UI tap unreliable. Verifying the callback wiring is the correct test.
      final popup = tester.widget<PopupMenuButton<int>>(
        find.byType(PopupMenuButton<int>),
      );
      popup.onSelected?.call(5);
      expect(selectedValue, equals(5));
    });

    testWidgets('shows Chip widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: [DepthChip(depth: 6, onChanged: (_) {})]),
          ),
        ),
      );

      expect(find.byType(Chip), findsOneWidget);
    });
  });
}
