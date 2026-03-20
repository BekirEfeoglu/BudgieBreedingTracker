import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_settings_providers.dart';
import 'package:uuid/uuid.dart';

/// All eggs for a user (live stream).
///
/// Single source of truth - imported by home, breeding, and statistics.
final eggsStreamProvider = StreamProvider.family<List<Egg>, String>((
  ref,
  userId,
) {
  final repo = ref.watch(eggRepositoryProvider);
  return repo.watchAll(userId);
});

/// Eggs for a specific incubation (live stream).
final eggsForIncubationProvider = StreamProvider.family<List<Egg>, String>((
  ref,
  incubationId,
) {
  final repo = ref.watch(eggRepositoryProvider);
  return repo.watchByIncubation(incubationId);
});

class EggActionsState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final bool chickCreated;

  const EggActionsState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.chickCreated = false,
  });

  EggActionsState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    bool? chickCreated,
  }) {
    return EggActionsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
      chickCreated: chickCreated ?? this.chickCreated,
    );
  }
}

class EggActionsNotifier extends Notifier<EggActionsState> {
  @override
  EggActionsState build() => const EggActionsState();

  /// Adds a new egg to an incubation.
  Future<void> addEgg({
    required String incubationId,
    required DateTime layDate,
    required int eggNumber,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(eggRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);

      final egg = Egg(
        id: const Uuid().v4(),
        userId: userId,
        incubationId: incubationId,
        layDate: layDate,
        eggNumber: eggNumber,
        status: EggStatus.incubating,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.save(egg);

      // Schedule egg turning reminders
      try {
        final scheduler = ref.read(notificationSchedulerProvider);
        final settings = ref.read(notificationToggleSettingsProvider);
        await scheduler.scheduleEggTurningReminders(
          eggId: egg.id,
          startDate: layDate,
          eggLabel: 'eggs.egg_label'.tr(args: ['$eggNumber']),
          settings: settings,
        );
      } catch (e) {
        AppLogger.warning('Failed to schedule egg reminders: $e');
      }

      // Auto-generate expected hatch date calendar event
      try {
        final calendarGen = ref.read(calendarEventGeneratorProvider);
        await calendarGen.generateEggEvents(
          userId: userId,
          layDate: layDate,
          eggNumber: eggNumber,
          incubationId: incubationId,
        );
      } catch (e) {
        if (_isSupabaseUnavailableError(e)) {
          AppLogger.info(
            'Skipping egg calendar generation: Supabase is not initialized',
          );
        } else {
          AppLogger.warning('Failed to generate egg calendar event: $e');
        }
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('EggActionsNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Updates the status of an existing egg.
  Future<void> updateEggStatus(Egg egg, EggStatus newStatus) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      isSuccess: false,
      chickCreated: false,
    );
    try {
      final repo = ref.read(eggRepositoryProvider);

      var updated = egg.copyWith(status: newStatus, updatedAt: DateTime.now());

      if (newStatus == EggStatus.hatched) {
        updated = updated.copyWith(hatchDate: DateTime.now());
      } else if (newStatus == EggStatus.fertile) {
        updated = updated.copyWith(fertileCheckDate: DateTime.now());
      } else if (newStatus == EggStatus.discarded) {
        updated = updated.copyWith(discardDate: DateTime.now());
      }

      await repo.save(updated);

      // Automatically create chick when egg hatches
      var didCreateChick = false;
      if (newStatus == EggStatus.hatched) {
        didCreateChick = await _createChickFromHatchedEgg(updated);
      }

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        chickCreated: didCreateChick,
      );
    } catch (e) {
      AppLogger.error('EggActionsNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Creates a chick record automatically when an egg is marked as hatched.
  /// Returns true if a new chick was created, false if already exists.
  Future<bool> _createChickFromHatchedEgg(Egg egg) async {
    try {
      final chickRepo = ref.read(chickRepositoryProvider);

      // Duplicate check: skip if chick already exists for this egg
      final existing = await chickRepo.getByEggId(egg.id);
      if (existing != null) {
        AppLogger.info('Chick already exists for egg: ${egg.id}, skipping');
        return false;
      }

      final hatchDate = egg.hatchDate ?? DateTime.now();

      final chick = Chick(
        id: const Uuid().v4(),
        userId: egg.userId,
        eggId: egg.id,
        clutchId: egg.clutchId,
        hatchDate: hatchDate,
        gender: BirdGender.unknown,
        healthStatus: ChickHealthStatus.healthy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await chickRepo.save(chick);

      final chickLabel = 'chicks.unnamed_chick'.tr(
        args: ['${egg.eggNumber ?? chick.id.substring(0, 6)}'],
      );

      // Schedule chick care reminders
      try {
        final scheduler = ref.read(notificationSchedulerProvider);
        final chickSettings = ref.read(notificationToggleSettingsProvider);
        await scheduler.scheduleChickCareReminder(
          chickId: chick.id,
          chickLabel: chickLabel,
          startDate: hatchDate,
          intervalHours: 4,
          durationDays: 14,
          settings: chickSettings,
        );
      } catch (e) {
        AppLogger.warning('Failed to schedule chick care reminders: $e');
      }

      // Auto-generate chick milestone calendar events
      try {
        final calendarGen = ref.read(calendarEventGeneratorProvider);
        await calendarGen.generateChickEvents(
          userId: egg.userId,
          hatchDate: hatchDate,
          chickLabel: chickLabel,
        );
      } catch (e) {
        if (_isSupabaseUnavailableError(e)) {
          AppLogger.info(
            'Skipping chick calendar generation: Supabase is not initialized',
          );
        } else {
          AppLogger.warning('Failed to generate chick calendar events: $e');
        }
      }

      AppLogger.info('Chick auto-created from hatched egg: ${egg.id}');
      return true;
    } catch (e) {
      AppLogger.error('Failed to auto-create chick from egg', e);
      return false;
    }
  }

  /// Soft-deletes an egg.
  Future<void> deleteEgg(String id) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(eggRepositoryProvider);
      await repo.remove(id);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('EggActionsNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Resets the action state.
  void reset() {
    state = const EggActionsState();
  }

  bool _isSupabaseUnavailableError(Object error) {
    final message = error.toString();
    return message.contains('You must initialize the supabase instance') ||
        message.contains('provider that is in error state');
  }
}

/// Actions notifier for egg CRUD operations.
final eggActionsProvider =
    NotifierProvider<EggActionsNotifier, EggActionsState>(
      EggActionsNotifier.new,
    );
