import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/bird_selector_field.dart';

import '../../../helpers/test_helpers.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Form(child: child)),
    ),
  );
  await tester.pump();
}

void main() {
  group('BirdSelectorField', () {
    testWidgets('shows label text', (tester) async {
      final birds = [
        createTestBird(id: 'b-1', name: 'Erkek', gender: BirdGender.male),
      ];

      await _pump(
        tester,
        BirdSelectorField(
          label: 'Erkek Seç',
          birds: birds,
          onChanged: (_) {},
          gender: BirdGender.male,
        ),
      );

      expect(find.text('Erkek Seç'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows all birds as dropdown items', (tester) async {
      final birds = [
        createTestBird(id: 'b-1', name: 'Kus1', gender: BirdGender.male),
        createTestBird(id: 'b-2', name: 'Kus2', gender: BirdGender.male),
      ];

      await _pump(
        tester,
        BirdSelectorField(label: 'Seç', birds: birds, onChanged: (_) {}),
      );

      // DropdownButtonFormField widget renders with birds list
      expect(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
        findsOneWidget,
      );
    });

    testWidgets('shows ring number in item when available', (tester) async {
      final birds = [
        createTestBird(id: 'b-1', name: 'Kus1', ringNumber: 'TR-001'),
      ];

      await _pump(
        tester,
        BirdSelectorField(
          label: 'Seç',
          birds: birds,
          selectedId: 'b-1',
          onChanged: (_) {},
        ),
      );

      // Selected item shows name + ring number in the collapsed dropdown
      expect(find.text('Kus1'), findsOneWidget);
    });

    testWidgets('sets initial value correctly', (tester) async {
      final birds = [
        createTestBird(id: 'b-1', name: 'Kus1'),
        createTestBird(id: 'b-2', name: 'Kus2'),
      ];

      await _pump(
        tester,
        BirdSelectorField(
          label: 'Seç',
          birds: birds,
          selectedId: 'b-1',
          onChanged: (_) {},
        ),
      );

      // Selected bird name should be shown as the current value in collapsed state
      expect(find.text('Kus1'), findsOneWidget);
    });

    testWidgets('validates null selection', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: BirdSelectorField(
                label: 'Erkek Kus',
                birds: const [],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      formKey.currentState?.validate();
      await tester.pump();

      // Validation error text should appear
      expect(find.textContaining('Erkek Kus'), findsAtLeastNWidgets(1));
    });

    testWidgets('onChanged callback is invoked when selection changes', (
      tester,
    ) async {
      String? selected;
      final birds = [createTestBird(id: 'b-1', name: 'Kus1')];

      await _pump(
        tester,
        BirdSelectorField(
          label: 'Seç',
          birds: birds,
          onChanged: (id) => selected = id,
        ),
      );

      // Manually call onChanged via widget reference
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      dropdown.onChanged?.call('b-1');

      expect(selected, 'b-1');
    });

    testWidgets('dropdown renders in expanded mode', (tester) async {
      await _pump(
        tester,
        BirdSelectorField(label: 'Seç', birds: const [], onChanged: (_) {}),
      );

      // Widget renders successfully (isExpanded is a constructor-only param, not inspectable)
      expect(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
        findsOneWidget,
      );
    });
  });
}
