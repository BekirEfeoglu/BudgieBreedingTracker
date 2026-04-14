part of 'chick_form_providers.dart';

/// Notifier for chick form operations.
class ChickFormNotifier extends Notifier<ChickFormState> with SentryErrorFilter {
  @override
  ChickFormState build() => const ChickFormState();

  /// Creates a new chick.
  Future<void> createChick({
    required String userId,
    String? name,
    BirdGender gender = BirdGender.unknown,
    ChickHealthStatus healthStatus = ChickHealthStatus.healthy,
    String? clutchId,
    String? eggId,
    required DateTime hatchDate,
    double? hatchWeight,
    String? ringNumber,
    String? notes,
    int bandingDay = 10,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      error: null,
      warning: null,
      isSuccess: false,
    );
    try {
      final repo = ref.read(chickRepositoryProvider);
      final sideEffectErrors = <String>[];
      final chick = Chick(
        id: const Uuid().v7(),
        userId: userId,
        name: name,
        gender: gender,
        healthStatus: healthStatus,
        clutchId: clutchId,
        eggId: eggId,
        hatchDate: hatchDate,
        hatchWeight: hatchWeight,
        ringNumber: ringNumber,
        notes: notes,
        bandingDay: bandingDay,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.save(chick);

      // Schedule chick care reminders (feeding every 4 hours for 14 days)
      try {
        final scheduler = ref.read(notificationSchedulerProvider);
        final settings = ref.read(notificationToggleSettingsProvider);
        await scheduler.scheduleChickCareReminder(
          chickId: chick.id,
          chickLabel: _chickLabel(name, ringNumber, chick.id),
          startDate: hatchDate,
          intervalHours: 4,
          durationDays: 14,
          settings: settings,
        );
      } catch (e) {
        AppLogger.warning('Failed to schedule chick care reminders: $e');
        sideEffectErrors.add('chick_care');
      }

      // Schedule banding reminders
      try {
        final scheduler = ref.read(notificationSchedulerProvider);
        final settings = ref.read(notificationToggleSettingsProvider);
        await scheduler.scheduleBandingReminders(
          chickId: chick.id,
          chickLabel: _chickLabel(name, ringNumber, chick.id),
          hatchDate: hatchDate,
          bandingDay: bandingDay,
          settings: settings,
        );
      } catch (e) {
        AppLogger.warning('Failed to schedule banding reminders: $e');
        sideEffectErrors.add('banding');
      }

      // Auto-generate chick milestone calendar events
      try {
        final calendarGen = ref.read(calendarEventGeneratorProvider);
        await calendarGen.generateChickEvents(
          userId: userId,
          hatchDate: hatchDate,
          chickLabel: _chickLabel(name, ringNumber, chick.id),
          chickId: chick.id,
          bandingDay: bandingDay,
        );
      } catch (e) {
        if (isSupabaseUnavailableError(e)) {
          AppLogger.info(
            'Skipping chick calendar generation: Supabase is not initialized',
          );
        } else {
          AppLogger.warning('Failed to generate chick calendar events: $e');
          sideEffectErrors.add('calendar');
        }
      }

      state = state.copyWith(
        isLoading: false,
        warning: sideEffectErrors.isNotEmpty
            ? 'errors.background_tasks_partial'.tr()
            : null,
        isSuccess: true,
      );
    } catch (e, st) {
      AppLogger.error('ChickFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Updates an existing chick.
  Future<void> updateChick(Chick chick, {Chick? previous}) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      error: null,
      warning: null,
      isSuccess: false,
    );
    try {
      final repo = ref.read(chickRepositoryProvider);
      await repo.save(chick.copyWith(updatedAt: DateTime.now()));
      var sideEffectError = false;

      // Reschedule banding reminders if bandingDay changed
      if (previous != null && previous.bandingDay != chick.bandingDay && !chick.isBanded) {
        try {
          final scheduler = ref.read(notificationSchedulerProvider);
          final settings = ref.read(notificationToggleSettingsProvider);
          await scheduler.cancelBandingReminders(chick.id);
          if (chick.hatchDate != null) {
            await scheduler.scheduleBandingReminders(
              chickId: chick.id,
              chickLabel: chick.name ?? chick.id.substring(0, 6),
              hatchDate: chick.hatchDate!,
              bandingDay: chick.bandingDay,
              settings: settings,
            );
          }
        } catch (e) {
          AppLogger.warning('Failed to reschedule banding reminders: $e');
          sideEffectError = true;
        }
      }

      state = state.copyWith(
        isLoading: false,
        warning: sideEffectError ? 'errors.background_tasks_partial'.tr() : null,
        isSuccess: true,
      );
    } catch (e, st) {
      AppLogger.error('ChickFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Soft-deletes a chick.
  Future<void> deleteChick(String id) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, warning: null);
    try {
      final repo = ref.read(chickRepositoryProvider);
      await repo.remove(id);
      var sideEffectError = false;
      try {
        final scheduler = ref.read(notificationSchedulerProvider);
        await scheduler.cancelBandingReminders(id);
      } catch (e) {
        AppLogger.warning('Failed to cancel banding reminders: $e');
        sideEffectError = true;
      }
      state = state.copyWith(
        isLoading: false,
        warning: sideEffectError ? 'errors.background_tasks_partial'.tr() : null,
        isSuccess: true,
      );
    } catch (e, st) {
      AppLogger.error('ChickFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Returns a display label for a chick (name or fallback).
  String _chickLabel(String? name, String? ringNumber, String chickId) {
    return name ??
        'chicks.unnamed_chick'.tr(
          args: [ringNumber ?? chickId.substring(0, 6)],
        );
  }

  /// Resets form state for a new operation.
  void reset() {
    state = const ChickFormState();
  }
}
