import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';

void main() {
  group('Notification EmptyState (no data)', () {
    Widget createSubject() {
      return MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: const Icon(LucideIcons.bellOff),
            title: resolvedL10n('notifications.no_notifications'),
            subtitle: resolvedL10n('notifications.no_notifications_hint'),
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

      expect(
        find.text(resolvedL10n('notifications.no_notifications')),
        findsOneWidget,
      );
    });

    testWidgets('shows correct subtitle text', (tester) async {
      await tester.pumpWidget(createSubject());

      expect(
        find.text(resolvedL10n('notifications.no_notifications_hint')),
        findsOneWidget,
      );
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
      return MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: const Icon(LucideIcons.searchX),
            title: resolvedL10n('common.no_results'),
            subtitle: resolvedL10n('common.no_results_hint'),
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

      expect(find.text(resolvedL10n('common.no_results')), findsOneWidget);
    });

    testWidgets('shows correct subtitle text', (tester) async {
      await tester.pumpWidget(createSubject());

      expect(
        find.text(resolvedL10n('common.no_results_hint')),
        findsOneWidget,
      );
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
