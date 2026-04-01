import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/widgets/cards/stat_card.dart';

void main() {
  group('StatCard', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatCard(label: 'Birds', value: '42')),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Birds'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              label: 'Birds',
              value: '10',
              icon: Icon(Icons.pets),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pets), findsOneWidget);
    });

    testWidgets('accepts Widget icon (not just IconData)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              label: 'Birds',
              value: '10',
              icon: SizedBox(key: Key('svg_icon'), width: 20),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('svg_icon')), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              label: 'Birds',
              value: '10',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('renders vertical layout by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: 160,
              child: StatCard(label: 'Birds', value: '10'),
            ),
          ),
        ),
      );

      // Vertical layout uses Column
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('renders horizontal layout when isHorizontal is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              label: 'Birds',
              value: '10',
              icon: Icon(Icons.pets),
              isHorizontal: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Birds'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('shows trend up indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: 160,
              child: StatCard(
                label: 'Birds',
                value: '10',
                trendPercent: 15.0,
                trendUp: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.trendingUp), findsOneWidget);
      expect(find.text('+15%'), findsOneWidget);
    });

    testWidgets('shows trend down indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: 160,
              child: StatCard(
                label: 'Birds',
                value: '10',
                trendPercent: 5.0,
                trendUp: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.trendingDown), findsOneWidget);
      expect(find.text('-5%'), findsOneWidget);
    });

    testWidgets('shows stable trend text when percent is zero', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: 160,
              child: StatCard(
                label: 'Birds',
                value: '10',
                trendPercent: 0,
                trendUp: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // When trendPercent is 0, shows stable text (l10n key as raw string in tests)
      expect(find.text('statistics.trend_stable'), findsOneWidget);
    });

    testWidgets('displays non-numeric value as plain text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(label: 'Status', value: 'Active'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('displays percent value with % suffix', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(label: 'Rate', value: '75%'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('uses custom color for card styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              label: 'Birds',
              value: '10',
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('marks as button in semantics when onTap is provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              label: 'Birds',
              value: '10',
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the Semantics widget that is a direct descendant of StatCard
      final semantics = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(StatCard),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(semantics.properties.button, isTrue);
    });
  });
}
