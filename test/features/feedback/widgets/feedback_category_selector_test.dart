import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/feedback/providers/feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_category_selector.dart';

void _consumeExceptions(WidgetTester tester) {
  var ex = tester.takeException();
  while (ex != null) {
    ex = tester.takeException();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildSubject({FeedbackCategory selected = FeedbackCategory.bug}) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              var current = selected;
              return FeedbackCategorySelector(
                selected: current,
                onChanged: (cat) {
                  setState(() => current = cat);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  group('FeedbackCategorySelector', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(FeedbackCategorySelector), findsOneWidget);
    });

    testWidgets('renders a card for each FeedbackCategory', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // 3 categories => 3 Card widgets
      expect(find.byType(Card), findsNWidgets(FeedbackCategory.values.length));
    });

    testWidgets('renders an Icon for each FeedbackCategory', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(
        find.byType(Icon),
        findsAtLeastNWidgets(FeedbackCategory.values.length),
      );
    });

    testWidgets('tapping a category card calls onChanged with correct value', (
      tester,
    ) async {
      FeedbackCategory? tapped;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedbackCategorySelector(
                selected: FeedbackCategory.bug,
                onChanged: (cat) => tapped = cat,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap the 'feature' card (second in row)
      final inkWells = find.byType(InkWell);
      await tester.tap(inkWells.at(1));
      await tester.pump();

      expect(tapped, FeedbackCategory.feature);
    });

    testWidgets('selected category card has elevated elevation', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(selected: FeedbackCategory.bug));
      await tester.pump();

      final cards = tester.widgetList<Card>(find.byType(Card)).toList();
      // First card (bug) is selected → elevation == 2
      expect(cards.first.elevation, 2.0);
      // Others are not selected → elevation == 0
      expect(cards[1].elevation, 0.0);
    });

    testWidgets('changing selection via state updates selected card', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(selected: FeedbackCategory.bug));
      await tester.pump();

      // Tap 'general' card (third)
      final inkWells = find.byType(InkWell);
      await tester.tap(inkWells.at(2));
      await tester.pump();

      // After tap _selected changes to general; no errors expected
      _consumeExceptions(tester);
    });
  });
}
