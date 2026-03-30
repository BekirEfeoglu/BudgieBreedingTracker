import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/widgets/skeleton_loader.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  group('ChartCard', () {
    testWidgets('renders Card widget', (tester) async {
      await pumpWidgetSimple(
        tester,
        const ChartCard(
          title: 'Test Title',
          icon: Icon(Icons.bar_chart),
          child: Text('Chart Content'),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('displays title text', (tester) async {
      await pumpWidgetSimple(
        tester,
        const ChartCard(
          title: 'Bird Statistics',
          icon: Icon(Icons.bar_chart),
          child: SizedBox.shrink(),
        ),
      );

      expect(find.text('Bird Statistics'), findsOneWidget);
    });

    testWidgets('displays subtitle when provided', (tester) async {
      await pumpWidgetSimple(
        tester,
        const ChartCard(
          title: 'Title',
          subtitle: 'Last 3 months',
          icon: Icon(Icons.bar_chart),
          child: SizedBox.shrink(),
        ),
      );

      expect(find.text('Last 3 months'), findsOneWidget);
    });

    testWidgets('hides subtitle when not provided', (tester) async {
      await pumpWidgetSimple(
        tester,
        const ChartCard(
          title: 'Title',
          icon: Icon(Icons.bar_chart),
          child: SizedBox.shrink(),
        ),
      );

      expect(find.text('Last 3 months'), findsNothing);
    });

    testWidgets('renders child widget', (tester) async {
      await pumpWidgetSimple(
        tester,
        const ChartCard(
          title: 'Title',
          icon: Icon(Icons.bar_chart),
          child: Text('Chart goes here'),
        ),
      );

      expect(find.text('Chart goes here'), findsOneWidget);
    });
  });

  group('ChartLoading', () {
    testWidgets('shows skeleton loaders', (tester) async {
      await pumpWidgetSimple(tester, const ChartLoading());

      expect(find.byType(SkeletonLoader), findsWidgets);
    });

    testWidgets('renders in a SizedBox', (tester) async {
      await pumpWidgetSimple(tester, const ChartLoading());

      expect(find.byType(SizedBox), findsWidgets);
    });
  });

  group('ChartError', () {
    testWidgets('displays error message', (tester) async {
      await pumpWidgetSimple(
        tester,
        const ChartError(message: 'Failed to load data'),
      );

      expect(find.text('Failed to load data'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      await pumpWidgetSimple(
        tester,
        ChartError(message: 'Error', onRetry: () {}),
      );

      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await pumpWidgetSimple(tester, const ChartError(message: 'Error'));

      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('calls onRetry when retry button is tapped', (tester) async {
      var retried = false;

      await pumpWidgetSimple(
        tester,
        ChartError(message: 'Error', onRetry: () => retried = true),
      );

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(retried, isTrue);
    });
  });

  group('ChartCard dataCount / ChartLowData', () {
    testWidgets('shows low data banner when dataCount > 0 and < threshold', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        const ChartCard(
          title: 'Test',
          icon: Icon(Icons.bar_chart),
          dataCount: 1,
          child: Text('Chart'),
        ),
      );

      expect(find.text(l10n('statistics.low_data_hint')), findsOneWidget);
      expect(find.text('Chart'), findsOneWidget);
    });

    testWidgets('hides low data banner when dataCount >= threshold', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        const ChartCard(
          title: 'Test',
          icon: Icon(Icons.bar_chart),
          dataCount: 5,
          child: Text('Chart'),
        ),
      );

      expect(find.text(l10n('statistics.low_data_hint')), findsNothing);
      expect(find.text('Chart'), findsOneWidget);
    });

    testWidgets('hides low data banner when dataCount is null', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        const ChartCard(
          title: 'Test',
          icon: Icon(Icons.bar_chart),
          child: Text('Chart'),
        ),
      );

      expect(find.text(l10n('statistics.low_data_hint')), findsNothing);
    });

    testWidgets('hides low data banner when dataCount is 0', (tester) async {
      await pumpWidgetSimple(
        tester,
        const ChartCard(
          title: 'Test',
          icon: Icon(Icons.bar_chart),
          dataCount: 0,
          child: Text('Chart'),
        ),
      );

      expect(find.text(l10n('statistics.low_data_hint')), findsNothing);
    });

    testWidgets('respects custom lowDataThreshold', (tester) async {
      await pumpWidgetSimple(
        tester,
        const ChartCard(
          title: 'Test',
          icon: Icon(Icons.bar_chart),
          dataCount: 4,
          lowDataThreshold: 5,
          child: Text('Chart'),
        ),
      );

      expect(find.text(l10n('statistics.low_data_hint')), findsOneWidget);
    });
  });

  group('ChartEmpty', () {
    testWidgets('shows default l10n message when no custom message', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, const ChartEmpty());

      expect(find.text(l10n('statistics.no_data')), findsOneWidget);
      expect(find.text(l10n('statistics.no_data_hint')), findsOneWidget);
    });

    testWidgets('shows custom message when provided', (tester) async {
      await pumpWidgetSimple(
        tester,
        const ChartEmpty(message: 'No eggs recorded yet'),
      );

      expect(find.text('No eggs recorded yet'), findsOneWidget);
    });
  });
}
