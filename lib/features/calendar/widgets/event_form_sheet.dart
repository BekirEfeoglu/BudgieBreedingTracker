import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/date_picker_field.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/providers/calendar_form_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/date_format_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_card.dart';
import 'package:budgie_breeding_tracker/core/providers/action_feedback_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/bottom_sheet/app_bottom_sheet.dart';

part 'event_form_fields.dart';

/// Opens the event form as a modal bottom sheet.
Future<void> showEventFormSheet(
  BuildContext context, {
  Event? existingEvent,
  DateTime? initialDate,
}) {
  return showAppBottomSheet(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: AppSpacing.maxSheetWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (_) => _EventFormContent(
      existingEvent: existingEvent,
      initialDate: initialDate,
    ),
  );
}

class _EventFormContent extends ConsumerStatefulWidget {
  final Event? existingEvent;
  final DateTime? initialDate;

  const _EventFormContent({this.existingEvent, this.initialDate});

  @override
  ConsumerState<_EventFormContent> createState() => _EventFormContentState();
}

class _EventFormContentState extends ConsumerState<_EventFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _eventDate;
  late TimeOfDay _eventTime;
  late EventType _eventType;

  bool get _isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEvent;
    if (existing != null) {
      // Event model stores UTC; convert to local for display/edit pickers.
      final localDate = existing.eventDate.toLocal();
      _titleController.text = existing.title;
      _notesController.text = existing.notes ?? '';
      _eventDate = localDate;
      _eventTime = TimeOfDay(hour: localDate.hour, minute: localDate.minute);
      _eventType = existing.type;
    } else {
      _eventDate = widget.initialDate ?? DateTime.now();
      _eventTime = TimeOfDay.now();
      _eventType = EventType.custom;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(eventFormStateProvider);

    ref.listen<EventFormState>(eventFormStateProvider, (_, state) {
      if (state.isSuccess) {
        ref.read(eventFormStateProvider.notifier).reset();
        if (!mounted) return;
        Navigator.of(context).pop();
        ActionFeedbackService.show(
          _isEditing
              ? 'calendar.event_updated'.tr()
              : 'calendar.event_saved'.tr(),
        );
      }
      if (state.error != null && mounted) {
        // Surface the typed error captured by the form provider (already
        // localized by the catch block) instead of a generic fallback.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error!)));
        // Clear the error so re-emitting the same state won't replay it.
        ref.read(eventFormStateProvider.notifier).clearError();
      }
    });

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _isEditing
                    ? 'calendar.edit_event'.tr()
                    : 'calendar.add_event'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title field
              // IMPROVED: add maxLength to prevent overflow on small screens
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'calendar.event_title'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(LucideIcons.type),
                ),
                maxLength: 100,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'validation.field_required'.tr(
                      args: ['calendar.event_title'.tr()],
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Event type dropdown
              DropdownButtonFormField<EventType>(
                initialValue: _eventType,
                decoration: InputDecoration(
                  labelText: 'calendar.event_type'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: eventTypeIconWidget(_eventType, size: 20),
                  ),
                ),
                items: buildEventTypeItems(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _eventType = value);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Date picker
              //
              // Sliding window instead of hardcoded `DateTime(2020)`: the
              // hardcoded lower bound becomes more and more stale over time
              // (in 2030 a user could pick a 10-year-old date with no
              // breeding context). 5-year backward + 2-year forward window
              // matches realistic data-entry need.
              DatePickerField(
                label: 'calendar.event_date'.tr(),
                value: _eventDate,
                onChanged: (date) => setState(() => _eventDate = date),
                firstDate: DateTime(
                  DateTime.now().year - 5,
                  DateTime.now().month,
                  DateTime.now().day,
                ),
                lastDate: DateTime(
                  DateTime.now().year + 2,
                  DateTime.now().month,
                  DateTime.now().day,
                ),
                dateFormatter: ref.watch(dateFormatProvider).formatter(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Time picker
              _TimePickerField(
                eventTime: _eventTime,
                onTap: _pickTime,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Notes field
              // IMPROVED: add maxLength to prevent excessive input
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'calendar.event_notes'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(LucideIcons.stickyNote),
                ),
                maxLength: 500,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Save button
              FilledButton.icon(
                onPressed: formState.isLoading ? null : _submit,
                icon: formState.isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : _isEditing
                    ? const Icon(LucideIcons.save)
                    : const AppIcon(AppIcons.add),
                label: Text(
                  _isEditing
                      ? 'calendar.edit_event'.tr()
                      : 'calendar.add_event'.tr(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _eventTime,
      helpText: 'calendar.select_time'.tr(),
    );
    if (picked != null && mounted) {
      setState(() => _eventTime = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(currentUserIdProvider);
    final notifier = ref.read(eventFormStateProvider.notifier);

    final dateWithTime = DateTime(
      _eventDate.year,
      _eventDate.month,
      _eventDate.day,
      _eventTime.hour,
      _eventTime.minute,
    );
    // DST guard: when the chosen date crosses a forward DST boundary,
    // `DateTime(y,m,d,hour,minute)` may snap the hour into the next slot
    // (e.g. 02:30 → 03:30 on the spring-forward day). Detect and log so a
    // user-reported "reminder fired an hour off" can be traced back to the
    // picker rather than the scheduler. The full fix requires offering the
    // user the DST-shifted slot — out of scope here, but the breadcrumb
    // makes the issue investigable.
    if (dateWithTime.hour != _eventTime.hour) {
      AppLogger.warning(
        '[EventForm] DST snap: picker $_eventTime.hour → stored ${dateWithTime.hour} on ${_eventDate.toIso8601String()}',
      );
    }

    if (_isEditing) {
      notifier.updateEvent(
        widget.existingEvent!.copyWith(
          title: _titleController.text.trim(),
          eventDate: dateWithTime,
          type: _eventType,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        ),
      );
    } else {
      notifier.createEvent(
        userId: userId,
        title: _titleController.text.trim(),
        eventDate: dateWithTime,
        type: _eventType,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
    }
  }
}
