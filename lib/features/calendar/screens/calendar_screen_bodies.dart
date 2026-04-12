part of 'calendar_screen.dart';

/// Body of the calendar screen containing the grid and event list.
class _CalendarBody extends StatelessWidget {
  final DateTime displayedMonth;
  final DateTime selectedDate;
  final Map<DateTime, List<Event>> eventsMap;
  final List<Event> selectedEvents;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onDateLongPress;
  final ValueChanged<Event>? onEventTap;
  final ValueChanged<Event> onEditEvent;
  final ValueChanged<Event> onDeleteEvent;

  const _CalendarBody({
    required this.displayedMonth,
    required this.selectedDate,
    required this.eventsMap,
    required this.selectedEvents,
    required this.onDateSelected,
    required this.onDateLongPress,
    this.onEventTap,
    required this.onEditEvent,
    required this.onDeleteEvent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedLabel = DateFormat.yMMMMd(
      context.locale.toStringWithSeparator(),
    ).format(selectedDate);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: CalendarHeader()),
        SliverToBoxAdapter(
          child: CalendarGrid(
            displayedMonth: displayedMonth,
            selectedDate: selectedDate,
            eventsMap: eventsMap,
            onDateSelected: onDateSelected,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'calendar.view_all_events'.tr(),
                  child: InkWell(
                    onTap: () => onDateLongPress(selectedDate),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.maximize2,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${selectedEvents.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: Divider()),
        CalendarEventListSliver(
          events: selectedEvents,
          onEventTap: onEventTap,
          onEditEvent: onEditEvent,
          onDeleteEvent: onDeleteEvent,
        ),
        // Bottom padding for FAB
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl * 2)),
      ],
    );
  }
}

/// Week view body with week grid + selected day events.
class _WeekBody extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, List<Event>> weekEvents;
  final List<Event> selectedEvents;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<Event>? onEventTap;
  final ValueChanged<Event> onEditEvent;
  final ValueChanged<Event> onDeleteEvent;

  const _WeekBody({
    required this.selectedDate,
    required this.weekEvents,
    required this.selectedEvents,
    required this.onDateSelected,
    this.onEventTap,
    required this.onEditEvent,
    required this.onDeleteEvent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: CalendarWeekView(
            selectedDate: selectedDate,
            eventsMap: weekEvents,
            onDateSelected: onDateSelected,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              'calendar.events_for_day'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: Divider()),
        CalendarEventListSliver(
          events: selectedEvents,
          onEventTap: onEventTap,
          onEditEvent: onEditEvent,
          onDeleteEvent: onDeleteEvent,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl * 2)),
      ],
    );
  }
}
