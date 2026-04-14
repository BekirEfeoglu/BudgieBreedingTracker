import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/date_picker_field.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/providers/calendar_form_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/date_format_providers.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_card.dart';
import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';

part 'event_form_fields.dart';

/// Opens the event form as a modal bottom sheet.
Future<void> showEventFormSheet(
  BuildContext context, {
  Event? existingEvent,
  DateTime? initialDate,
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
      _titleController.text = existing.title;
      _notesController.text = existing.notes ?? '';
      _eventDate = existing.eventDate;
      _eventTime = TimeOfDay(
        hour: existing.eventDate.hour,
        minute: existing.eventDate.minute,
      );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('errors.unknown'.tr())));
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
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'calendar.event_title'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(LucideIcons.type),
                ),
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
                  prefixIcon: Icon(eventTypeIcon(_eventType)),
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
              DatePickerField(
                label: 'calendar.event_date'.tr(),
                value: _eventDate,
                onChanged: (date) => setState(() => _eventDate = date),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 730)),
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
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'calendar.event_notes'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(LucideIcons.stickyNote),
                ),
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
