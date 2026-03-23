import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/features/more/screens/guide_detail_screen.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_content_widgets.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_data.dart';

void main() {
  Widget createSubject({required int topicIndex}) {
    return MaterialApp(home: GuideDetailScreen(topicIndex: topicIndex));
  }

  group('GuideDetailScreen', () {
    testWidgets('renders topic title in AppBar', (tester) async {
      // guideTopics[0] = registration
      await tester.pumpWidget(createSubject(topicIndex: 0));
      await tester.pumpAndSettle();

      // Without EasyLocalization, .tr() returns the key itself
      expect(
        find.text(guideTopics[0].titleKey),
        findsOneWidget,
      );
    });

    testWidgets('renders category label (uppercase) in header', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(topicIndex: 0));
      await tester.pumpAndSettle();

      // Category labelKey is returned as-is by .tr() without localization
      final expectedLabel =
          guideTopics[0].category.labelKey.toUpperCase();
      expect(find.text(expectedLabel), findsOneWidget);
    });

    testWidgets('renders step count when topic has steps', (tester) async {
      // guideTopics[0] = registration, has 4 steps
      await tester.pumpWidget(createSubject(topicIndex: 0));
      await tester.pumpAndSettle();

      // .tr() without localization returns the key; step_count uses args
      // so it returns 'user_guide.step_count' as the key
      expect(
        find.textContaining('user_guide.step_count'),
        findsOneWidget,
      );
    });

    testWidgets('hides step count when topic has no steps', (tester) async {
      // guideTopics[1] = dashboard, has 0 steps
      expect(guideTopics[1].stepCount, 0);

      await tester.pumpWidget(createSubject(topicIndex: 1));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('user_guide.step_count'),
        findsNothing,
      );
    });

    testWidgets('renders GuideBlockRenderer', (tester) async {
      await tester.pumpWidget(createSubject(topicIndex: 0));
      await tester.pumpAndSettle();

      expect(find.byType(GuideBlockRenderer), findsOneWidget);
    });

    testWidgets('renders related topics section when relatedTopicIndices '
        'is non-empty', (tester) async {
      // guideTopics[0] has relatedTopicIndices: [1, 2]
      expect(guideTopics[0].relatedTopicIndices, isNotEmpty);

      await tester.pumpWidget(createSubject(topicIndex: 0));
      await tester.pumpAndSettle();

      expect(
        find.text('user_guide.related_topics'.toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets('hides related topics section when relatedTopicIndices '
        'is empty', (tester) async {
      // guideTopics[9] = calendar_notifications, has empty related
      expect(guideTopics[9].relatedTopicIndices, isEmpty);

      await tester.pumpWidget(createSubject(topicIndex: 9));
      await tester.pumpAndSettle();

      expect(
        find.text('user_guide.related_topics'.toUpperCase()),
        findsNothing,
      );
    });

    testWidgets('related topics show correct topic titles', (tester) async {
      // guideTopics[0] has relatedTopicIndices: [1, 2]
      await tester.pumpWidget(createSubject(topicIndex: 0));
      await tester.pumpAndSettle();

      // Related topics should show the titles of topics at indices 1 and 2
      // Since .tr() returns key without localization, we check for titleKey
      expect(find.text(guideTopics[1].titleKey), findsOneWidget);
      expect(find.text(guideTopics[2].titleKey), findsOneWidget);
    });
  });
}
