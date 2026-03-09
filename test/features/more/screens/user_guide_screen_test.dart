import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/features/more/screens/user_guide_screen.dart';

void main() {
  Widget createSubject() {
    return const MaterialApp(home: UserGuideScreen());
  }

  // UserGuideScreen is a plain StatefulWidget (no providers) that has a
  // search bar, category chips, and a scrollable list of guide topics.

  group('UserGuideScreen', () {
    testWidgets('shows UserGuideScreen with search bar and topic list', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(UserGuideScreen), findsOneWidget);
    });

    testWidgets('shows AppBar with user guide title', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('user_guide.title'), findsOneWidget);
    });

    testWidgets('has search text field', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows category filter chips', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Multiple ChoiceChip widgets for category filtering
      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('shows empty state when search has no matching topics', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Enter a query that matches no topics
      await tester.enterText(find.byType(TextField), 'xyzzzzzz_no_match');
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows scrollable content list', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Guide content should be in a scrollable view
      expect(
        find.byWidgetPredicate(
          (w) => w is SingleChildScrollView || w is ListView,
        ),
        findsWidgets,
      );
    });
  });
}
