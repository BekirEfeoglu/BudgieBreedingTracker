import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_card.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  final testEvent = Event(
    id: 'event-1',
    title: 'Veteriner Kontrolü',
    eventDate: DateTime(2024, 1, 15, 10, 30),
    type: EventType.health,
    userId: 'user-1',
  );

  group('EventCard', () {
    testWidgets('displays event title', (tester) async {
      await pumpWidgetSimple(tester, EventCard(event: testEvent));

      expect(find.text('Veteriner Kontrolü'), findsOneWidget);
    });

    testWidgets('renders inside a Card widget', (tester) async {
      await pumpWidgetSimple(tester, EventCard(event: testEvent));

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('custom onTap is invoked', (tester) async {
      var tapped = false;

      await pumpWidgetSimple(
        tester,
        EventCard(event: testEvent, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });

    testWidgets('shows edit button when onEdit is provided', (tester) async {
      await pumpWidgetSimple(
        tester,
        EventCard(event: testEvent, onEdit: () {}),
      );

      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('shows notes when present', (tester) async {
      final event = Event(
        id: 'event-2',
        title: 'Kontrol',
        eventDate: DateTime(2024, 1, 20),
        type: EventType.health,
        userId: 'user-1',
        notes: 'Gözlem notu',
      );

      await pumpWidgetSimple(tester, EventCard(event: event));

      expect(find.text('Gözlem notu'), findsOneWidget);
    });

    testWidgets('completed event shows reduced opacity', (tester) async {
      final completedEvent = Event(
        id: 'event-3',
        title: 'Tamamlanan',
        eventDate: DateTime(2024, 1, 15),
        type: EventType.custom,
        userId: 'user-1',
        status: EventStatus.completed,
      );

      await pumpWidgetSimple(tester, EventCard(event: completedEvent));

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, lessThan(1.0));
    });

    testWidgets('active event shows full opacity', (tester) async {
      await pumpWidgetSimple(tester, EventCard(event: testEvent));

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, equals(1.0));
    });

    testWidgets('shows delete button when onDelete is provided', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        EventCard(event: testEvent, onDelete: () {}),
      );

      expect(find.byType(IconButton), findsWidgets);
    });
  });
}
