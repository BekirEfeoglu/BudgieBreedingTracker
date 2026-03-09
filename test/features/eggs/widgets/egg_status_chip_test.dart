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

  group('EggStatusChip', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.laid));
      await tester.pump();

      expect(find.byType(EggStatusChip), findsOneWidget);
    });

    testWidgets('shows laid status label', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.laid));
      await tester.pump();

      expect(find.text('eggs.status_laid'), findsOneWidget);
    });

    testWidgets('shows fertile status label', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.fertile));
      await tester.pump();

      expect(find.text('eggs.status_fertile'), findsOneWidget);
    });

    testWidgets('shows hatched status label', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.hatched));
      await tester.pump();

      expect(find.text('eggs.status_hatched'), findsOneWidget);
    });

    testWidgets('shows incubating status label', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.incubating));
      await tester.pump();

      expect(find.text('eggs.status_incubating'), findsOneWidget);
    });

    testWidgets('shows infertile status label', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.infertile));
      await tester.pump();

      expect(find.text('eggs.status_infertile'), findsOneWidget);
    });

    testWidgets('shows damaged status label', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.damaged));
      await tester.pump();

      expect(find.text('eggs.status_damaged'), findsOneWidget);
    });

    testWidgets('shows discarded status label', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.discarded));
      await tester.pump();

      expect(find.text('eggs.status_discarded'), findsOneWidget);
    });

    testWidgets('shows unknown status label', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.unknown));
      await tester.pump();

      expect(find.text('eggs.status_unknown'), findsOneWidget);
    });

    testWidgets('renders Container with decoration', (tester) async {
      await tester.pumpWidget(createSubject(EggStatus.laid));
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });
  });
}
