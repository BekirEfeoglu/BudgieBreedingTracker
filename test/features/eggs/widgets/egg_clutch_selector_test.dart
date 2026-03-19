import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_clutch_selector.dart';

import '../../../helpers/test_fixtures.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  final clutch1 = TestFixtures.sampleClutch(id: 'clutch-1', breedingId: 'pair-1');
  const clutchWithName = Clutch(
    id: 'clutch-named',
    userId: 'user-1',
    name: 'Spring 2024',
    breedingId: 'pair-1',
  );

  group('EggClutchSelector', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(EggClutchSelector(clutches: const [], onChanged: (_) {})),
      );

      expect(find.byType(EggClutchSelector), findsOneWidget);
    });

    testWidgets('shows DropdownButtonFormField', (tester) async {
      await tester.pumpWidget(
        _wrap(EggClutchSelector(clutches: [clutch1], onChanged: (_) {})),
      );

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('shows clutch options when dropdown is opened', (tester) async {
      await tester.pumpWidget(
        _wrap(EggClutchSelector(
          clutches: [clutchWithName],
          onChanged: (_) {},
        )),
      );

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // The clutch name should appear in the dropdown items
      expect(find.text('Spring 2024'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays clutch id prefix when name is null', (tester) async {
      await tester.pumpWidget(
        _wrap(EggClutchSelector(
          clutches: [clutch1],
          onChanged: (_) {},
        )),
      );

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Should show first 8 chars of id as fallback
      expect(find.text('clutch-1'), findsAtLeastNWidgets(1));
    });

    testWidgets('handles empty clutch list', (tester) async {
      await tester.pumpWidget(
        _wrap(EggClutchSelector(clutches: const [], onChanged: (_) {})),
      );

      // Should render without error even with empty list
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('selection change triggers callback', (tester) async {
      String? selectedId;

      await tester.pumpWidget(
        _wrap(EggClutchSelector(
          clutches: [clutchWithName],
          onChanged: (id) => selectedId = id,
        )),
      );

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select the clutch item
      await tester.tap(find.text('Spring 2024').last);
      await tester.pumpAndSettle();

      expect(selectedId, 'clutch-named');
    });

    testWidgets('shows multiple clutch options', (tester) async {
      const namedClutch1 = Clutch(
        id: 'c1',
        userId: 'user-1',
        name: 'First Clutch',
      );
      const namedClutch2 = Clutch(
        id: 'c2',
        userId: 'user-1',
        name: 'Second Clutch',
      );

      await tester.pumpWidget(
        _wrap(EggClutchSelector(
          clutches: [namedClutch1, namedClutch2],
          onChanged: (_) {},
        )),
      );

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('First Clutch'), findsAtLeastNWidgets(1));
      expect(find.text('Second Clutch'), findsAtLeastNWidgets(1));
    });

    testWidgets('ignores invalid selectedClutchId', (tester) async {
      await tester.pumpWidget(
        _wrap(EggClutchSelector(
          clutches: [clutch1],
          selectedClutchId: 'non-existent-id',
          onChanged: (_) {},
        )),
      );

      // Should render without error, treating invalid id as null
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('pre-selects valid selectedClutchId', (tester) async {
      await tester.pumpWidget(
        _wrap(EggClutchSelector(
          clutches: [clutchWithName],
          selectedClutchId: 'clutch-named',
          onChanged: (_) {},
        )),
      );

      // The selected clutch name should be visible without opening dropdown
      expect(find.text('Spring 2024'), findsOneWidget);
    });
  });
}
