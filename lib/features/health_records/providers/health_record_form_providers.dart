import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_settings_providers.dart';
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
  }) =>
      HealthRecordFormState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isSuccess: isSuccess ?? this.isSuccess,
      );
}

/// Notifier for health record form actions.
class HealthRecordFormNotifier extends Notifier<HealthRecordFormState> {
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
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(healthRecordRepositoryProvider);
      final record = HealthRecord(
        id: const Uuid().v4(),
        userId: userId,
        title: title,
        type: type,
        date: date,
        birdId: birdId,
        description: description,
        treatment: treatment,
        veterinarian: veterinarian,
        notes: notes,
        weight: weight,
        cost: cost,
        followUpDate: followUpDate,
        createdAt: DateTime.now(),
      );
      await repo.save(record);

      // Schedule health check reminders if a bird is associated
      if (birdId != null) {
        await _scheduleHealthCheckReminders(
          birdId: birdId,
          birdName: title,
          followUpDate: followUpDate,
        );
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('HealthRecordFormNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Schedules health check reminders for the associated bird.
  ///
  /// If [followUpDate] is set, schedules daily reminders until that date.
  /// Otherwise schedules 7 days of daily reminders at 09:00.
  Future<void> _scheduleHealthCheckReminders({
    required String birdId,
    required String birdName,
    DateTime? followUpDate,
  }) async {
    try {
      final scheduler = ref.read(notificationSchedulerProvider);
      final settings = ref.read(notificationToggleSettingsProvider);

      final durationDays = followUpDate != null
          ? followUpDate.difference(DateTime.now()).inDays.clamp(1, 30)
          : 7;

      await scheduler.scheduleHealthCheckReminder(
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

  Future<void> updateRecord(HealthRecord record) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(healthRecordRepositoryProvider);
      await repo.save(record.copyWith(updatedAt: DateTime.now()));
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('HealthRecordFormNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteRecord(String id) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(healthRecordRepositoryProvider);
      await repo.remove(id);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('HealthRecordFormNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const HealthRecordFormState();
}

/// Provider for health record form state.
final healthRecordFormStateProvider =
    NotifierProvider<HealthRecordFormNotifier, HealthRecordFormState>(
        HealthRecordFormNotifier.new);
