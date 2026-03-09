import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    testWidgets('shows CircularProgressIndicator', (tester) async {
      await pumpWidgetSimple(tester, const ChartLoading());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
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

  group('ChartEmpty', () {
    testWidgets('shows default l10n message when no custom message', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, const ChartEmpty());

      expect(find.text('statistics.no_data'), findsOneWidget);
      expect(find.text('statistics.no_data_hint'), findsOneWidget);
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
