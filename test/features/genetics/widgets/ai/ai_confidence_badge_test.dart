import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_confidence_badge.dart';

import '../../../../helpers/pump_helpers.dart';

void main() {
  group('AiConfidenceBadge', () {
    for (final confidence in LocalAiConfidence.values) {
      testWidgets('renders for ${confidence.name}', (tester) async {
        await pumpWidgetSimple(
          tester,
          AiConfidenceBadge(confidence: confidence),
        );
        await tester.pump();

        expect(find.byType(AiConfidenceBadge), findsOneWidget);
        expect(find.byType(Icon), findsOneWidget);
      });
    }

    testWidgets('shows text label for high confidence', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiConfidenceBadge(confidence: LocalAiConfidence.high),
      );
      await tester.pump();

      // Should find a Text widget inside the badge (the label)
      final badge = find.byType(AiConfidenceBadge);
      expect(badge, findsOneWidget);
      final texts = find.descendant(of: badge, matching: find.byType(Text));
      expect(texts, findsOneWidget);
    });

    testWidgets('has colored container decoration', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiConfidenceBadge(confidence: LocalAiConfidence.medium),
      );
      await tester.pump();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AiConfidenceBadge),
          matching: find.byType(Container),
        ),
      );
      expect(container.decoration, isA<BoxDecoration>());
    });

    testWidgets('low and high have different icons', (tester) async {
      await pumpWidgetSimple(
        tester,
        const Column(
          children: [
            AiConfidenceBadge(confidence: LocalAiConfidence.low),
            AiConfidenceBadge(confidence: LocalAiConfidence.high),
          ],
        ),
      );
      await tester.pump();

      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons.length, 2);
      expect(icons[0].icon, isNot(equals(icons[1].icon)));
    });
  });
}
