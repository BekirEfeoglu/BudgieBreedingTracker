import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/calendar_event_list_sliver.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_card.dart';

void main() {
  Event makeEvent(String id, String title) => Event(
    id: id,
    title: title,
    eventDate: DateTime(2024, 3, 15, 10),
    type: EventType.custom,
    userId: 'user-1',
  );

  Widget buildSliver({
    required List<Event> events,
    ValueChanged<Event>? onEventTap,
    ValueChanged<Event>? onEditEvent,
    ValueChanged<Event>? onDeleteEvent,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            CalendarEventListSliver(
              events: events,
              onEventTap: onEventTap,
              onEditEvent: onEditEvent ?? (_) {},
              onDeleteEvent: onDeleteEvent ?? (_) {},
            ),
          ],
        ),
      ),
    );
  }

  group('CalendarEventListSliver', () {
    testWidgets('shows EmptyState when events list is empty', (tester) async {
      await tester.pumpWidget(buildSliver(events: const []));
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows EventCards when events list is non-empty', (
      tester,
    ) async {
      final events = [
        makeEvent('e1', 'Veteriner'),
        makeEvent('e2', 'Halka Takma'),
      ];
      await tester.pumpWidget(buildSliver(events: events));
      expect(find.byType(EventCard), findsNWidgets(2));
    });

    testWidgets('shows event titles for each event', (tester) async {
      final events = [
        makeEvent('e1', 'Veteriner'),
        makeEvent('e2', 'Halka Takma'),
      ];
      await tester.pumpWidget(buildSliver(events: events));
      expect(find.text('Veteriner'), findsOneWidget);
      expect(find.text('Halka Takma'), findsOneWidget);
    });

    testWidgets('fires onEditEvent callback', (tester) async {
      Event? editedEvent;
      final events = [makeEvent('e1', 'Veteriner')];
      final event = events.single;
      await tester.pumpWidget(
        buildSliver(events: events, onEditEvent: (e) => editedEvent = e),
      );
      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsNWidgets(2));

      await tester.tap(iconButtons.first);
      await tester.pump();

      expect(editedEvent, same(event));
    });

    testWidgets('renders in CustomScrollView without crash', (tester) async {
      await tester.pumpWidget(buildSliver(events: const []));
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('single event shows exactly one EventCard', (tester) async {
      await tester.pumpWidget(
        buildSliver(events: [makeEvent('e1', 'Solo Event')]),
      );
      expect(find.byType(EventCard), findsOneWidget);
    });
  });
}
