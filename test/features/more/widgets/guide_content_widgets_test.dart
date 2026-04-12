import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/more/widgets/guide_content_widgets.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_data.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('GuideTipBox', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(const GuideTipBox(textKey: 'user_guide.tip_key')),
      );
      await tester.pump();

      expect(find.byType(GuideTipBox), findsOneWidget);
    });

    testWidgets('renders Container with border decoration', (tester) async {
      await tester.pumpWidget(
        _wrap(const GuideTipBox(textKey: 'user_guide.tip_key')),
      );
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Row layout', (tester) async {
      await tester.pumpWidget(
        _wrap(const GuideTipBox(textKey: 'user_guide.tip_key')),
      );
      await tester.pump();

      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });
  });

  group('GuideWarningBox', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(const GuideWarningBox(textKey: 'user_guide.warning_key')),
      );
      await tester.pump();

      expect(find.byType(GuideWarningBox), findsOneWidget);
    });

    testWidgets('renders Container with border decoration', (tester) async {
      await tester.pumpWidget(
        _wrap(const GuideWarningBox(textKey: 'user_guide.warning_key')),
      );
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Row layout', (tester) async {
      await tester.pumpWidget(
        _wrap(const GuideWarningBox(textKey: 'user_guide.warning_key')),
      );
      await tester.pump();

      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });
  });

  group('GuidePremiumNote', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(const GuidePremiumNote(textKey: 'user_guide.premium_note')),
      );
      await tester.pump();

      expect(find.byType(GuidePremiumNote), findsOneWidget);
    });

    testWidgets('shows textKey content', (tester) async {
      await tester.pumpWidget(
        _wrap(const GuidePremiumNote(textKey: 'user_guide.premium_note')),
      );
      await tester.pump();

      expect(find.text('user_guide.premium_note'), findsOneWidget);
    });

    testWidgets('renders Row layout', (tester) async {
      await tester.pumpWidget(
        _wrap(const GuidePremiumNote(textKey: 'user_guide.prem_key')),
      );
      await tester.pump();

      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });
  });

  group('GuideStepList', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GuideStepList(
            titleKey: 'user_guide.steps_title',
            stepKeys: ['user_guide.step_1', 'user_guide.step_2'],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GuideStepList), findsOneWidget);
    });

    testWidgets('shows title text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GuideStepList(
            titleKey: 'user_guide.my_title',
            stepKeys: ['step.one'],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('user_guide.my_title'), findsOneWidget);
    });

    testWidgets('shows step number circles', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GuideStepList(
            titleKey: 'user_guide.title',
            stepKeys: ['step.one', 'step.two', 'step.three'],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows step text content', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GuideStepList(
            titleKey: 'user_guide.title',
            stepKeys: ['user_guide.step_one'],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('user_guide.step_one'), findsOneWidget);
    });

    testWidgets('shows CircleAvatar for each step', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GuideStepList(
            titleKey: 'user_guide.title',
            stepKeys: ['step.a', 'step.b'],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircleAvatar), findsNWidgets(2));
    });
  });

  group('GuideBlockRenderer', () {
    testWidgets('renders empty block list without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const GuideBlockRenderer(blocks: [])));
      await tester.pump();

      expect(find.byType(GuideBlockRenderer), findsOneWidget);
    });

    testWidgets('renders text block', (tester) async {
      const blocks = [GuideBlock.text('user_guide.some_text')];
      await tester.pumpWidget(_wrap(const GuideBlockRenderer(blocks: blocks)));
      await tester.pump();

      expect(find.text('user_guide.some_text'), findsOneWidget);
    });

    testWidgets('renders tip block as GuideTipBox', (tester) async {
      const blocks = [GuideBlock.tip('user_guide.tip_text')];
      await tester.pumpWidget(_wrap(const GuideBlockRenderer(blocks: blocks)));
      await tester.pump();

      expect(find.byType(GuideTipBox), findsOneWidget);
    });

    testWidgets('renders warning block as GuideWarningBox', (tester) async {
      const blocks = [GuideBlock.warning('user_guide.warn_text')];
      await tester.pumpWidget(_wrap(const GuideBlockRenderer(blocks: blocks)));
      await tester.pump();

      expect(find.byType(GuideWarningBox), findsOneWidget);
    });

    testWidgets('renders premiumNote block as GuidePremiumNote', (
      tester,
    ) async {
      const blocks = [GuideBlock.premiumNote('user_guide.prem_text')];
      await tester.pumpWidget(_wrap(const GuideBlockRenderer(blocks: blocks)));
      await tester.pump();

      expect(find.byType(GuidePremiumNote), findsOneWidget);
    });

    testWidgets('renders steps block as GuideStepList', (tester) async {
      const blocks = [
        GuideBlock.steps(
          stepsTitle: 'user_guide.title',
          stepKeys: ['step.one'],
        ),
      ];
      await tester.pumpWidget(_wrap(const GuideBlockRenderer(blocks: blocks)));
      await tester.pump();

      expect(find.byType(GuideStepList), findsOneWidget);
    });

    testWidgets('renders multiple blocks of different types', (tester) async {
      const blocks = [
        GuideBlock.text('user_guide.text_block'),
        GuideBlock.tip('user_guide.tip_block'),
        GuideBlock.warning('user_guide.warn_block'),
      ];
      await tester.pumpWidget(_wrap(const GuideBlockRenderer(blocks: blocks)));
      await tester.pump();

      expect(find.byType(GuideTipBox), findsOneWidget);
      expect(find.byType(GuideWarningBox), findsOneWidget);
    });
  });
}
