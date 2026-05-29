import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_card.dart';

/// Day view showing hourly slots with dynamic hour range based on events.
class CalendarDayView extends StatelessWidget {
  final DateTime selectedDate;
  final List<Event> events;
  final ValueChanged<Event> onEditEvent;
  final ValueChanged<Event> onDeleteEvent;
  final ValueChanged<Event>? onEventTap;

  const CalendarDayView({
    super.key,
    required this.selectedDate,
    required this.events,
    required this.onEditEvent,
    required this.onDeleteEvent,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    // Event model stores UTC; convert to local for wall-clock display.
    final sortedEvents = List<Event>.from(events)
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

    // Dynamic hour range: default 06:00-22:00, expand if events fall outside
    var startHour = 6;
    var endHour = 22;

    if (sortedEvents.isNotEmpty) {
      final minHour = sortedEvents
          .map((e) => e.eventDate.toLocal().hour)
          .reduce(math.min);
      final maxHour = sortedEvents
          .map((e) {
            final localStart = e.eventDate.toLocal();
            if (e.endDate == null) return localStart.hour;
            final localEnd = e.endDate!.toLocal();
            // For events that span past the start day, the end hour belongs
            // to a later calendar day; clamp the day's range to end-of-day
            // (23) instead of the smaller wall-clock end hour, which would
            // otherwise pull the range backwards.
            return _isSameDay(localStart, localEnd) ? localEnd.hour : 23;
          })
          .reduce(math.max);
      startHour = math.min(startHour, minHour);
      endHour = math.max(endHour, maxHour + 1);
    }

    final slotCount = endHour - startHour + 1;
    final slots = List.generate(slotCount, (i) => i + startHour);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl * 2),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final hour = slots[index];
        final hourStr = '${hour.toString().padLeft(2, '0')}:00';

        // Events that fall in this hour (including endDate range)
        final hourEvents = sortedEvents.where((e) {
          final localStart = e.eventDate.toLocal();
          final startHr = localStart.hour;
          if (e.endDate != null) {
            final localEnd = e.endDate!.toLocal();
            // Compare full normalized dates, not the day-of-month alone — a
            // next-month event with the same day number must not be treated
            // as same-day.
            if (_isSameDay(localStart, localEnd)) {
              // Same-day event
              return startHr <= hour && localEnd.hour >= hour;
            }
            // Cross-midnight (or multi-day): show from start hour to end of day
            return startHr <= hour;
          }
          return startHr == hour;
        }).toList();

        return _HourSlot(
          hourLabel: hourStr,
          events: hourEvents,
          onEditEvent: onEditEvent,
          onDeleteEvent: onDeleteEvent,
          onEventTap: onEventTap,
        );
      },
    );
  }
}

/// Whether two local [DateTime]s fall on the same calendar day. Compares the
/// full date (year/month/day), not just the day-of-month.
bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _HourSlot extends StatelessWidget {
  final String hourLabel;
  final List<Event> events;
  final ValueChanged<Event> onEditEvent;
  final ValueChanged<Event> onDeleteEvent;
  final ValueChanged<Event>? onEventTap;

  const _HourSlot({
    required this.hourLabel,
    required this.events,
    required this.onEditEvent,
    required this.onDeleteEvent,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Using ConstrainedBox instead of IntrinsicHeight to avoid O(n^2)
    // layout cost inside ListView.builder.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                top: AppSpacing.sm,
              ),
              child: Text(
                hourLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
              ),
              child: events.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      children: events
                          .map(
                            (e) => EventCard(
                              event: e,
                              onTap: onEventTap != null
                                  ? () => onEventTap!(e)
                                  : null,
                              onEdit: () => onEditEvent(e),
                              onDelete: () => onDeleteEvent(e),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
