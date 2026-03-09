import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/premium/widgets/feature_comparison.dart';

void main() {
  Widget createSubject() {
    return const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: FeatureComparison())),
    );
  }

  group('FeatureComparison', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(FeatureComparison), findsOneWidget);
    });

    testWidgets('shows comparison title', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('premium.comparison_title'), findsOneWidget);
    });

    testWidgets('shows feature column header', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('premium.feature'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows free column header', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('premium.free'), findsOneWidget);
    });

    testWidgets('shows pro column header', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('premium.pro'), findsOneWidget);
    });

    testWidgets('renders Column as root', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });

    testWidgets('shows feature rows for all features', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      // 10 features defined in _features list
      expect(find.text('premium.feature_bird_tracking'), findsOneWidget);
      expect(find.text('premium.feature_genealogy'), findsOneWidget);
    });

    testWidgets('shows check icons for available features', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(Icon), findsAtLeastNWidgets(1));
    });
  });
}
