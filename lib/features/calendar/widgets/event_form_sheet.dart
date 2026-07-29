import 'dart:async';

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
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/providers/calendar_form_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/date_format_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_card.dart';
import 'package:budgie_breeding_tracker/core/providers/action_feedback_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/app_icon_button.dart';

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
    showCloseButton: false,
    constraints: const BoxConstraints(maxWidth: AppSpacing.maxSheetWidth),
    useRootNavigator: true,
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

  /// Dropdown value for the reminder offset. `DropdownButtonFormField` mishandles
  /// a null item value (it shows the hint instead of the item), so "no reminder"
  /// is carried as this sentinel and converted back to `null` at submit time.
  static const int _noReminderSentinel = -1;
  int _reminderChoice = kDefaultReminderMinutesBefore;
  bool _isReminderLoading = false;
  bool _hasReminderLoadError = false;
  int _reminderFieldVersion = 0;

  bool get _isEditing => widget.existingEvent != null;

  /// Localized label for a reminder offset (minutes before; `null` = none).
  String _reminderOptionLabel(int? minutes) {
    switch (minutes) {
      case null:
        return 'calendar.reminder_none'.tr();
      case 0:
        return 'calendar.reminder_at_time'.tr();
      case 60:
        return 'calendar.reminder_1_hour'.tr();
      case 1440:
        return 'calendar.reminder_1_day'.tr();
      default:
        return 'calendar.reminder_minutes_before'.tr(
          namedArgs: {'minutes': '$minutes'},
        );
    }
  }

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
      // Load the event's current reminder so the dropdown reflects it in edit
      // mode (and the user can change/remove it).
      _isReminderLoading = true;
      unawaited(_loadExistingReminder(existing.id));
    } else {
      _eventDate = widget.initialDate ?? DateTime.now();
      _eventTime = TimeOfDay.now();
      _eventType = EventType.custom;
    }
  }

  /// Reads the event's existing reminder offset into [_reminderChoice] so the
  /// edit form opens showing the current setting (or "no reminder").
  Future<void> _loadExistingReminder(String eventId) async {
    if (!_isReminderLoading || _hasReminderLoadError) {
      setState(() {
        _isReminderLoading = true;
        _hasReminderLoadError = false;
      });
    }
    try {
      final reminders = await ref
          .read(eventReminderRepositoryProvider)
          .getByEvent(eventId);
      if (!mounted) return;
      setState(() {
        _reminderChoice = reminders.isEmpty
            ? _noReminderSentinel
            : reminders.first.minutesBefore;
        _isReminderLoading = false;
        _hasReminderLoadError = false;
        // FormField.initialValue is consumed only when its State is created.
        // Re-key once after async hydration so the displayed selection and the
        // value submitted by this State cannot diverge.
        _reminderFieldVersion++;
      });
    } catch (e, st) {
      AppLogger.error(
        '[EventForm] Failed to load reminder for $eventId',
        e,
        st,
      );
      if (!mounted) return;
      setState(() {
        _isReminderLoading = false;
        _hasReminderLoadError = true;
      });
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
    final isBusy = formState.isLoading || _isReminderLoading;
    final canSubmit = !isBusy && !_hasReminderLoadError;

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing
                          ? 'calendar.edit_event'.tr()
                          : 'calendar.add_event'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AppIconButton(
                    key: const Key('event_form_close_button'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x),
                    semanticLabel: 'common.close'.tr(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

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
              _TimePickerField(eventTime: _eventTime, onTap: _pickTime),
              const SizedBox(height: AppSpacing.lg),

              // Reminder offset — shown for both create and edit. In edit
              // mode the dropdown is pre-filled from the event's current
              // reminder and any change is reconciled on save.
              DropdownButtonFormField<int>(
                key: ValueKey(_reminderFieldVersion),
                initialValue: _reminderChoice,
                // Fill the field width and ellipsize long localized labels
                // instead of overflowing the row (e.g. German "Zum
                // Ereigniszeitpunkt").
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'calendar.reminder_label'.tr(),
                  helperText: _isReminderLoading ? 'common.loading'.tr() : null,
                  errorText: _hasReminderLoadError
                      ? 'common.data_load_error'.tr()
                      : null,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(LucideIcons.bell),
                ),
                items: [
                  for (final minutes in kReminderOffsetOptions)
                    DropdownMenuItem<int>(
                      value: minutes ?? _noReminderSentinel,
                      child: Text(_reminderOptionLabel(minutes)),
                    ),
                ],
                onChanged: isBusy || _hasReminderLoadError
                    ? null
                    : (value) => setState(
                        () => _reminderChoice =
                            value ?? kDefaultReminderMinutesBefore,
                      ),
              ),
              if (_hasReminderLoadError)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: () =>
                        _loadExistingReminder(widget.existingEvent!.id),
                    icon: const Icon(LucideIcons.refreshCw),
                    label: Text('common.retry'.tr()),
                  ),
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
                onPressed: canSubmit ? _submit : null,
                icon: isBusy
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
    if (_isReminderLoading || _hasReminderLoadError) return;
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
        reminderMinutesBefore: _reminderChoice == _noReminderSentinel
            ? null
            : _reminderChoice,
        reconcileReminder: true,
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
        reminderMinutesBefore: _reminderChoice == _noReminderSentinel
            ? null
            : _reminderChoice,
      );
    }
  }
}
