import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/features/notifications/providers/action_feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/widgets/notification_action_feedback_section.dart';

import '../../../helpers/test_localization.dart';

ActionFeedback _makeFeedback({
  String id = 'f-1',
  String message = 'Test feedback',
  ActionFeedbackType type = ActionFeedbackType.success,
  String? actionRoute,
  String? actionLabel,
  DateTime? createdAt,
}) =>
    ActionFeedback(
      id: id,
      message: message,
      type: type,
      createdAt: createdAt ?? DateTime.now(),
      actionRoute: actionRoute,
      actionLabel: actionLabel,
    );

void main() {
  setUp(() {
    ActionFeedbackService.resetForTesting();
  });

  Widget buildSubject({
    required List<ActionFeedback> feedbacks,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: SingleChildScrollView(
              child: ActionFeedbacksSection(feedbacks: feedbacks),
            ),
          ),
        ),
        GoRoute(
          path: '/birds/123',
          builder: (_, __) => const Scaffold(body: Text('Bird Detail')),
        ),
      ],
    );

    return ProviderScope(
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('ActionFeedbacksSection', () {
    testWidgets('renders section title', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(feedbacks: []),
      );

      // With test asset loader raw key is shown
      expect(
        find.text('notifications.recent_actions'),
        findsOneWidget,
      );
    });

    testWidgets('shows clear button when feedbacks are not empty', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(feedbacks: [_makeFeedback()]),
      );

      expect(find.text('common.clear'), findsOneWidget);
    });

    testWidgets('hides clear button when feedbacks list is empty', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(feedbacks: []),
      );

      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('renders feedback message text', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(feedbacks: [_makeFeedback(message: 'Bird saved')]),
      );

      expect(find.text('Bird saved'), findsOneWidget);
    });

    testWidgets('limits display to 10 items', (tester) async {
      final many = List.generate(
        15,
        (i) => _makeFeedback(id: 'f-$i', message: 'Msg $i'),
      );

      await pumpLocalizedApp(tester, buildSubject(feedbacks: many));

      // Only first 10 should render
      for (var i = 0; i < 10; i++) {
        expect(find.text('Msg $i'), findsOneWidget);
      }
      for (var i = 10; i < 15; i++) {
        expect(find.text('Msg $i'), findsNothing);
      }
    });
  });

  group('ActionFeedbackListTile', () {
    testWidgets('displays success icon for success type', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(feedbacks: [
          _makeFeedback(type: ActionFeedbackType.success),
        ]),
      );

      expect(find.byIcon(LucideIcons.checkCircle2), findsOneWidget);
    });

    testWidgets('displays alert icon for error type', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(feedbacks: [
          _makeFeedback(type: ActionFeedbackType.error),
        ]),
      );

      expect(find.byIcon(LucideIcons.alertCircle), findsOneWidget);
    });

    testWidgets('displays info icon for info type', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(feedbacks: [
          _makeFeedback(type: ActionFeedbackType.info),
        ]),
      );

      expect(find.byIcon(LucideIcons.info), findsOneWidget);
    });

    testWidgets('shows action label when actionRoute is set', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(feedbacks: [
          _makeFeedback(
            actionRoute: '/birds/123',
            actionLabel: 'View bird',
          ),
        ]),
      );

      expect(find.text('View bird'), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    });

    testWidgets('hides chevron when no actionRoute', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(feedbacks: [_makeFeedback()]),
      );

      expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
    });

    testWidgets('shows time ago text', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(feedbacks: [
          _makeFeedback(createdAt: DateTime.now()),
        ]),
      );

      // Just-now time text (raw key with test loader)
      expect(find.text('notifications.time_just_now'), findsOneWidget);
    });
  });
}
