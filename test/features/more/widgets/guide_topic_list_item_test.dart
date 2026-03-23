import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_data.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_topic_list_item.dart';

GuideTopic _createTopic({
  String titleKey = 'test.title',
  String subtitleKey = 'test.subtitle',
  bool isPremium = false,
}) {
  return GuideTopic(
    titleKey: titleKey,
    subtitleKey: subtitleKey,
    iconAsset: AppIcons.bird,
    category: GuideCategory.gettingStarted,
    blocks: const [GuideBlock.text('test.block_text')],
    isPremium: isPremium,
  );
}

void main() {
  late bool tapped;

  setUp(() => tapped = false);

  Widget createSubject({
    GuideTopic? topic,
    bool showDivider = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: GuideTopicListItem(
          topic: topic ?? _createTopic(),
          onTap: () => tapped = true,
          showDivider: showDivider,
        ),
      ),
    );
  }

  group('GuideTopicListItem', () {
    testWidgets('renders topic title text', (tester) async {
      final topic = _createTopic(titleKey: 'some.topic_title');
      await tester.pumpWidget(createSubject(topic: topic));

      expect(find.text('some.topic_title'), findsOneWidget);
    });

    testWidgets('renders subtitle text key', (tester) async {
      final topic = _createTopic(subtitleKey: 'some.subtitle_key');
      await tester.pumpWidget(createSubject(topic: topic));

      expect(find.text('some.subtitle_key'), findsOneWidget);
    });

    testWidgets('renders chevron icon', (tester) async {
      await tester.pumpWidget(createSubject());

      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    });

    testWidgets('renders AppIcon widget', (tester) async {
      await tester.pumpWidget(createSubject());

      expect(find.byType(AppIcon), findsOneWidget);
    });

    testWidgets('shows premium badge when topic.isPremium is true',
        (tester) async {
      final topic = _createTopic(isPremium: true);
      await tester.pumpWidget(createSubject(topic: topic));

      expect(find.text('user_guide.premium_feature'), findsOneWidget);
    });

    testWidgets('hides premium badge when topic.isPremium is false',
        (tester) async {
      final topic = _createTopic(isPremium: false);
      await tester.pumpWidget(createSubject(topic: topic));

      expect(find.text('user_guide.premium_feature'), findsNothing);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      await tester.pumpWidget(createSubject());

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows divider when showDivider is true (default)',
        (tester) async {
      await tester.pumpWidget(createSubject(showDivider: true));

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('hides divider when showDivider is false', (tester) async {
      await tester.pumpWidget(createSubject(showDivider: false));

      expect(find.byType(Divider), findsNothing);
    });
  });
}
