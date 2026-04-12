import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_bird_picker.dart';

import '../../../../helpers/pump_helpers.dart';

Bird _bird({
  String name = 'TestBird',
  BirdGender gender = BirdGender.male,
  String? ringNumber,
}) =>
    Bird(
      id: 'test-${name.toLowerCase()}',
      userId: 'u1',
      name: name,
      gender: gender,
      species: Species.budgie,
      status: BirdStatus.alive,
      ringNumber: ringNumber,
    );

void main() {
  group('AiBirdPicker', () {
    testWidgets('shows two selection slots when no birds selected',
        (tester) async {
      await pumpWidgetSimple(
        tester,
        AiBirdPicker(
          selectedFather: null,
          selectedMother: null,
          onSelectFather: () {},
          onSelectMother: () {},
          onClearFather: () {},
          onClearMother: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AiBirdPicker), findsOneWidget);
      expect(find.byType(InkWell), findsNWidgets(2));
    });

    testWidgets('shows bird name when father is selected', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiBirdPicker(
          selectedFather: _bird(name: 'Atlas'),
          selectedMother: null,
          onSelectFather: () {},
          onSelectMother: () {},
          onClearFather: () {},
          onClearMother: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Atlas'), findsOneWidget);
    });

    testWidgets('shows ring number when available', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiBirdPicker(
          selectedFather: _bird(name: 'Atlas', ringNumber: 'TR-001'),
          selectedMother: null,
          onSelectFather: () {},
          onSelectMother: () {},
          onClearFather: () {},
          onClearMother: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TR-001'), findsOneWidget);
    });

    testWidgets('calls onSelectFather when father slot tapped', (tester) async {
      var called = false;
      await pumpWidgetSimple(
        tester,
        AiBirdPicker(
          selectedFather: null,
          selectedMother: null,
          onSelectFather: () => called = true,
          onSelectMother: () {},
          onClearFather: () {},
          onClearMother: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      expect(called, isTrue);
    });

    testWidgets('calls onSelectMother when mother slot tapped', (tester) async {
      var called = false;
      await pumpWidgetSimple(
        tester,
        AiBirdPicker(
          selectedFather: null,
          selectedMother: null,
          onSelectFather: () {},
          onSelectMother: () => called = true,
          onClearFather: () {},
          onClearMother: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).last);
      expect(called, isTrue);
    });

    testWidgets('shows clear button when bird selected', (tester) async {
      var cleared = false;
      await pumpWidgetSimple(
        tester,
        AiBirdPicker(
          selectedFather: _bird(name: 'Atlas'),
          selectedMother: null,
          onSelectFather: () {},
          onSelectMother: () {},
          onClearFather: () => cleared = true,
          onClearMother: () {},
        ),
      );
      await tester.pumpAndSettle();

      // LucideIcons.x icon should be visible for the clear button
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
      await tester.tap(find.byIcon(LucideIcons.x));
      expect(cleared, isTrue);
    });

    testWidgets('does not show clear button when no bird selected',
        (tester) async {
      await pumpWidgetSimple(
        tester,
        AiBirdPicker(
          selectedFather: null,
          selectedMother: null,
          onSelectFather: () {},
          onSelectMother: () {},
          onClearFather: () {},
          onClearMother: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.x), findsNothing);
    });

    testWidgets('shows x separator between slots', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiBirdPicker(
          selectedFather: null,
          selectedMother: null,
          onSelectFather: () {},
          onSelectMother: () {},
          onClearFather: () {},
          onClearMother: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('\u00D7'), findsOneWidget);
    });

    testWidgets('shows both birds when father and mother selected',
        (tester) async {
      await pumpWidgetSimple(
        tester,
        AiBirdPicker(
          selectedFather: _bird(name: 'Atlas', gender: BirdGender.male),
          selectedMother: _bird(name: 'Luna', gender: BirdGender.female),
          onSelectFather: () {},
          onSelectMother: () {},
          onClearFather: () {},
          onClearMother: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Atlas'), findsOneWidget);
      expect(find.text('Luna'), findsOneWidget);
      // Two clear buttons
      expect(find.byIcon(LucideIcons.x), findsNWidgets(2));
    });
  });
}
