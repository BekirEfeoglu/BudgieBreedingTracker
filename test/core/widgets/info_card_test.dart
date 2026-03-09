import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/cards/info_card.dart';

void main() {
  group('InfoCard', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InfoCard(title: 'Bird Name')),
        ),
      );

      expect(find.text('Bird Name'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoCard(title: 'Bird Name', subtitle: 'Male budgie'),
          ),
        ),
      );

      expect(find.text('Bird Name'), findsOneWidget);
      expect(find.text('Male budgie'), findsOneWidget);
    });

    testWidgets('does not render subtitle when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InfoCard(title: 'Bird Name')),
        ),
      );

      expect(find.text('Bird Name'), findsOneWidget);
      // No subtitle text visible
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders icon widget when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoCard(title: 'Bird Name', icon: Icon(Icons.pets)),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
      expect(find.byIcon(Icons.pets), findsOneWidget);
    });

    testWidgets('renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoCard(
              title: 'Bird Name',
              trailing: SizedBox(
                key: Key('trailing-widget'),
                width: 20,
                height: 20,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('trailing-widget')), findsOneWidget);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfoCard(title: 'Tap me', onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(InfoCard));
      expect(tapped, isTrue);
    });

    testWidgets('does not throw when onTap is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InfoCard(title: 'No tap')),
        ),
      );

      // Tap should not throw
      await tester.tap(find.byType(InfoCard));
      await tester.pump();
    });

    testWidgets('uses Card widget for layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: InfoCard(title: 'Test')),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });
}
