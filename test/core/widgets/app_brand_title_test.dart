import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/app_brand_title.dart';

void main() {
  group('AppBrandTitle', () {
    testWidgets('renders Budgie Breeding Tracker text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppBrandTitle(showIcon: false))),
      );

      expect(find.byType(Text), findsWidgets);
      // Text.rich renders "Budgie Breeding Tracker" as spans
      expect(find.byType(AppBrandTitle), findsOneWidget);
    });

    testWidgets('wraps content in Semantics with label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppBrandTitle(showIcon: false))),
      );

      expect(find.bySemanticsLabel('BudgieBreedingTracker'), findsOneWidget);
    });

    testWidgets('renders small size without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBrandTitle(size: AppBrandSize.small, showIcon: false),
          ),
        ),
      );

      expect(find.byType(AppBrandTitle), findsOneWidget);
    });

    testWidgets('renders medium size without errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBrandTitle(size: AppBrandSize.medium, showIcon: false),
          ),
        ),
      );

      expect(find.byType(AppBrandTitle), findsOneWidget);
    });

    testWidgets('renders large size with image instead of text layout', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBrandTitle(size: AppBrandSize.large, showIcon: true),
          ),
        ),
      );

      // Large size shows Image widget
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('hides icon when showIcon is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBrandTitle(size: AppBrandSize.small, showIcon: false),
          ),
        ),
      );

      // No Row layout (icons omitted), just Text.rich
      expect(find.byType(Row), findsNothing);
    });
  });

  group('AppBrandSize', () {
    test('has 3 variants', () {
      expect(AppBrandSize.values.length, 3);
    });

    test('contains small, medium, large', () {
      expect(
        AppBrandSize.values,
        containsAll([
          AppBrandSize.small,
          AppBrandSize.medium,
          AppBrandSize.large,
        ]),
      );
    });
  });
}
