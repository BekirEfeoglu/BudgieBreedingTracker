import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/dialogs/confirm_dialog.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/features/calendar/providers/calendar_form_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_card.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_form_sheet.dart';

/// Bottom sheet listing events for a specific day.
class DayEventsSheet extends ConsumerWidget {
  final DateTime date;
  final List<Event> events;

  const DayEventsSheet({super.key, required this.date, required this.events});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat.yMMMMd(
      context.locale.toStringWithSeparator(),
    ).format(date);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'calendar.events_for_day'.tr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          dateLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const AppIcon(AppIcons.add),
                    onPressed: () {
                      Navigator.of(context).pop();
                      showEventFormSheet(context, initialDate: date);
                    },
                    tooltip: 'calendar.add_event'.tr(),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: events.isEmpty
                  ? EmptyState(
                      icon: const Icon(LucideIcons.calendarX),
                      title: 'calendar.no_events'.tr(),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return EventCard(
                          key: ValueKey(event.id),
                          event: event,
                          onEdit: () {
                            Navigator.of(context).pop();
                            showEventFormSheet(context, existingEvent: event);
                          },
                          onDelete: () => _confirmDelete(context, ref, event),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Event event,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'calendar.delete_event'.tr(),
      message: 'calendar.delete_event_confirm'.tr(),
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      ref.read(eventFormStateProvider.notifier).deleteEvent(event.id);
      Navigator.of(context).pop();
    }
  }
}

/// Opens the [DayEventsSheet] as a modal bottom sheet.
Future<void> showDayEventsSheet(
  BuildContext context, {
  required DateTime date,
  required List<Event> events,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: AppSpacing.maxSheetWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (_) => DayEventsSheet(date: date, events: events),
  );
}
