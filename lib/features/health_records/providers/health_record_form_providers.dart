import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/gamification_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/date_utils.dart'
    as date_utils;
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/utils/sentry_error_filter.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/gamification/gamification_action_recorder.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_settings_providers.dart';
import 'package:uuid/uuid.dart';

/// Form state for health record create/edit.
class HealthRecordFormState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const HealthRecordFormState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  HealthRecordFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) => HealthRecordFormState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    isSuccess: isSuccess ?? this.isSuccess,
  );
}

/// Notifier for health record form actions.
class HealthRecordFormNotifier extends Notifier<HealthRecordFormState>
    with SentryErrorFilter {
  @override
  HealthRecordFormState build() => const HealthRecordFormState();

  Future<void> createRecord({
    required String userId,
    required String title,
    required HealthRecordType type,
    required DateTime date,
    String? birdId,
    String? description,
    String? treatment,
    String? veterinarian,
    String? notes,
    double? weight,
    double? cost,
    DateTime? followUpDate,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(healthRecordRepositoryProvider);
      final record = HealthRecord(
        id: const Uuid().v7(),
        userId: userId,
        title: title,
        type: type,
        date: date.toUtc(),
        birdId: birdId,
        description: description,
        treatment: treatment,
        veterinarian: veterinarian,
        notes: notes,
        weight: weight,
        cost: cost,
        followUpDate: followUpDate?.toUtc(),
        createdAt: DateTime.now().toUtc(),
      );
      await repo.save(record);

      recordGamificationAction(
        ref,
        userId: userId,
        action: XpAction.addHealthRecord,
        referenceId: record.id,
      );

      // Schedule health check reminders if a bird is associated
      if (birdId != null) {
        await _scheduleHealthCheckReminders(
          recordId: record.id,
          birdId: birdId,
          birdName: title,
          followUpDate: followUpDate,
        );
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('HealthRecordFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Schedules health check reminders for the associated bird.
  ///
  /// If [followUpDate] is set, schedules daily reminders until that date.
  /// Otherwise schedules 7 days of daily reminders at 09:00.
  Future<void> _scheduleHealthCheckReminders({
    required String recordId,
    required String birdId,
    required String birdName,
    DateTime? followUpDate,
  }) async {
    try {
      final scheduler = ref.read(notificationSchedulerProvider);
      final settings = await ref.read(
        notificationToggleSettingsReadyProvider.future,
      );

      final durationDays = followUpDate != null
          ? date_utils.DateUtils.dayDiff(
              DateTime.now(),
              followUpDate,
            ).clamp(1, 30)
          : 7;

      await scheduler.scheduleHealthCheckReminder(
        recordId: recordId,
        birdId: birdId,
        birdName: birdName,
        hour: 9,
        durationDays: durationDays,
        settings: settings,
      );
    } catch (e) {
      AppLogger.warning('Failed to schedule health check reminders: $e');
    }
  }

  /// Cancels previously-scheduled health check reminders for [record].
  ///
  /// Best-effort: a reminder-scheduling side effect failing must not undo
  /// the primary mutation (save/delete), which has already succeeded by
  /// the time this runs.
  Future<void> _cancelHealthCheckReminders(HealthRecord record) async {
    final birdId = record.birdId;
    if (birdId == null) return;
    try {
      final scheduler = ref.read(notificationSchedulerProvider);
      await scheduler.cancelHealthCheckReminders(birdId, recordId: record.id);
    } catch (e) {
      AppLogger.warning('Failed to cancel health check reminders: $e');
    }
  }

  Future<void> updateRecord(HealthRecord record) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(healthRecordRepositoryProvider);
      // Best-effort: this pre-fetch only informs the reminder cancel/
      // reschedule decision below. A failure here must not abort the
      // primary save — the same "side effect must not undo a successful
      // mutation" contract as _cancelHealthCheckReminders itself.
      HealthRecord? previous;
      try {
        previous = await repo.getById(record.id);
      } catch (e) {
        AppLogger.warning(
          'Failed to fetch previous health record for reminder diff: $e',
        );
      }
      await repo.save(record.copyWith(updatedAt: DateTime.now().toUtc()));

      // Reminders are scheduled off followUpDate/birdId — if either
      // changed, the previously-scheduled notifications now point at a
      // stale date or a bird that's no longer associated with this
      // record. Cancel and reschedule rather than leaving zombie
      // reminders firing on the old date (or none at all on the new one).
      final followUpChanged = previous?.followUpDate != record.followUpDate;
      final birdChanged = previous?.birdId != record.birdId;
      if (previous != null && (followUpChanged || birdChanged)) {
        await _cancelHealthCheckReminders(previous);
        if (record.birdId != null) {
          await _scheduleHealthCheckReminders(
            recordId: record.id,
            birdId: record.birdId!,
            birdName: record.title,
            followUpDate: record.followUpDate,
          );
        }
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('HealthRecordFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  Future<void> deleteRecord(String id) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(healthRecordRepositoryProvider);
      // Best-effort: only needed to know which reminders to cancel. A
      // failure here must not abort the primary delete.
      HealthRecord? existing;
      try {
        existing = await repo.getById(id);
      } catch (e) {
        AppLogger.warning(
          'Failed to fetch health record before delete for reminder '
          'cancellation: $e',
        );
      }
      await repo.remove(id);
      if (existing != null) {
        await _cancelHealthCheckReminders(existing);
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('HealthRecordFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  void reset() => state = const HealthRecordFormState();
}

/// Provider for health record form state.
final healthRecordFormStateProvider =
    NotifierProvider<HealthRecordFormNotifier, HealthRecordFormState>(
      HealthRecordFormNotifier.new,
    );
