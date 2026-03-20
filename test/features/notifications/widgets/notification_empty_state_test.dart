import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';

void main() {
  group('Notification EmptyState (no data)', () {
    Widget createSubject() {
      return const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icon(LucideIcons.bellOff),
            title: 'notifications.no_notifications',
            subtitle: 'notifications.no_notifications_hint',
          ),
        ),
      );
    }

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(createSubject());

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows correct title text', (tester) async {
      await tester.pumpWidget(createSubject());

      expect(find.text('notifications.no_notifications'), findsOneWidget);
    });

    testWidgets('shows correct subtitle text', (tester) async {
      await tester.pumpWidget(createSubject());

      expect(find.text('notifications.no_notifications_hint'), findsOneWidget);
    });

    testWidgets('shows bellOff icon', (tester) async {
      await tester.pumpWidget(createSubject());

      expect(find.byIcon(LucideIcons.bellOff), findsOneWidget);
    });

    testWidgets('does not show action button', (tester) async {
      await tester.pumpWidget(createSubject());

      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('Notification EmptyState (no search results)', () {
    Widget createSubject() {
      return const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icon(LucideIcons.searchX),
            title: 'common.no_results',
            subtitle: 'common.no_results_hint',
          ),
        ),
      );
    }

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(createSubject());

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows correct title text', (tester) async {
      await tester.pumpWidget(createSubject());

      expect(find.text('common.no_results'), findsOneWidget);
    });

    testWidgets('shows correct subtitle text', (tester) async {
      await tester.pumpWidget(createSubject());

      expect(find.text('common.no_results_hint'), findsOneWidget);
    });

    testWidgets('shows searchX icon', (tester) async {
      await tester.pumpWidget(createSubject());

      expect(find.byIcon(LucideIcons.searchX), findsOneWidget);
    });

    testWidgets('does not show action button', (tester) async {
      await tester.pumpWidget(createSubject());

      expect(find.byType(FilledButton), findsNothing);
    });
  });
}
