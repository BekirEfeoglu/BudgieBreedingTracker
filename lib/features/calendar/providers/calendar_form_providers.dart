import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/reminder_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/utils/sentry_error_filter.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/models/event_reminder_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_ids.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:uuid/uuid.dart';

/// Default reminder window for calendar events (minutes before).
const int kDefaultReminderMinutesBefore = 30;

/// Reminder offsets the event form offers, in minutes before the event.
/// `null` means "no reminder". Kept here so the provider and the form widget
/// agree on the exact set (and the default).
const List<int?> kReminderOffsetOptions = <int?>[
  null, // no reminder
  0, // at time of event
  30, // 30 minutes before (default)
  60, // 1 hour before
  1440, // 1 day before
];

/// State for the event form.
@immutable
class EventFormState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const EventFormState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  EventFormState copyWith({bool? isLoading, String? error, bool? isSuccess}) {
    return EventFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventFormState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          error == other.error &&
          isSuccess == other.isSuccess;

  @override
  int get hashCode => Object.hash(isLoading, error, isSuccess);
}

/// Notifier for event form operations.
class EventFormNotifier extends Notifier<EventFormState>
    with SentryErrorFilter {
  @override
  EventFormState build() => const EventFormState();

  /// Creates a new event.
  ///
  /// [reminderMinutesBefore] controls the reminder offset: the default
  /// ([kDefaultReminderMinutesBefore]) preserves the historic 30-minutes-before
  /// behavior, `0` fires at the event time, and `null` creates no reminder.
  Future<void> createEvent({
    required String userId,
    required String title,
    required DateTime eventDate,
    required EventType type,
    EventStatus status = EventStatus.active,
    String? notes,
    String? birdId,
    String? breedingPairId,
    int? reminderMinutesBefore = kDefaultReminderMinutesBefore,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(eventRepositoryProvider);
      final event = Event(
        id: const Uuid().v7(),
        title: title,
        eventDate: eventDate.toUtc(),
        type: type,
        userId: userId,
        status: status,
        notes: notes,
        birdId: birdId,
        breedingPairId: breedingPairId,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      await repo.save(event);
      // Schedule the reminder (unless the user chose "no reminder").
      // notification_processor picks up unsent reminders on its next tick and
      // schedules an OS notification.
      if (reminderMinutesBefore != null) {
        await _createReminder(event, reminderMinutesBefore);
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('EventFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(
        isLoading: false,
        error: 'errors.save_failed'.tr(),
      );
    }
  }

  /// Updates an existing event.
  ///
  /// When [reconcileReminder] is true (the edit form now manages reminders),
  /// [reminderMinutesBefore] fully replaces the event's reminder: any existing
  /// reminders are cancelled + removed, then the chosen offset is re-created
  /// (`null` = no reminder). When false (other callers, e.g. a status change),
  /// the legacy behavior applies: reminders are only re-armed if the date
  /// shifted, so the offset the user picked at creation is preserved.
  Future<void> updateEvent(
    Event event, {
    int? reminderMinutesBefore,
    bool reconcileReminder = false,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(eventRepositoryProvider);
      final previous = await repo.getById(event.id);
      await repo.save(event.copyWith(updatedAt: DateTime.now().toUtc()));
      if (reconcileReminder) {
        // Replace the reminder with the user's edited choice: drop the old
        // one(s) (cancels their OS notifications) and re-create if chosen. The
        // notification processor re-arms the fresh reminder on its next tick.
        await _cleanupRemindersForEvent(event.id);
        if (reminderMinutesBefore != null) {
          await _createReminder(event, reminderMinutesBefore);
        }
      } else {
        // If the event time shifted, cancel any already-scheduled OS
        // notification(s) and re-arm pending reminders so the processor
        // re-schedules with the new triggerTime on its next tick.
        final dateShifted =
            previous == null ||
            !previous.eventDate.isAtSameMomentAs(event.eventDate);
        if (dateShifted) {
          await _resetRemindersForReschedule(event.id);
        }
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('EventFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(
        isLoading: false,
        error: 'errors.update_failed'.tr(),
      );
    }
  }

  /// Soft-deletes an event.
  Future<void> deleteEvent(String id) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(eventRepositoryProvider);
      // Cancel OS notifications and soft-delete reminders BEFORE the event
      // is removed; otherwise a sync push of the orphan reminder may fail
      // FK validation.
      await _cleanupRemindersForEvent(id);
      await repo.remove(id);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('EventFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(
        isLoading: false,
        error: 'errors.delete_failed'.tr(),
      );
    }
  }

  /// Persists a reminder [minutesBefore] the event for newly created events.
  /// Failure is logged but does not block event creation (degraded
  /// notification UX beats lost data).
  Future<void> _createReminder(Event event, int minutesBefore) async {
    try {
      final reminderRepo = ref.read(eventReminderRepositoryProvider);
      final now = DateTime.now();
      await reminderRepo.save(
        EventReminder(
          id: const Uuid().v7(),
          userId: event.userId,
          eventId: event.id,
          minutesBefore: minutesBefore,
          type: ReminderType.notification,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } catch (e, st) {
      AppLogger.warning(
        '[EventFormNotifier] Default reminder create failed for ${event.id}: $e',
      );
      reportIfUnexpected(e, st);
    }
  }

  /// Cancels any scheduled OS notification for [eventId]'s reminders and
  /// soft-deletes them in Drift. Best-effort: failures are logged so the
  /// primary event delete still completes.
  Future<void> _cleanupRemindersForEvent(String eventId) async {
    try {
      final reminderRepo = ref.read(eventReminderRepositoryProvider);
      final notifService = ref.read(notificationServiceProvider);
      final reminders = await reminderRepo.getByEvent(eventId);
      for (final reminder in reminders) {
        final notificationId = NotificationIds.generate(
          NotificationIds.eventReminderBaseId,
          reminder.id,
          0,
        );
        await notifService.cancel(notificationId);
        await reminderRepo.remove(reminder.id);
      }
    } catch (e, st) {
      AppLogger.warning(
        '[EventFormNotifier] Reminder cleanup failed for $eventId: $e',
      );
      reportIfUnexpected(e, st);
    }
  }

  /// Resets reminders so the processor reschedules them. Cancels the
  /// previously scheduled OS notification (if any), marks the reminder
  /// unsent, and lets `notification_processor` re-arm on its next tick.
  Future<void> _resetRemindersForReschedule(String eventId) async {
    try {
      final reminderRepo = ref.read(eventReminderRepositoryProvider);
      final notifService = ref.read(notificationServiceProvider);
      final reminders = await reminderRepo.getByEvent(eventId);
      final now = DateTime.now();
      for (final reminder in reminders) {
        if (!reminder.isSent) continue;
        final notificationId = NotificationIds.generate(
          NotificationIds.eventReminderBaseId,
          reminder.id,
          0,
        );
        await notifService.cancel(notificationId);
        await reminderRepo.save(
          reminder.copyWith(isSent: false, updatedAt: now),
        );
      }
    } catch (e, st) {
      AppLogger.warning(
        '[EventFormNotifier] Reminder reschedule reset failed for $eventId: $e',
      );
      reportIfUnexpected(e, st);
    }
  }

  /// Updates the status of an event.
  ///
  /// Shares [state.isLoading] with `createEvent`/`updateEvent`. If a save is
  /// already in flight, this status update is silently ignored — the user's
  /// next tap or screen re-entry will succeed once that save completes.
  /// Acceptable trade-off because status changes are sub-100ms in practice
  /// and a parallel transaction would compete on the same row anyway.
  Future<void> updateEventStatus(String id, EventStatus newStatus) async {
    if (state.isLoading) {
      AppLogger.debug(
        '[EventFormNotifier] status update for $id ignored — save in flight',
      );
      return;
    }
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(eventRepositoryProvider);
      final event = await repo.getById(id);
      if (event != null) {
        await repo.save(
          event.copyWith(status: newStatus, updatedAt: DateTime.now().toUtc()),
        );
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('EventFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(
        isLoading: false,
        error: 'errors.update_failed'.tr(),
      );
    }
  }

  /// Resets form state for a new operation.
  void reset() {
    state = const EventFormState();
  }

  /// Clears just the error field so the UI doesn't replay the same SnackBar
  /// when the listener re-fires for an unrelated state change.
  void clearError() {
    if (state.error == null) return;
    state = state.copyWith(error: null);
  }
}

/// Form state and actions for creating/editing events.
final eventFormStateProvider =
    NotifierProvider<EventFormNotifier, EventFormState>(EventFormNotifier.new);
