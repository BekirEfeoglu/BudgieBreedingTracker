import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_progress_phases.dart';

import '../../../../helpers/pump_helpers.dart';

void main() {
  group('AiProgressPhases', () {
    testWidgets('shows nothing when idle', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiProgressPhases(phase: AiAnalysisPhase.idle),
      );

      expect(find.byType(AiProgressPhases), findsOneWidget);
    });

    testWidgets('shows spinner when preparing', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiProgressPhases(phase: AiAnalysisPhase.preparing),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows spinner when analyzing', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiProgressPhases(phase: AiAnalysisPhase.analyzing),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows no spinner when complete', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiProgressPhases(phase: AiAnalysisPhase.complete),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error icon on error phase', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiProgressPhases(phase: AiAnalysisPhase.error),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('elapsed counter Text appears while analyzing', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        const AiProgressPhases(phase: AiAnalysisPhase.analyzing),
      );

      final elapsedFinder = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.style?.fontFeatures ?? const <FontFeature>[])
                .contains(const FontFeature.tabularFigures()),
      );

      expect(elapsedFinder, findsNothing, reason: 'no label before 1s tick');

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        elapsedFinder,
        findsOneWidget,
        reason: 'elapsed counter should render after 1 second',
      );
    });

    testWidgets('elapsed counter clears when phase leaves active state', (
      tester,
    ) async {
      final key = GlobalKey();
      await pumpWidgetSimple(
        tester,
        AiProgressPhases(key: key, phase: AiAnalysisPhase.analyzing),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 50));

      await pumpWidgetSimple(
        tester,
        AiProgressPhases(key: key, phase: AiAnalysisPhase.complete),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final elapsedFinder = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.style?.fontFeatures ?? const <FontFeature>[])
                .contains(const FontFeature.tabularFigures()),
      );
      expect(
        elapsedFinder,
        findsNothing,
        reason: 'elapsed counter must clear after completion',
      );
    });
  });
}
