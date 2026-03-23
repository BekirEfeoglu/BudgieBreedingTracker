import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_status_chip.dart';

void main() {
  Widget createSubject(EggStatus status) {
    return MaterialApp(
      home: Scaffold(body: EggStatusChip(status: status)),
    );
  }

  group('EggStatusChip - All Statuses', () {
    testWidgets('renders laid status with correct label', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.laid));
      await tester.pump();

      expect(find.text('eggs.status_laid'), findsOneWidget);
    });

    testWidgets('renders fertile status with correct label', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.fertile));
      await tester.pump();

      expect(find.text('eggs.status_fertile'), findsOneWidget);
    });

    testWidgets('renders infertile status with correct label', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.infertile));
      await tester.pump();

      expect(find.text('eggs.status_infertile'), findsOneWidget);
    });

    testWidgets('renders incubating status with correct label', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(EggStatus.incubating));
      await tester.pump();

      expect(find.text('eggs.status_incubating'), findsOneWidget);
    });

    testWidgets('renders hatched status with correct label', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.hatched));
      await tester.pump();

      expect(find.text('eggs.status_hatched'), findsOneWidget);
    });

    testWidgets('renders damaged status with correct label', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.damaged));
      await tester.pump();

      expect(find.text('eggs.status_damaged'), findsOneWidget);
    });

    testWidgets('renders discarded status with correct label', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.discarded));
      await tester.pump();

      expect(find.text('eggs.status_discarded'), findsOneWidget);
    });

    testWidgets('renders empty status with correct label', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.empty));
      await tester.pump();

      expect(find.text('eggs.status_empty'), findsOneWidget);
    });

    testWidgets('renders unknown status with correct label', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.unknown));
      await tester.pump();

      expect(find.text('eggs.status_unknown'), findsOneWidget);
    });
  });

  group('EggStatusChip - Visual Structure', () {
    testWidgets('wraps text in a Container with decoration', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.laid));
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('contains a Text widget for the label', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.fertile));
      await tester.pump();

      expect(find.byType(Text), findsAtLeastNWidgets(1));
    });

    testWidgets('every status renders without crashing', (tester) async {
      for (final status in EggStatus.values) {
        await tester.pumpWidget(createSubject(status));
        await tester.pump();

        expect(find.byType(EggStatusChip), findsOneWidget);
      }
    });

    testWidgets('has rounded border radius (pill shape)', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.laid));
      await tester.pump();

      final container = tester.widgetList<Container>(
        find.byType(Container),
      ).where((c) => c.decoration is BoxDecoration).firstOrNull;

      expect(container, isNotNull);
      if (container != null) {
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.borderRadius, isNotNull);
      }
    });

    testWidgets('has a border in the decoration', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.incubating));
      await tester.pump();

      final container = tester.widgetList<Container>(
        find.byType(Container),
      ).where((c) => c.decoration is BoxDecoration).firstOrNull;

      expect(container, isNotNull);
      if (container != null) {
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.border, isNotNull);
      }
    });

    testWidgets('text uses small bold font style', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.fertile));
      await tester.pump();

      final text = tester.widget<Text>(find.text('eggs.status_fertile'));
      expect(text.style?.fontSize, 11);
      expect(text.style?.fontWeight, FontWeight.w600);
    });
  });

  group('EggStatusChip - Color Consistency', () {
    testWidgets('different statuses have different background colors', (
      tester,
    ) async {
      // Render laid
      await tester.pumpWidget(createSubject(EggStatus.laid));
      await tester.pump();
      final laidContainer = tester.widgetList<Container>(
        find.byType(Container),
      ).where((c) => c.decoration is BoxDecoration).first;
      final laidColor =
          (laidContainer.decoration! as BoxDecoration).color;

      // Render hatched
      await tester.pumpWidget(createSubject(EggStatus.hatched));
      await tester.pump();
      final hatchedContainer = tester.widgetList<Container>(
        find.byType(Container),
      ).where((c) => c.decoration is BoxDecoration).first;
      final hatchedColor =
          (hatchedContainer.decoration! as BoxDecoration).color;

      // They should be different
      expect(laidColor, isNot(equals(hatchedColor)));
    });

    testWidgets('damaged status uses a distinct color from fertile', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(EggStatus.damaged));
      await tester.pump();
      final damagedContainer = tester.widgetList<Container>(
        find.byType(Container),
      ).where((c) => c.decoration is BoxDecoration).first;
      final damagedColor =
          (damagedContainer.decoration! as BoxDecoration).color;

      await tester.pumpWidget(createSubject(EggStatus.fertile));
      await tester.pump();
      final fertileContainer = tester.widgetList<Container>(
        find.byType(Container),
      ).where((c) => c.decoration is BoxDecoration).first;
      final fertileColor =
          (fertileContainer.decoration! as BoxDecoration).color;

      expect(damagedColor, isNot(equals(fertileColor)));
    });
  });
}
