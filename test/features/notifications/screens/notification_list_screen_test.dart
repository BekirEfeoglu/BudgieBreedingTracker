import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/screens/notification_list_screen.dart';
import 'package:budgie_breeding_tracker/features/notifications/widgets/notification_card.dart';

void main() {
  AppNotification makeNotification({
    String id = 'notif-1',
    bool read = false,
    String? referenceType,
    String? referenceId,
  }) {
    return AppNotification(
      id: id,
      userId: 'test-user',
      title: 'Test Notification $id',
      body: 'Test body',
      read: read,
      referenceType: referenceType,
      referenceId: referenceId,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationListScreen(),
        ),
        GoRoute(
          path: '/birds/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Bird: ${state.pathParameters['id']}')),
        ),
      ],
    );
  });

  Widget createSubject({
    required Stream<List<AppNotification>> notificationsStream,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        notificationsStreamProvider(
          'test-user',
        ).overrideWith((_) => notificationsStream),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('NotificationListScreen', () {
    testWidgets('shows loading indicator while data is loading', (
      tester,
    ) async {
      final controller = StreamController<List<AppNotification>>();

      await tester.pumpWidget(
        createSubject(notificationsStream: controller.stream),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.close();
    });

    testWidgets('shows empty state when no notifications exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(notificationsStream: Stream.value([])),
      );

      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows error state on stream error', (tester) async {
      await tester.pumpWidget(
        createSubject(notificationsStream: Stream.error('Network error')),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows notification cards when data is available', (
      tester,
    ) async {
      final notifications = [
        makeNotification(id: 'n1'),
        makeNotification(id: 'n2'),
        makeNotification(id: 'n3'),
      ];

      await tester.pumpWidget(
        createSubject(notificationsStream: Stream.value(notifications)),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NotificationCard), findsNWidgets(3));
    });

    testWidgets('shows filter chips for all/unread/read', (tester) async {
      await tester.pumpWidget(
        createSubject(notificationsStream: Stream.value([])),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsNWidgets(3));
      expect(find.text(l10n('notifications.filter_all')), findsOneWidget);
      expect(find.text(l10n('notifications.filter_unread')), findsOneWidget);
      expect(find.text(l10n('notifications.filter_read')), findsOneWidget);
    });

    testWidgets('shows AppBar with inbox title', (tester) async {
      await tester.pumpWidget(
        createSubject(notificationsStream: Stream.value([])),
      );

      await tester.pumpAndSettle();

      expect(find.text(l10n('notifications.inbox_title')), findsOneWidget);
    });

    testWidgets('shows mark all read button in AppBar', (tester) async {
      await tester.pumpWidget(
        createSubject(notificationsStream: Stream.value([])),
      );

      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('filtering by unread shows only unread notifications', (
      tester,
    ) async {
      final notifications = [
        makeNotification(id: 'n1', read: false),
        makeNotification(id: 'n2', read: true),
        makeNotification(id: 'n3', read: false),
      ];

      await tester.pumpWidget(
        createSubject(notificationsStream: Stream.value(notifications)),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('notifications.filter_unread')));
      await tester.pumpAndSettle();

      // Should show 2 unread notifications
      expect(find.byType(NotificationCard), findsNWidgets(2));
    });

    testWidgets('filtering by read shows only read notifications', (
      tester,
    ) async {
      final notifications = [
        makeNotification(id: 'n1', read: false),
        makeNotification(id: 'n2', read: true),
      ];

      await tester.pumpWidget(
        createSubject(notificationsStream: Stream.value(notifications)),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('notifications.filter_read')));
      await tester.pumpAndSettle();

      // Should show 1 read notification
      expect(find.byType(NotificationCard), findsNWidgets(1));
    });

    testWidgets(
      'shows no results empty state when filter yields no notifications',
      (tester) async {
        // All notifications are read, filter by unread → no results
        final notifications = [makeNotification(id: 'n1', read: true)];

        await tester.pumpWidget(
          createSubject(notificationsStream: Stream.value(notifications)),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.text(l10n('notifications.filter_unread')));
        await tester.pumpAndSettle();

        expect(find.byType(EmptyState), findsOneWidget);
      },
    );
  });
}
