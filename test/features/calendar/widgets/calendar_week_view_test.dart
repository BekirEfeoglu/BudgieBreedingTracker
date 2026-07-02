import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/calendar_week_view.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  // Monday 2024-03-11 — a known Monday
  final selectedDate = DateTime(2024, 3, 13); // Wednesday

  Event makeEvent(DateTime date) => Event(
    id: 'e-${date.day}',
    title: 'Event',
    eventDate: date,
    type: EventType.custom,
    userId: 'user-1',
  );

  group('CalendarWeekView', () {
    testWidgets('renders without crash', (tester) async {
      await pumpWidgetSimple(
        tester,
        CalendarWeekView(
          selectedDate: selectedDate,
          eventsMap: const {},
          onDateSelected: (_) {},
        ),
      );
      expect(find.byType(CalendarWeekView), findsOneWidget);
    });

    testWidgets('shows 7 day columns', (tester) async {
      await pumpWidgetSimple(
        tester,
        CalendarWeekView(
          selectedDate: selectedDate,
          eventsMap: const {},
          onDateSelected: (_) {},
        ),
      );
      // 7 Expanded children in the Row
      final expanded = tester.widgetList<Expanded>(find.byType(Expanded));
      expect(expanded.length, greaterThanOrEqualTo(7));
    });

    testWidgets('fires onDateSelected when a day is tapped', (tester) async {
      DateTime? tappedDate;
      await pumpWidgetSimple(
        tester,
        CalendarWeekView(
          selectedDate: selectedDate,
          eventsMap: const {},
          onDateSelected: (d) => tappedDate = d,
        ),
      );
      // Tap the first GestureDetector (Monday)
      await tester.tap(find.byType(GestureDetector).first);
      expect(tappedDate, DateTime(2024, 3, 11));
    });

    testWidgets('shows day numbers for the week', (tester) async {
      // Week of 2024-03-11 → days 11..17
      await pumpWidgetSimple(
        tester,
        CalendarWeekView(
          selectedDate: selectedDate,
          eventsMap: const {},
          onDateSelected: (_) {},
        ),
      );
      // At least the selected date's day is shown
      expect(find.text('13'), findsWidgets);
    });

    testWidgets('selected day container has decoration', (tester) async {
      await pumpWidgetSimple(
        tester,
        CalendarWeekView(
          selectedDate: selectedDate,
          eventsMap: const {},
          onDateSelected: (_) {},
        ),
      );
      // Selected day column has a Container with BoxDecoration color
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasDecoration = containers.any(
        (c) => c.decoration is BoxDecoration,
      );
      expect(hasDecoration, isTrue);
    });

    testWidgets('renders event dots for days with events', (tester) async {
      final mondayOfWeek = selectedDate.subtract(
        Duration(days: selectedDate.weekday - 1),
      );
      final dateKey = DateTime(
        mondayOfWeek.year,
        mondayOfWeek.month,
        mondayOfWeek.day,
      );
      final eventsMap = {
        dateKey: [makeEvent(dateKey)],
      };

      await pumpWidgetSimple(
        tester,
        CalendarWeekView(
          selectedDate: selectedDate,
          eventsMap: eventsMap,
          onDateSelected: (_) {},
        ),
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.constraints ==
                  const BoxConstraints.tightFor(width: 5, height: 5) &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'day-with-events semantic label names the event type, not just the '
      'count, so color-blind/screen-reader users get the same info the '
      'color-coded dots convey visually',
      (tester) async {
        final mondayOfWeek = selectedDate.subtract(
          Duration(days: selectedDate.weekday - 1),
        );
        final dateKey = DateTime(
          mondayOfWeek.year,
          mondayOfWeek.month,
          mondayOfWeek.day,
        );
        final eventsMap = {
          dateKey: [makeEvent(dateKey)],
        };

        await pumpWidgetSimple(
          tester,
          CalendarWeekView(
            selectedDate: selectedDate,
            eventsMap: eventsMap,
            onDateSelected: (_) {},
          ),
        );

        // pumpWidgetSimple doesn't mount EasyLocalization, so `.tr()` falls
        // back to the raw key (no arg interpolation) — assert on the key
        // itself, which is what other tests in this suite already rely on.
        final semantics = tester.getSemantics(find.text('${dateKey.day}'));
        expect(semantics.label, contains('calendar.day_with_events'));
        // EventType.custom -> 'calendar.general' per eventTypeLabel; its
        // presence proves the type name was appended, not just the count.
        expect(semantics.label, contains('calendar.general'));
      },
    );
  });
}
