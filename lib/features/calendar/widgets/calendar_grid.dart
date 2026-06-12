import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_card.dart';

/// Custom month grid (7 columns, Mon-Sun) with event dots.
class CalendarGrid extends StatelessWidget {
  /// Currently displayed month.
  final DateTime displayedMonth;

  /// Currently selected date.
  final DateTime selectedDate;

  /// Events grouped by day for this month.
  final Map<DateTime, List<Event>> eventsMap;

  /// Callback when a date is tapped.
  final ValueChanged<DateTime> onDateSelected;

  const CalendarGrid({
    super.key,
    required this.displayedMonth,
    required this.selectedDate,
    required this.eventsMap,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    // `today` and all grid-cell dates are local date-only (year/month/day,
    // no time-of-day). `eventsMap` keys are likewise normalized to local
    // calendar days upstream — keep everything date-only here to avoid
    // mixed-timezone equality drift.
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final daysInMonth = DateUtils.getDaysInMonth(
      displayedMonth.year,
      displayedMonth.month,
    );

    final firstDay = DateTime(displayedMonth.year, displayedMonth.month, 1);
    // Monday = 1, so offset = weekday - 1
    final startOffset = (firstDay.weekday - DateTime.monday) % 7;

    return Column(
      children: [
        _buildWeekdayHeaders(context),
        const SizedBox(height: AppSpacing.xs),
        _buildDayGrid(
          context,
          theme,
          today,
          selected,
          daysInMonth,
          startOffset,
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders(BuildContext context) {
    final theme = Theme.of(context);
    final weekdays = [
      'calendar.mon'.tr(),
      'calendar.tue'.tr(),
      'calendar.wed'.tr(),
      'calendar.thu'.tr(),
      'calendar.fri'.tr(),
      'calendar.sat'.tr(),
      'calendar.sun'.tr(),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: weekdays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day.length > 3 ? day.substring(0, 3) : day,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayGrid(
    BuildContext context,
    ThemeData theme,
    DateTime today,
    DateTime selected,
    int daysInMonth,
    int startOffset,
  ) {
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final index = row * 7 + col;
              final dayNum = index - startOffset + 1;

              if (dayNum < 1 || dayNum > daysInMonth) {
                // Match real cell height (48) so out-of-month rows don't
                // collapse and misalign the grid.
                return const Expanded(child: SizedBox(height: 48));
              }

              final date = DateTime(
                displayedMonth.year,
                displayedMonth.month,
                dayNum,
              );
              final isToday = date == today;
              final isSelected = date == selected;
              final hasEvents = eventsMap.containsKey(date);

              final dayEvents = eventsMap[date] ?? [];

              return Expanded(
                child: _DayCell(
                  day: dayNum,
                  isToday: isToday,
                  isSelected: isSelected,
                  hasEvents: hasEvents,
                  events: dayEvents,
                  onTap: () => onDateSelected(date),
                  theme: theme,
                ),
              );
            }),
          );
        }),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasEvents;
  final List<Event> events;
  final VoidCallback onTap;
  final ThemeData theme;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasEvents,
    required this.events,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Localized accessible label: "Pazartesi, 14, 3 etkinlik". Screen
    // readers announce the day number alone otherwise.
    final eventCount = events.length;
    final semanticLabel = isSelected
        ? 'calendar.day_selected'.tr(args: ['$day', '$eventCount'])
        : 'calendar.day_with_events'.tr(args: ['$day', '$eventCount']);

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          // WCAG 2.5.5 minimum 48dp. Grid layout means rows decide the
          // outer cell height, but at least the per-cell hit target is
          // not smaller than the accessibility floor.
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : isToday
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isToday || isSelected ? FontWeight.w700 : null,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : isToday
                        ? theme.colorScheme.primary
                        : null,
                  ),
                ),
              ),
              if (hasEvents)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    events.length.clamp(0, 3),
                    (i) => Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsetsDirectional.only(
                        top: 2,
                        start: 1,
                        end: 1,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Preserve per-event-type color even on a selected day
                        // so the type distinction isn't lost.
                        color: eventTypeColor(events[i].type),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
