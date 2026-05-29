part of 'chick_form_providers.dart';

/// Notifier for chick form operations.
class ChickFormNotifier extends Notifier<ChickFormState>
    with SentryErrorFilter {
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
      } catch (e, st) {
        // Best-effort side effect: AppLogger.warning has no stackTrace param,
        // so append it to the message to retain it for diagnosis.
        AppLogger.warning('Failed to schedule chick care reminders: $e\n$st');
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
      } catch (e, st) {
        // Best-effort side effect: AppLogger.warning has no stackTrace param,
        // so append it to the message to retain it for diagnosis.
        AppLogger.warning('Failed to schedule banding reminders: $e\n$st');
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
      } catch (e, st) {
        if (isSupabaseUnavailableError(e)) {
          AppLogger.info(
            'Skipping chick calendar generation: Supabase is not initialized',
          );
        } else {
          AppLogger.warning(
            'Failed to generate chick calendar events: $e\n$st',
          );
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
      if (previous != null &&
          previous.bandingDay != chick.bandingDay &&
          !chick.isBanded) {
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
        } catch (e, st) {
          AppLogger.warning(
            'Failed to reschedule banding reminders: $e\n$st',
          );
          sideEffectError = true;
        }
      }

      state = state.copyWith(
        isLoading: false,
        warning: sideEffectError
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

  /// Soft-deletes a chick.
  Future<void> deleteChick(String id) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, warning: null);
    try {
      final repo = ref.read(chickRepositoryProvider);
      await repo.remove(id);
      final sideEffectError = await _cancelChickReminders(
        ref,
        id,
        cancelCare: true,
        cancelBanding: true,
      );
      // Drop calendar entries (banding, care reminders, …) for this chick.
      bool eventCleanupFailed = false;
      try {
        await ref.read(eventRepositoryProvider).removeByChickIds([id]);
      } catch (e, st) {
        eventCleanupFailed = true;
        AppLogger.warning(
          'Failed to delete calendar events for chick $id: $e\n$st',
        );
      }
      // Cascade-remove growth measurements. growth_measurements has no
      // isDeleted column, so soft-delete isn't an option — leaving the
      // rows behind would resurface them as permanent sync errors once
      // the parent chick is tombstoned (ValidatedSyncMixin would mark
      // the measurement orphan on every push).
      bool growthCleanupFailed = false;
      try {
        await ref
            .read(growthMeasurementRepositoryProvider)
            .removeByChickIds([id]);
      } catch (e, st) {
        growthCleanupFailed = true;
        AppLogger.warning(
          'Failed to delete growth measurements for chick $id: $e\n$st',
        );
      }
      // The delete itself succeeded (soft-delete is done); these cleanups are
      // best-effort and must not block. A failed growth-measurement cleanup is
      // worth flagging more specifically than the generic background-tasks
      // warning, because those orphaned rows would otherwise surface as
      // recurring sync errors on every push (no isDeleted column to tombstone).
      final String? cleanupWarning;
      if (growthCleanupFailed) {
        cleanupWarning = 'errors.chick_cleanup_partial'.tr();
      } else if (sideEffectError || eventCleanupFailed) {
        cleanupWarning = 'errors.background_tasks_partial'.tr();
      } else {
        cleanupWarning = null;
      }
      state = state.copyWith(
        isLoading: false,
        warning: cleanupWarning,
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
