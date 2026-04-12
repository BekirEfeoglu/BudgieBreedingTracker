import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import 'package:budgie_breeding_tracker/core/widgets/skeleton_loader.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_states.dart';

void main() {
  group('ChartLoading (bar skeleton)', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ChartLoading())),
      );

      expect(find.byType(ChartLoading), findsOneWidget);
    });

    testWidgets('contains SkeletonLoader widgets', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ChartLoading())),
      );

      expect(find.byType(SkeletonLoader), findsWidgets);
    });
  });

  group('ChartLoading (pie skeleton)', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChartLoading(isPieChart: true)),
        ),
      );

      expect(find.byType(ChartLoading), findsOneWidget);
    });

    testWidgets('contains SkeletonLoader widgets for pie variant',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChartLoading(isPieChart: true)),
        ),
      );

      // Pie skeleton has a circular SkeletonLoader and legend loaders
      expect(find.byType(SkeletonLoader), findsWidgets);
    });
  });

  group('ChartLoading (line skeleton)', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChartLoading(isLineChart: true)),
        ),
      );

      expect(find.byType(ChartLoading), findsOneWidget);
    });

    testWidgets('uses RepaintBoundary for performance', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChartLoading(isLineChart: true)),
        ),
      );

      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('uses Shimmer animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChartLoading(isLineChart: true)),
        ),
      );

      expect(find.byType(Shimmer), findsWidgets);
    });

    testWidgets('contains CustomPaint for line drawing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ChartLoading(isLineChart: true)),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
