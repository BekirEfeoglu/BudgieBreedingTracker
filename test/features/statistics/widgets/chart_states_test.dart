import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/widgets/skeleton_loader.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_states.dart';

import '../../../helpers/test_localization.dart';

void main() {
  group('ChartLoading', () {
    testWidgets('renders bar chart skeleton by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ChartLoading())),
      );

      expect(find.byType(ChartLoading), findsOneWidget);
      expect(find.byType(SkeletonLoader), findsWidgets);
    });

    testWidgets('renders pie chart skeleton when isPieChart is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChartLoading(isPieChart: true)),
        ),
      );

      expect(find.byType(ChartLoading), findsOneWidget);
      expect(find.byType(SkeletonLoader), findsWidgets);
    });

    testWidgets('renders line chart skeleton when isLineChart is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChartLoading(isLineChart: true)),
        ),
      );

      expect(find.byType(ChartLoading), findsOneWidget);
      // Line skeleton uses CustomPaint
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('ChartError', () {
    testWidgets('renders error message', (tester) async {
      await pumpTranslatedWidget(
        tester,
        const ChartError(message: 'Something went wrong'),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry is provided',
        (tester) async {
      await pumpTranslatedWidget(
        tester,
        ChartError(message: 'Error', onRetry: () {}),
      );

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text(resolvedL10n('common.retry')), findsOneWidget);
    });

    testWidgets('does not show retry button when onRetry is null',
        (tester) async {
      await pumpTranslatedWidget(
        tester,
        const ChartError(message: 'Error'),
      );

      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('taps retry callback', (tester) async {
      var retryTapped = false;
      await pumpTranslatedWidget(
        tester,
        ChartError(message: 'Error', onRetry: () => retryTapped = true),
      );

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(retryTapped, isTrue);
    });
  });

  group('ChartEmpty', () {
    testWidgets('renders default no data message', (tester) async {
      await pumpTranslatedWidget(tester, const ChartEmpty());

      expect(find.text(resolvedL10n('statistics.no_data')), findsOneWidget);
      expect(find.text(resolvedL10n('statistics.no_data_hint')), findsOneWidget);
    });

    testWidgets('renders custom message when provided', (tester) async {
      await pumpTranslatedWidget(
        tester,
        const ChartEmpty(message: 'Custom empty message'),
      );

      expect(find.text('Custom empty message'), findsOneWidget);
      expect(find.text(resolvedL10n('statistics.no_data_hint')), findsOneWidget);
    });

    testWidgets('has correct height', (tester) async {
      await pumpTranslatedWidget(tester, const ChartEmpty());

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(ChartEmpty),
          matching: find.byType(SizedBox).first,
        ),
      );
      expect(sizedBox.height, 200);
    });
  });

  group('ChartLowData', () {
    testWidgets('wraps child widget with info banner', (tester) async {
      await pumpTranslatedWidget(
        tester,
        const ChartLowData(child: Text('Chart content')),
      );

      expect(find.text(resolvedL10n('statistics.low_data_hint')), findsOneWidget);
      expect(find.text('Chart content'), findsOneWidget);
    });

    testWidgets('shows action button when onAction is provided',
        (tester) async {
      await pumpTranslatedWidget(
        tester,
        ChartLowData(
          onAction: () {},
          child: const Text('Chart'),
        ),
      );

      expect(find.text(resolvedL10n('common.add')), findsOneWidget);
    });

    testWidgets('shows custom action label', (tester) async {
      await pumpTranslatedWidget(
        tester,
        ChartLowData(
          onAction: () {},
          actionLabel: 'custom.action',
          child: const Text('Chart'),
        ),
      );

      expect(find.text('custom.action'), findsOneWidget);
    });

    testWidgets('taps action callback', (tester) async {
      var tapped = false;
      await pumpTranslatedWidget(
        tester,
        ChartLowData(
          onAction: () => tapped = true,
          child: const Text('Chart'),
        ),
      );

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('hides action button when onAction is null', (tester) async {
      await pumpTranslatedWidget(
        tester,
        const ChartLowData(child: Text('Chart')),
      );

      expect(find.byType(TextButton), findsNothing);
    });
  });
}
