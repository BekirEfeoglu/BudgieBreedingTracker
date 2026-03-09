import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
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
  });
}
