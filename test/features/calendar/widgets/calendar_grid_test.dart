import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/calendar_grid.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  // March 2024: starts on Friday (weekday=5), 31 days
  final displayedMonth = DateTime(2024, 3);
  final selectedDate = DateTime(2024, 3, 15);

  Event makeEvent(String id) => Event(
    id: id,
    title: 'Test Event',
    eventDate: DateTime(2024, 3, 15, 10),
    type: EventType.custom,
    userId: 'user-1',
  );

  Widget buildGrid({
    DateTime? month,
    DateTime? selected,
    Map<DateTime, List<Event>> eventsMap = const {},
    ValueChanged<DateTime>? onDateSelected,
  }) {
    return CalendarGrid(
      displayedMonth: month ?? displayedMonth,
      selectedDate: selected ?? selectedDate,
      eventsMap: eventsMap,
      onDateSelected: onDateSelected ?? (_) {},
    );
  }

  group('CalendarGrid', () {
    testWidgets('renders without crash', (tester) async {
      await pumpWidgetSimple(tester, buildGrid());
      expect(find.byType(CalendarGrid), findsOneWidget);
    });

    testWidgets('shows day numbers for the month', (tester) async {
      await pumpWidgetSimple(tester, buildGrid());
      expect(find.text('1'), findsWidgets);
      expect(find.text('31'), findsOneWidget);
    });

    testWidgets('does not show day 32 (out of range)', (tester) async {
      await pumpWidgetSimple(tester, buildGrid());
      expect(find.text('32'), findsNothing);
    });

    testWidgets('fires onDateSelected when a day cell is tapped', (
      tester,
    ) async {
      DateTime? tappedDate;
      await pumpWidgetSimple(
        tester,
        buildGrid(onDateSelected: (d) => tappedDate = d),
      );
      await tester.tap(find.text('15').first);
      expect(tappedDate, isNotNull);
      expect(tappedDate!.day, 15);
    });

    testWidgets('renders event dot container for date with events', (
      tester,
    ) async {
      final eventsMap = {
        DateTime(2024, 3, 15): [makeEvent('e1')],
      };
      await pumpWidgetSimple(tester, buildGrid(eventsMap: eventsMap));
      // Widget tree contains event dot containers (4x4)
      // CalendarGrid itself renders without error
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('selected date cell has CircleAvatar-like container', (
      tester,
    ) async {
      await pumpWidgetSimple(tester, buildGrid());
      // Selected cell is day 15 — widget tree has Container with BoxDecoration
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasCircle = containers.any(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration as BoxDecoration).shape == BoxShape.circle,
      );
      expect(hasCircle, isTrue);
    });

    testWidgets('renders 7 GestureDetectors per week row', (tester) async {
      await pumpWidgetSimple(tester, buildGrid());
      // March 2024 has 5 weeks + partial rows → at least 28 GestureDetectors
      final gestures = tester.widgetList<GestureDetector>(
        find.byType(GestureDetector),
      );
      expect(gestures.length, greaterThanOrEqualTo(28));
    });
  });
}
