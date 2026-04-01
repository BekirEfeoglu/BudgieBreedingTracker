import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/utils/sentry_error_filter.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:uuid/uuid.dart';

/// State for the event form.
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
}

/// Notifier for event form operations.
class EventFormNotifier extends Notifier<EventFormState> with SentryErrorFilter {
  @override
  EventFormState build() => const EventFormState();

  /// Creates a new event.
  Future<void> createEvent({
    required String userId,
    required String title,
    required DateTime eventDate,
    required EventType type,
    EventStatus status = EventStatus.active,
    String? notes,
    String? birdId,
    String? breedingPairId,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(eventRepositoryProvider);
      final event = Event(
        id: const Uuid().v7(),
        title: title,
        eventDate: eventDate,
        type: type,
        userId: userId,
        status: status,
        notes: notes,
        birdId: birdId,
        breedingPairId: breedingPairId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.save(event);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('EventFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.save_failed'.tr());
    }
  }

  /// Updates an existing event.
  Future<void> updateEvent(Event event) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(eventRepositoryProvider);
      await repo.save(event.copyWith(updatedAt: DateTime.now()));
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('EventFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.update_failed'.tr());
    }
  }

  /// Soft-deletes an event.
  Future<void> deleteEvent(String id) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(eventRepositoryProvider);
      await repo.remove(id);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('EventFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.delete_failed'.tr());
    }
  }

  /// Updates the status of an event.
  Future<void> updateEventStatus(String id, EventStatus newStatus) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(eventRepositoryProvider);
      final event = await repo.getById(id);
      if (event != null) {
        await repo.save(
          event.copyWith(status: newStatus, updatedAt: DateTime.now()),
        );
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('EventFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.update_failed'.tr());
    }
  }

  /// Resets form state for a new operation.
  void reset() {
    state = const EventFormState();
  }
}

/// Form state and actions for creating/editing events.
final eventFormStateProvider =
    NotifierProvider<EventFormNotifier, EventFormState>(EventFormNotifier.new);
