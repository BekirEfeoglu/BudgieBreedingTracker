import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_card.dart';

/// Shared sliver widget for displaying event lists with empty state.
///
/// Used by both month view (_CalendarBody) and week view (_WeekBody)
/// to avoid duplicating the empty state + event list pattern.
class CalendarEventListSliver extends StatelessWidget {
  final List<Event> events;
  final ValueChanged<Event>? onEventTap;
  final ValueChanged<Event> onEditEvent;
  final ValueChanged<Event> onDeleteEvent;

  const CalendarEventListSliver({
    super.key,
    required this.events,
    this.onEventTap,
    required this.onEditEvent,
    required this.onDeleteEvent,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxl),
          child: EmptyState(
            icon: const Icon(LucideIcons.calendarX),
            title: 'calendar.no_events'.tr(),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final event = events[index];
        return EventCard(
          event: event,
          onTap: onEventTap != null ? () => onEventTap!(event) : null,
          onEdit: () => onEditEvent(event),
          onDelete: () => onDeleteEvent(event),
        );
      }, childCount: events.length),
    );
  }
}
