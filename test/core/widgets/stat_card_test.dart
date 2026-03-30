import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/widgets/cards/stat_card.dart';

void main() {
  group('StatCard', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(label: 'Total Birds', value: 'N/A'),
          ),
        ),
      );

      expect(find.text('Total Birds'), findsOneWidget);
    });

    testWidgets('renders non-numeric value directly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(label: 'Status', value: 'N/A'),
          ),
        ),
      );

      expect(find.text('N/A'), findsOneWidget);
    });

    testWidgets('renders icon widget when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              label: 'Eggs',
              value: 'N/A',
              icon: Icon(Icons.egg_alt),
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('does not render icon when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(label: 'Birds', value: 'N/A'),
          ),
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              label: 'Birds',
              value: 'N/A',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StatCard));
      expect(tapped, isTrue);
    });

    testWidgets('does not throw when onTap is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(label: 'Birds', value: 'N/A'),
          ),
        ),
      );

      await tester.tap(find.byType(StatCard));
      await tester.pump();
    });

    testWidgets('uses Card widget for layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(label: 'Test', value: 'N/A'),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders with custom color without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(label: 'Births', value: 'N/A', color: Colors.green),
          ),
        ),
      );

      expect(find.text('Births'), findsOneWidget);
    });

    testWidgets('shows positive trend with plus sign', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              label: 'Birds',
              value: '10',
              trendPercent: 25.0,
              trendUp: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+25%'), findsOneWidget);
    });

    testWidgets('shows negative trend without double minus sign',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              label: 'Birds',
              value: '10',
              trendPercent: -25.0,
              trendUp: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show "-25%" not "--25%"
      expect(find.text('-25%'), findsOneWidget);
      expect(find.text('--25%'), findsNothing);
    });

    testWidgets('shows zero trend as stable text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              label: 'Birds',
              value: '10',
              trendPercent: 0.0,
              trendUp: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // percent == 0 shows 'statistics.trend_stable' key
      expect(find.text(l10n('statistics.trend_stable')), findsOneWidget);
    });
  });
}
