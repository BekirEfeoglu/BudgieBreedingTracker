import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_data.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_topic_card.dart';

GuideTopic _createTopic({
  String titleKey = 'test.title',
  bool isPremium = false,
}) {
  return GuideTopic(
    titleKey: titleKey,
    iconAsset: AppIcons.bird,
    category: GuideCategory.gettingStarted,
    blocks: const [GuideBlock.text('test.block_text')],
    isPremium: isPremium,
  );
}

void main() {
  Widget createSubject(GuideTopic topic) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: GuideTopicCard(topic: topic)),
      ),
    );
  }

  group('GuideTopicCard', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(createSubject(_createTopic()));
      await tester.pump();

      expect(find.byType(GuideTopicCard), findsOneWidget);
    });

    testWidgets('shows topic title', (tester) async {
      await tester.pumpWidget(
        createSubject(_createTopic(titleKey: 'some.topic_title')),
      );
      await tester.pump();

      expect(find.text('some.topic_title'), findsOneWidget);
    });

    testWidgets('shows premium badge when isPremium is true', (tester) async {
      await tester.pumpWidget(createSubject(_createTopic(isPremium: true)));
      await tester.pump();

      expect(find.text('user_guide.premium_feature'), findsOneWidget);
    });

    testWidgets('does not show premium badge when isPremium is false', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(_createTopic(isPremium: false)));
      await tester.pump();

      expect(find.text('user_guide.premium_feature'), findsNothing);
    });

    testWidgets('renders ExpansionTile', (tester) async {
      await tester.pumpWidget(createSubject(_createTopic()));
      await tester.pump();

      expect(find.byType(ExpansionTile), findsOneWidget);
    });

    testWidgets('renders Card wrapper', (tester) async {
      await tester.pumpWidget(createSubject(_createTopic()));
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('expanding shows block content', (tester) async {
      await tester.pumpWidget(
        createSubject(_createTopic(titleKey: 'test.title')),
      );
      await tester.pump();

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // After expansion, the GuideBlockRenderer shows block text
      expect(find.text('test.block_text'), findsOneWidget);
    });
  });
}
