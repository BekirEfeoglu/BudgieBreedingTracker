import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/skeleton_loader.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_trend_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/quick_insights_card.dart';

const _testUserId = 'test-user';

Widget _createSubject({
  AsyncValue<List<QuickInsight>> insightsAsync = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue(_testUserId),
      quickInsightsProvider(_testUserId).overrideWithValue(insightsAsync),
    ],
    child: const MaterialApp(home: Scaffold(body: QuickInsightsCard())),
  );
}

void main() {
  group('QuickInsightsCard', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(QuickInsightsCard), findsOneWidget);
    });

    testWidgets('shows skeleton loader while loading', (tester) async {
      await tester.pumpWidget(
        _createSubject(insightsAsync: const AsyncLoading()),
      );
      await tester.pump();

      // Loading → skeleton card with SkeletonLoader placeholders
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(SkeletonLoader), findsWidgets);
    });

    testWidgets('shows nothing on error', (tester) async {
      await tester.pumpWidget(
        _createSubject(
          insightsAsync: const AsyncError('Error', StackTrace.empty),
        ),
      );
      await tester.pump();

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('shows nothing with empty insights list', (tester) async {
      await tester.pumpWidget(
        _createSubject(insightsAsync: const AsyncData([])),
      );
      await tester.pump();

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('shows card when insights are available', (tester) async {
      const insights = [
        QuickInsight(
          text: 'Your birds are thriving!',
          sentiment: InsightSentiment.positive,
        ),
      ];

      await tester.pumpWidget(
        _createSubject(insightsAsync: const AsyncData(insights)),
      );
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Your birds are thriving!'), findsOneWidget);
    });

    testWidgets('shows insights title', (tester) async {
      const insights = [
        QuickInsight(text: 'Insight text', sentiment: InsightSentiment.neutral),
      ];

      await tester.pumpWidget(
        _createSubject(insightsAsync: const AsyncData(insights)),
      );
      await tester.pump();

      expect(find.text('statistics.insights_title'), findsOneWidget);
    });

    testWidgets('skeleton does not show insight text', (tester) async {
      await tester.pumpWidget(
        _createSubject(insightsAsync: const AsyncLoading()),
      );
      await tester.pump();

      expect(find.byType(SkeletonLoader), findsWidgets);
      expect(find.text('statistics.insights_title'), findsNothing);
    });

    testWidgets('data state does not show skeleton', (tester) async {
      const insights = [
        QuickInsight(
          text: 'Active insight',
          sentiment: InsightSentiment.positive,
        ),
      ];

      await tester.pumpWidget(
        _createSubject(insightsAsync: const AsyncData(insights)),
      );
      await tester.pump();

      expect(find.text('Active insight'), findsOneWidget);
      expect(find.byType(SkeletonLoader), findsNothing);
    });

    testWidgets('shows multiple insights', (tester) async {
      const insights = [
        QuickInsight(
          text: 'First insight',
          sentiment: InsightSentiment.positive,
        ),
        QuickInsight(
          text: 'Second insight',
          sentiment: InsightSentiment.negative,
        ),
        QuickInsight(
          text: 'Third insight',
          sentiment: InsightSentiment.neutral,
        ),
      ];

      await tester.pumpWidget(
        _createSubject(insightsAsync: const AsyncData(insights)),
      );
      await tester.pump();

      expect(find.text('First insight'), findsOneWidget);
      expect(find.text('Second insight'), findsOneWidget);
      expect(find.text('Third insight'), findsOneWidget);
    });
  });
}
