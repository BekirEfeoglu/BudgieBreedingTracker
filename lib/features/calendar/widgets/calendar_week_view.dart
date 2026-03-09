import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_card.dart';

/// Week view grid showing 7 days with event indicators.
class CalendarWeekView extends StatelessWidget {
  final DateTime selectedDate;
  final Map<DateTime, List<Event>> eventsMap;
  final ValueChanged<DateTime> onDateSelected;

  const CalendarWeekView({
    super.key,
    required this.selectedDate,
    required this.eventsMap,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    // Get Monday of the selected date's week
    final monday =
        selectedDate.subtract(Duration(days: (selectedDate.weekday - 1)));

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
        children: List.generate(7, (index) {
          final day = monday.add(Duration(days: index));
          final dateKey = DateTime(day.year, day.month, day.day);
          final isToday = dateKey == today;
          final isSelected = dateKey == selected;
          final events = eventsMap[dateKey] ?? [];

          return Expanded(
            child: GestureDetector(
              onTap: () => onDateSelected(day),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : null,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Column(
                  children: [
                    Text(
                      weekdays[index].length > 3
                          ? weekdays[index].substring(0, 3)
                          : weekdays[index],
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isToday
                                ? theme.colorScheme.primary
                                    .withValues(alpha: 0.15)
                                : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isToday || isSelected
                              ? FontWeight.w700
                              : null,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : isToday
                                  ? theme.colorScheme.primary
                                  : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (events.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          events.length.clamp(0, 3),
                          (i) => Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : eventTypeColor(events[i].type),
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 5),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
