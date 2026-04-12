import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/action_feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/widgets/notification_bell_button.dart';

AppNotification makeNotification({String id = 'n-1', bool isRead = false}) =>
    AppNotification(
      id: id,
      userId: 'user-1',
      title: 'Test',
      body: 'Body',
      read: isRead,
      type: NotificationType.custom,
    );

void main() {
  // GoRouter is created inside buildSubject to avoid WidgetsFlutterBinding
  // conflict with test framework in GoRouter 17+.
  Widget buildSubject({List<AppNotification> unread = const []}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            appBar: AppBar(actions: [const NotificationBellButton()]),
            body: const SizedBox(),
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const Scaffold(body: Text('Notifications')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        unreadNotificationsProvider(
          'user-1',
        ).overrideWith((_) => Stream.value(unread)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('NotificationBellButton', () {
    setUp(() {
      ActionFeedbackService.resetForTesting();
    });

    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.byType(NotificationBellButton), findsOneWidget);
    });

    testWidgets('shows an IconButton', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.byType(IconButton), findsAtLeastNWidgets(1));
    });

    testWidgets('shows no Badge when unread count is zero', (tester) async {
      await tester.pumpWidget(buildSubject(unread: []));
      await tester.pump();
      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('shows Badge when there are unread notifications', (
      tester,
    ) async {
      final unread = [makeNotification(id: 'n-1'), makeNotification(id: 'n-2')];
      await tester.pumpWidget(buildSubject(unread: unread));
      await tester.pump();
      expect(find.byType(Badge), findsAtLeastNWidgets(1));
    });

    testWidgets('Badge shows correct count text', (tester) async {
      final unread = List.generate(3, (i) => makeNotification(id: 'n-$i'));
      await tester.pumpWidget(buildSubject(unread: unread));
      await tester.pump();
      expect(find.text('3'), findsAtLeastNWidgets(1));
    });

    testWidgets('Badge shows 99+ for more than 99 unread', (tester) async {
      final unread = List.generate(100, (i) => makeNotification(id: 'n-$i'));
      await tester.pumpWidget(buildSubject(unread: unread));
      await tester.pump();
      expect(find.text('99+'), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping navigates to notifications screen', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      await tester.tap(find.byType(NotificationBellButton));
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('shows badge when action feedback is added', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // No badge initially
      expect(find.byType(Badge), findsNothing);

      // Add a feedback
      ActionFeedbackService.show('Test success');
      await tester.pump();

      // Badge should appear with count 1
      expect(find.byType(Badge), findsAtLeastNWidgets(1));
      expect(find.text('1'), findsAtLeastNWidgets(1));
    });

    testWidgets('badge accumulates rapid feedbacks correctly', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // Fire 3 feedbacks rapidly
      ActionFeedbackService.show('Success 1');
      ActionFeedbackService.show('Success 2');
      ActionFeedbackService.show('Success 3');
      await tester.pump();

      // Badge should show 3
      expect(find.byType(Badge), findsAtLeastNWidgets(1));
      expect(find.text('3'), findsAtLeastNWidgets(1));
    });

    testWidgets('combined badge count includes notifications and feedbacks', (
      tester,
    ) async {
      final unread = [makeNotification(id: 'n-1')];
      await tester.pumpWidget(buildSubject(unread: unread));
      await tester.pump();

      // 1 notification
      expect(find.text('1'), findsAtLeastNWidgets(1));

      // Add 2 feedbacks
      ActionFeedbackService.show('Feedback 1');
      ActionFeedbackService.show('Feedback 2');
      await tester.pump();

      // 1 notification + 2 feedbacks = 3
      expect(find.text('3'), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping shows popup when feedbacks exist', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      ActionFeedbackService.show('Saved successfully');
      await tester.pump();

      await tester.tap(find.byType(NotificationBellButton));
      await tester.pump();

      // Popup should show the feedback message
      expect(find.text('Saved successfully'), findsAtLeastNWidgets(1));
    });

    testWidgets('popup auto-dismisses after 5 seconds', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      ActionFeedbackService.show('Auto dismiss test');
      await tester.pump();

      await tester.tap(find.byType(NotificationBellButton));
      await tester.pump();

      // Popup visible
      expect(find.text('Auto dismiss test'), findsAtLeastNWidgets(1));

      // Advance 5 seconds
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      // Popup should be dismissed
      expect(find.text('Auto dismiss test'), findsNothing);
    });

    testWidgets('badge clears after viewing popup', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      ActionFeedbackService.show('Clear badge test');
      await tester.pump();

      // Badge shows 1
      expect(find.text('1'), findsAtLeastNWidgets(1));

      // Tap to show popup (marks as read)
      await tester.tap(find.byType(NotificationBellButton));
      await tester.pump();

      // Badge should be gone (feedback marked as read, no notifications)
      expect(find.byType(Badge), findsNothing);
    });
  });
}
