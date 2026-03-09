import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import '../../helpers/pump_helpers.dart';

void main() {
  group('PrimaryButton', () {
    testWidgets('renders label text', (tester) async {
      await pumpWidgetSimple(
        tester,
        PrimaryButton(label: 'Save', onPressed: () {}),
      );

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('triggers onPressed callback', (tester) async {
      var pressed = false;

      await pumpWidgetSimple(
        tester,
        PrimaryButton(label: 'Tap me', onPressed: () => pressed = true),
      );

      await tester.tap(find.text('Tap me'));
      expect(pressed, isTrue);
    });

    testWidgets('shows CircularProgressIndicator when isLoading', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        const PrimaryButton(label: 'Save', isLoading: true),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('disables button when isLoading', (tester) async {
      var pressed = false;

      await pumpWidgetSimple(
        tester,
        PrimaryButton(
          label: 'Save',
          isLoading: true,
          onPressed: () => pressed = true,
        ),
      );

      await tester.tap(find.byType(FilledButton));
      expect(pressed, isFalse);
    });

    testWidgets('renders icon when provided', (tester) async {
      await pumpWidgetSimple(
        tester,
        PrimaryButton(
          label: 'Add',
          icon: const Icon(Icons.add),
          onPressed: () {},
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('renders without icon when not provided', (tester) async {
      await pumpWidgetSimple(
        tester,
        PrimaryButton(label: 'Simple', onPressed: () {}),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await pumpWidgetSimple(tester, const PrimaryButton(label: 'Disabled'));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });
}
