part of 'event_form_sheet.dart';

/// Time picker row that displays the selected time and opens a picker on tap.
class _TimePickerField extends StatelessWidget {
  final TimeOfDay eventTime;
  final VoidCallback onTap;

  const _TimePickerField({required this.eventTime, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr =
        '${eventTime.hour.toString().padLeft(2, '0')}:${eventTime.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'calendar.event_time'.tr(),
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(LucideIcons.clock),
        ),
        child: Text(timeStr, style: theme.textTheme.bodyLarge),
      ),
    );
  }
}

/// Builds the list of [DropdownMenuItem]s for [EventType] selection.
List<DropdownMenuItem<EventType>> buildEventTypeItems() {
  return EventType.values.where((type) => type != EventType.unknown).map((
    type,
  ) {
    return DropdownMenuItem(
      value: type,
      child: Row(
        children: [
          Icon(eventTypeIcon(type), size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(eventTypeLabel(type)),
        ],
      ),
    );
  }).toList();
}
