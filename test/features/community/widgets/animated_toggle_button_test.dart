@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/community/widgets/animated_toggle_button.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  group('AnimatedToggleButton', () {
    const activeIcon = Icon(Icons.favorite, key: Key('active'));
    const inactiveIcon = Icon(Icons.favorite_border, key: Key('inactive'));

    Future<void> pump(
      WidgetTester tester, {
      bool isActive = false,
      VoidCallback? onToggle,
      String? label,
      String? semanticLabel,
    }) async {
      await pumpWidgetSimple(
        tester,
        AnimatedToggleButton(
          isActive: isActive,
          activeIcon: activeIcon,
          inactiveIcon: inactiveIcon,
          onToggle: onToggle ?? () {},
          label: label,
          semanticLabel: semanticLabel,
        ),
      );
    }

    testWidgets('shows inactiveIcon when isActive is false', (tester) async {
      await pump(tester, isActive: false);
      expect(find.byKey(const Key('inactive')), findsOneWidget);
      expect(find.byKey(const Key('active')), findsNothing);
    });

    testWidgets('shows activeIcon when isActive is true', (tester) async {
      await pump(tester, isActive: true);
      expect(find.byKey(const Key('active')), findsOneWidget);
      expect(find.byKey(const Key('inactive')), findsNothing);
    });

    testWidgets('calls onToggle when tapped', (tester) async {
      var tapped = false;
      await pump(tester, onToggle: () => tapped = true);
      await tester.tap(find.byType(AnimatedToggleButton));
      expect(tapped, isTrue);
    });

    testWidgets('shows label when provided', (tester) async {
      await pump(tester, label: '42');
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('does not show label when label is null', (tester) async {
      await pump(tester, label: null);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('applies semanticLabel', (tester) async {
      await pump(tester, semanticLabel: 'Like button');
      expect(
        find.bySemanticsLabel('Like button'),
        findsOneWidget,
      );
    });

    testWidgets('triggers scale animation when isActive changes', (
      tester,
    ) async {
      bool isActive = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    AnimatedToggleButton(
                      isActive: isActive,
                      activeIcon: activeIcon,
                      inactiveIcon: inactiveIcon,
                      onToggle: () => setState(() => isActive = !isActive),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Verify initial inactive state
      expect(find.byKey(const Key('inactive')), findsOneWidget);

      // Tap to toggle active
      await tester.tap(find.byType(AnimatedToggleButton));
      await tester.pump(); // start animation

      // During animation active icon is shown
      expect(find.byKey(const Key('active')), findsOneWidget);

      // Settle animation
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('active')), findsOneWidget);
    });

    testWidgets('swaps icons on successive toggles', (tester) async {
      bool isActive = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AnimatedToggleButton(
                  isActive: isActive,
                  activeIcon: activeIcon,
                  inactiveIcon: inactiveIcon,
                  onToggle: () => setState(() => isActive = !isActive),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('inactive')), findsOneWidget);

      await tester.tap(find.byType(AnimatedToggleButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('active')), findsOneWidget);

      await tester.tap(find.byType(AnimatedToggleButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inactive')), findsOneWidget);
    });

    testWidgets('updates label via AnimatedSwitcher when label changes', (
      tester,
    ) async {
      String label = '5';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    AnimatedToggleButton(
                      isActive: false,
                      activeIcon: activeIcon,
                      inactiveIcon: inactiveIcon,
                      onToggle: () => setState(() => label = '6'),
                      label: label,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);

      await tester.tap(find.byType(AnimatedToggleButton));
      await tester.pumpAndSettle();

      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('disposes controller without error', (tester) async {
      await pump(tester, isActive: false);
      // Navigate away — widget is disposed
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      // No exception = dispose works correctly
    });
  });
}
