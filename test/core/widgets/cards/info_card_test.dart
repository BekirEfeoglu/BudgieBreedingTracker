import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/cards/info_card.dart';

void main() {
  group('InfoCard', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InfoCard(title: 'Bird Info')),
        ),
      );

      expect(find.text('Bird Info'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoCard(title: 'Bird Info', subtitle: 'Details'),
          ),
        ),
      );

      expect(find.text('Bird Info'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('does not render subtitle when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InfoCard(title: 'Bird Info')),
        ),
      );

      // Only title text should be present
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoCard(title: 'Bird Info', icon: Icon(Icons.info)),
          ),
        ),
      );

      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('accepts Widget icon (not just IconData)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoCard(
              title: 'Bird Info',
              icon: SizedBox(key: Key('svg_icon'), width: 24),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('svg_icon')), findsOneWidget);
    });

    testWidgets('renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoCard(
              title: 'Bird Info',
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoCard(
              title: 'Bird Info',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('uses custom semanticLabel when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoCard(
              title: 'Bird Info',
              semanticLabel: 'Custom label',
            ),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(InfoCard),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(semantics.properties.label, 'Custom label');
    });

    testWidgets('builds default semanticLabel from title and subtitle',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoCard(title: 'Count', subtitle: 'Birds'),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(InfoCard),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(semantics.properties.label, 'Birds: Count');
    });

    testWidgets('marks as button in semantics when onTap is provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoCard(title: 'Bird Info', onTap: () {}),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find.descendant(
          of: find.byType(InfoCard),
          matching: find.byType(Semantics),
        ).first,
      );
      expect(semantics.properties.button, isTrue);
    });
  });
}
