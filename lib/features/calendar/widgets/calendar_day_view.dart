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
    final theme = Theme.of(context);
    final sortedEvents = List<Event>.from(events)
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

    // Dynamic hour range: default 06:00-22:00, expand if events fall outside
    var startHour = 6;
    var endHour = 22;

    if (sortedEvents.isNotEmpty) {
      final minHour = sortedEvents
          .map((e) => e.eventDate.hour)
          .reduce(math.min);
      final maxHour = sortedEvents
          .map((e) => e.endDate != null ? e.endDate!.hour : e.eventDate.hour)
          .reduce(math.max);
      startHour = math.min(startHour, minHour);
      endHour = math.max(endHour, maxHour + 1);
    }

    final slotCount = endHour - startHour + 1;
    final slots = List.generate(slotCount, (i) => i + startHour);

    return ListView.builder(
      padding: const EdgeInsets.only(
        bottom: AppSpacing.xxxl * 2,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final hour = slots[index];
        final hourStr = '${hour.toString().padLeft(2, '0')}:00';

        // Events that fall in this hour (including endDate range)
        final hourEvents = sortedEvents.where((e) {
          if (e.endDate != null) {
            return e.eventDate.hour <= hour && e.endDate!.hour >= hour;
          }
          return e.eventDate.hour == hour;
        }).toList();

        return _HourSlot(
          hourLabel: hourStr,
          events: hourEvents,
          theme: theme,
          onEditEvent: onEditEvent,
          onDeleteEvent: onDeleteEvent,
          onEventTap: onEventTap,
        );
      },
    );
  }
}

class _HourSlot extends StatelessWidget {
  final String hourLabel;
  final List<Event> events;
  final ThemeData theme;
  final ValueChanged<Event> onEditEvent;
  final ValueChanged<Event> onDeleteEvent;
  final ValueChanged<Event>? onEventTap;

  const _HourSlot({
    required this.hourLabel,
    required this.events,
    required this.theme,
    required this.onEditEvent,
    required this.onDeleteEvent,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
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
                          .map((e) => EventCard(
                                event: e,
                                onTap: onEventTap != null
                                    ? () => onEventTap!(e)
                                    : null,
                                onEdit: () => onEditEvent(e),
                                onDelete: () => onDeleteEvent(e),
                              ))
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
