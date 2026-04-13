import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/widgets/skeleton_loader.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_result_section.dart';

import '../../../../helpers/pump_helpers.dart';

void main() {
  group('AiResultSection', () {
    testWidgets('renders title and summary', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiResultSection(
          title: 'Test Title',
          confidence: LocalAiConfidence.high,
          summary: 'Test summary text',
          bullets: ['Bullet 1', 'Bullet 2'],
        ),
      );
      await tester.pump();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test summary text'), findsOneWidget);
    });

    testWidgets('renders bullet points', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiResultSection(
          title: 'Title',
          confidence: LocalAiConfidence.medium,
          summary: 'Summary',
          bullets: ['First', 'Second', 'Third'],
        ),
      );
      await tester.pump();

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);
    });

    testWidgets('filters empty bullets', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiResultSection(
          title: 'Title',
          confidence: LocalAiConfidence.low,
          summary: 'Summary',
          bullets: ['Valid', '', '  ', 'Also valid'],
        ),
      );
      await tester.pump();

      expect(find.text('Valid'), findsOneWidget);
      expect(find.text('Also valid'), findsOneWidget);
    });

    testWidgets('hides summary when empty', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiResultSection(
          title: 'Title',
          confidence: LocalAiConfidence.high,
          summary: '',
          bullets: ['Bullet'],
        ),
      );
      await tester.pump();

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Bullet'), findsOneWidget);
    });

    testWidgets('renders with all confidence levels', (tester) async {
      for (final confidence in LocalAiConfidence.values) {
        await pumpWidgetSimple(
          tester,
          AiResultSection(
            title: 'Title',
            confidence: confidence,
            summary: 'Summary',
            bullets: const ['Bullet'],
          ),
        );
        await tester.pump();

        expect(find.byType(AiResultSection), findsOneWidget);
      }
    });
  });

  group('AiAnimatedResultSlot', () {
    testWidgets('shows nothing when no content', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiAnimatedResultSlot(
          isLoading: false,
          hasError: false,
        ),
      );
      await tester.pump();

      expect(find.byType(AiInsightSkeleton), findsNothing);
      expect(find.byType(AiErrorBox), findsNothing);
    });

    testWidgets('shows skeleton when loading', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiAnimatedResultSlot(
          isLoading: true,
          hasError: false,
        ),
      );
      await tester.pump();

      expect(find.byType(AiInsightSkeleton), findsOneWidget);
    });

    testWidgets('shows error box when hasError', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiAnimatedResultSlot(
          isLoading: false,
          hasError: true,
          errorMessage: 'Something went wrong',
        ),
      );
      await tester.pump();

      expect(find.byType(AiErrorBox), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows child when provided', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiAnimatedResultSlot(
          isLoading: false,
          hasError: false,
          child: Text('Result content'),
        ),
      );
      await tester.pump();

      expect(find.text('Result content'), findsOneWidget);
    });
  });

  group('AiInsightSkeleton', () {
    testWidgets('renders skeleton loaders', (tester) async {
      await pumpWidgetSimple(tester, const AiInsightSkeleton());
      await tester.pump();

      expect(find.byType(SkeletonLoader), findsWidgets);
    });
  });

  group('AiErrorBox', () {
    testWidgets('renders error message', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiErrorBox(message: 'Test error message'),
      );
      await tester.pump();

      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('renders empty message', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiErrorBox(message: ''),
      );
      await tester.pump();

      expect(find.byType(AiErrorBox), findsOneWidget);
    });
  });
}
