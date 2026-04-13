import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_quick_tags.dart';

import '../../../../helpers/pump_helpers.dart';

void main() {
  group('AiQuickTags', () {
    testWidgets('renders all 6 default tags', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiQuickTags(
          selectedTags: const {},
          onTagToggled: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilterChip), findsNWidgets(6));
    });

    testWidgets('highlights selected tags', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiQuickTags(
          selectedTags: const {'genetics.ai_tag_blue_cere'},
          onTagToggled: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip)).toList();
      expect(chips[0].selected, isTrue);
      expect(chips[1].selected, isFalse);
    });

    testWidgets('calls onTagToggled with correct tag key', (tester) async {
      String? tappedTag;
      await pumpWidgetSimple(
        tester,
        AiQuickTags(
          selectedTags: const {},
          onTagToggled: (tag) => tappedTag = tag,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilterChip).first);
      expect(tappedTag, equals('genetics.ai_tag_blue_cere'));
    });

    testWidgets('multiple tags can be selected', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiQuickTags(
          selectedTags: const {
            'genetics.ai_tag_blue_cere',
            'genetics.ai_tag_young_bird',
          },
          onTagToggled: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip)).toList();
      expect(chips[0].selected, isTrue);  // blue_cere
      expect(chips[1].selected, isFalse); // brown_cere
      expect(chips[2].selected, isTrue);  // young_bird
    });

    testWidgets('empty selectedTags shows all unselected', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiQuickTags(
          selectedTags: const {},
          onTagToggled: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      for (final chip in chips) {
        expect(chip.selected, isFalse);
      }
    });

    testWidgets('tapping second tag returns correct key', (tester) async {
      String? tappedTag;
      await pumpWidgetSimple(
        tester,
        AiQuickTags(
          selectedTags: const {},
          onTagToggled: (tag) => tappedTag = tag,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilterChip).at(1));
      expect(tappedTag, equals('genetics.ai_tag_brown_cere'));
    });
  });
}
