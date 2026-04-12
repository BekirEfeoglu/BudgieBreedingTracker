import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/features/notifications/widgets/notification_card.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  const testNotification = AppNotification(
    id: 'notif-1',
    title: 'Yumurta Çevirme Zamanı',
    userId: 'user-1',
    type: NotificationType.eggTurning,
  );

  group('NotificationCard', () {
    testWidgets('displays notification title', (tester) async {
      await pumpWidgetSimple(
        tester,
        const NotificationCard(notification: testNotification),
      );

      expect(find.text('Yumurta Çevirme Zamanı'), findsOneWidget);
    });

    testWidgets('shows body when present', (tester) async {
      const notif = AppNotification(
        id: 'notif-2',
        title: 'Bildirim',
        userId: 'user-1',
        body: 'Detaylı açıklama',
      );

      await pumpWidgetSimple(
        tester,
        const NotificationCard(notification: notif),
      );

      expect(find.text('Detaylı açıklama'), findsOneWidget);
    });

    testWidgets('custom onTap is invoked', (tester) async {
      var tapped = false;

      await pumpWidgetSimple(
        tester,
        NotificationCard(
          notification: testNotification,
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });

    testWidgets('renders inside a Card widget', (tester) async {
      await pumpWidgetSimple(
        tester,
        const NotificationCard(notification: testNotification),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('Dismissible is present', (tester) async {
      await pumpWidgetSimple(
        tester,
        const NotificationCard(notification: testNotification),
      );

      expect(find.byType(Dismissible), findsOneWidget);
    });

    testWidgets('high priority notification renders without error', (
      tester,
    ) async {
      const highPriority = AppNotification(
        id: 'notif-3',
        title: 'Kritik Uyarı',
        userId: 'user-1',
        priority: NotificationPriority.high,
      );

      await pumpWidgetSimple(
        tester,
        const NotificationCard(notification: highPriority),
      );

      expect(find.text('Kritik Uyarı'), findsOneWidget);
    });

    testWidgets('read notification renders without error', (tester) async {
      const readNotif = AppNotification(
        id: 'notif-4',
        title: 'Okunmuş',
        userId: 'user-1',
        read: true,
      );

      await pumpWidgetSimple(
        tester,
        const NotificationCard(notification: readNotif),
      );

      expect(find.text('Okunmuş'), findsOneWidget);
    });

    testWidgets('different notification types render without error', (
      tester,
    ) async {
      for (final type in NotificationType.values) {
        final notif = AppNotification(
          id: 'notif-type-$type',
          title: 'Test $type',
          userId: 'user-1',
          type: type,
        );

        await pumpWidgetSimple(tester, NotificationCard(notification: notif));
        expect(find.byType(Card), findsOneWidget);
      }
    });
  });
}
