@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/features/community/widgets/community_feed_overlays.dart';

void main() {
  group('NewPostsBanner', () {
    testWidgets('renders with count and arrow icon', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NewPostsBanner(
              count: 3,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(NewPostsBanner), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowUp), findsOneWidget);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NewPostsBanner(
              count: 1,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(NewPostsBanner));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders with zero count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NewPostsBanner(
              count: 0,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(NewPostsBanner), findsOneWidget);
    });
  });

  group('SwipeOnboardingHint', () {
    testWidgets('renders title and dismiss icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeOnboardingHint(onDismiss: () {}),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SwipeOnboardingHint), findsOneWidget);
      expect(find.byIcon(LucideIcons.hand), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('shows left and right swipe hints', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeOnboardingHint(onDismiss: () {}),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.arrowRight), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
    });

    testWidgets('calls onDismiss when X icon is tapped', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeOnboardingHint(onDismiss: () => dismissed = true),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();

      expect(dismissed, isTrue);
    });
  });
}
