import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_summary_row.dart';

Egg _createEgg({EggStatus status = EggStatus.laid}) {
  return Egg(
    id: 'egg-1',
    layDate: DateTime(2024, 1, 1),
    userId: 'user-1',
    status: status,
  );
}

void main() {
  Widget createSubject(List<Egg> eggs) {
    return MaterialApp(
      home: Scaffold(body: EggSummaryRow(eggs: eggs)),
    );
  }

  group('EggSummaryRow', () {
    testWidgets('shows no_eggs text when list is empty', (tester) async {
      await tester.pumpWidget(createSubject([]));
      await tester.pump();

      expect(find.text('eggs.summary_no_eggs'), findsOneWidget);
    });

    testWidgets('renders without crashing with one egg', (tester) async {
      await tester.pumpWidget(createSubject([_createEgg()]));
      await tester.pump();

      expect(find.byType(EggSummaryRow), findsOneWidget);
    });

    testWidgets('does not show no_eggs when list is non-empty', (tester) async {
      await tester.pumpWidget(createSubject([_createEgg()]));
      await tester.pump();

      expect(find.text('eggs.summary_no_eggs'), findsNothing);
    });

    testWidgets('shows Row when eggs are present', (tester) async {
      await tester.pumpWidget(createSubject([_createEgg()]));
      await tester.pump();

      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });

    testWidgets('shows summary count text for single egg', (tester) async {
      // All laid — no hatched/fertile suffix, so text is just the key
      await tester.pumpWidget(
        createSubject([_createEgg(status: EggStatus.laid)]),
      );
      await tester.pump();

      expect(find.text('eggs.summary_count'), findsOneWidget);
    });

    testWidgets('shows multiple eggs without crashing', (tester) async {
      final eggs = [
        _createEgg(status: EggStatus.laid),
        _createEgg(status: EggStatus.infertile),
        _createEgg(status: EggStatus.laid),
      ];
      await tester.pumpWidget(createSubject(eggs));
      await tester.pump();

      expect(find.byType(EggSummaryRow), findsOneWidget);
    });

    testWidgets('renders AppIcon widgets for each egg', (tester) async {
      final eggs = [_createEgg(), _createEgg()];
      await tester.pumpWidget(createSubject(eggs));
      await tester.pump();

      // Each egg has an AppIcon (SVG)
      expect(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString().contains('AppIcon'),
        ),
        findsAtLeastNWidgets(2),
      );
    });
  });
}
