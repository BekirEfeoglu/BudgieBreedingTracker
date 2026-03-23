import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/features/more/screens/user_guide_screen.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_data.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_topic_list_item.dart';

void main() {
  Widget createSubject() {
    return const MaterialApp(home: UserGuideScreen());
  }

  group('UserGuideScreen', () {
    testWidgets('renders AppBar with title key', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('user_guide.title'), findsOneWidget);
    });

    testWidgets('renders search bar with hint text key', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('user_guide.search_hint'), findsOneWidget);
    });

    testWidgets('renders category section headers as grouped cards', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Each category that has topics gets a Card widget
      final usedCategories = <GuideCategory>{};
      for (final topic in guideTopics) {
        usedCategories.add(topic.category);
      }

      // Should have at least one Card for grouped topics
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('renders GuideTopicListItem widgets', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(GuideTopicListItem), findsWidgets);
    });

    testWidgets('shows empty state when search has no results', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'xyzzzzzz_no_match_gibberish',
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('search filters topics and reduces visible items', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      final allItemCount = tester
          .widgetList(find.byType(GuideTopicListItem))
          .length;
      expect(allItemCount, greaterThan(0));

      // Enter the title key of the first topic to filter
      final firstTitleKey = guideTopics.first.titleKey;
      await tester.enterText(find.byType(TextField), firstTitleKey);
      await tester.pumpAndSettle();

      final filteredCount = tester
          .widgetList(find.byType(GuideTopicListItem))
          .length;
      expect(filteredCount, lessThan(allItemCount));
      expect(filteredCount, greaterThan(0));
    });

    testWidgets('no category headers shown when searching (flat list)', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Default: grouped mode has Card widgets
      expect(find.byType(Card), findsWidgets);

      // Enter search query
      final firstTitleKey = guideTopics.first.titleKey;
      await tester.enterText(find.byType(TextField), firstTitleKey);
      await tester.pumpAndSettle();

      // In search mode: flat list, no Card grouping
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('shows scrollable content list', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsWidgets);
    });
  });
}
