import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_settings_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:uuid/uuid.dart';

/// Male birds available for pairing (derived from birdsStreamProvider).
final maleBirdsProvider = Provider.family<List<Bird>, String>((ref, userId) {
  final birds = ref.watch(birdsStreamProvider(userId)).value ?? <Bird>[];
  return birds.where((b) => b.gender == BirdGender.male).toList();
});

/// Female birds available for pairing (derived from birdsStreamProvider).
final femaleBirdsProvider = Provider.family<List<Bird>, String>((ref, userId) {
  final birds = ref.watch(birdsStreamProvider(userId)).value ?? <Bird>[];
  return birds.where((b) => b.gender == BirdGender.female).toList();
});

/// Form state and actions for creating/editing breeding pairs.
final breedingFormStateProvider =
    NotifierProvider<BreedingFormNotifier, BreedingFormState>(
      BreedingFormNotifier.new,
    );

class BreedingFormState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final bool isBreedingLimitReached;
  final bool isIncubationLimitReached;

  const BreedingFormState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.isBreedingLimitReached = false,
    this.isIncubationLimitReached = false,
  });

  BreedingFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    bool? isBreedingLimitReached,
    bool? isIncubationLimitReached,
  }) {
    return BreedingFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
      isBreedingLimitReached: isBreedingLimitReached ?? false,
      isIncubationLimitReached: isIncubationLimitReached ?? false,
    );
  }
}

class BreedingFormNotifier extends Notifier<BreedingFormState> {
  @override
  BreedingFormState build() => const BreedingFormState();

  /// Creates a new breeding pair and its associated incubation atomically.
  Future<void> createBreeding({
    required String userId,
    required String maleId,
    required String femaleId,
    required DateTime pairingDate,
    String? cageNumber,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final pairRepo = ref.read(breedingPairRepositoryProvider);
      final incubationRepo = ref.read(incubationRepositoryProvider);

      // Free tier limit checks
      final isPremium = ref.read(isPremiumProvider);
      if (!isPremium) {
        final existingPairs = await pairRepo.getAll(userId);
        final activePairs = existingPairs
            .where(
              (p) =>
                  p.status == BreedingStatus.active ||
                  p.status == BreedingStatus.ongoing,
            )
            .length;
        if (activePairs >= AppConstants.freeTierMaxBreedingPairs) {
          state = state.copyWith(
            isLoading: false,
            error: 'premium.breeding_limit_reached'.tr(
              args: ['${AppConstants.freeTierMaxBreedingPairs}'],
            ),
            isBreedingLimitReached: true,
          );
          return;
        }

        final existingIncubations = await incubationRepo.getAll(userId);
        final activeIncubations = existingIncubations
            .where((i) => i.status == IncubationStatus.active)
            .length;
        if (activeIncubations >= AppConstants.freeTierMaxActiveIncubations) {
          state = state.copyWith(
            isLoading: false,
            error: 'premium.incubation_limit_reached'.tr(
              args: ['${AppConstants.freeTierMaxActiveIncubations}'],
            ),
            isIncubationLimitReached: true,
          );
          return;
        }
      }

      final pairId = const Uuid().v4();
      final incubationId = const Uuid().v4();

      final pair = BreedingPair(
        id: pairId,
        userId: userId,
        status: BreedingStatus.active,
        maleId: maleId,
        femaleId: femaleId,
        cageNumber: cageNumber,
        notes: notes,
        pairingDate: pairingDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final incubation = Incubation(
        id: incubationId,
        userId: userId,
        status: IncubationStatus.active,
        breedingPairId: pairId,
        startDate: pairingDate,
        expectedHatchDate: pairingDate.add(const Duration(days: 18)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await pairRepo.save(pair);
      await incubationRepo.save(incubation);

      // Schedule incubation milestone + egg turning notifications
      try {
        final scheduler = ref.read(notificationSchedulerProvider);
        final settings = ref.read(notificationToggleSettingsProvider);
        final pairLabel = 'breeding.pair_label'.tr(
          args: [pairId.substring(0, 6)],
        );

        await scheduler.scheduleIncubationMilestones(
          incubationId: incubationId,
          startDate: pairingDate,
          label: pairLabel,
          settings: settings,
        );

        await scheduler.scheduleEggTurningReminders(
          eggId: incubationId,
          startDate: pairingDate,
          eggLabel: pairLabel,
          settings: settings,
        );
      } catch (e) {
        AppLogger.warning('Failed to schedule notifications: $e');
      }

      // Auto-generate calendar events for incubation milestones
      try {
        final calendarGen = ref.read(calendarEventGeneratorProvider);
        await calendarGen.generateIncubationEvents(
          userId: userId,
          breedingPairId: pairId,
          startDate: pairingDate,
          pairLabel: 'breeding.pair_label'.tr(args: [pairId.substring(0, 6)]),
        );
      } catch (e) {
        if (_isSupabaseUnavailableError(e)) {
          AppLogger.info(
            'Skipping calendar event generation: Supabase is not initialized',
          );
        } else {
          AppLogger.warning('Failed to generate calendar events: $e');
        }
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('BreedingFormNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Updates an existing breeding pair.
  Future<void> updateBreeding(BreedingPair pair) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(breedingPairRepositoryProvider);
      await repo.save(pair.copyWith(updatedAt: DateTime.now()));
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('BreedingFormNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Cancels a breeding pair and its associated notifications.
  Future<void> cancelBreeding(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(breedingPairRepositoryProvider);
      final pair = await repo.getById(id);
      final now = DateTime.now();
      if (pair != null) {
        await repo.save(
          pair.copyWith(
            status: BreedingStatus.cancelled,
            separationDate: now,
            updatedAt: now,
          ),
        );

        final incubations = await _closeActiveIncubations(
          breedingPairId: id,
          status: IncubationStatus.cancelled,
          closedAt: now,
        );
        await _cancelBreedingNotifications(id, incubations: incubations);
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('BreedingFormNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Completes a breeding pair and cancels remaining notifications.
  Future<void> completeBreeding(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(breedingPairRepositoryProvider);
      final pair = await repo.getById(id);
      final now = DateTime.now();
      if (pair != null) {
        await repo.save(
          pair.copyWith(
            status: BreedingStatus.completed,
            separationDate: now,
            updatedAt: now,
          ),
        );

        final incubations = await _closeActiveIncubations(
          breedingPairId: id,
          status: IncubationStatus.completed,
          closedAt: now,
        );
        await _cancelBreedingNotifications(id, incubations: incubations);
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('BreedingFormNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Cancels incubation milestone and egg turning notifications
  /// associated with a breeding pair.
  Future<void> _cancelBreedingNotifications(
    String breedingPairId, {
    List<Incubation>? incubations,
    List<Egg>? eggs,
  }) async {
    try {
      final loadedIncubations =
          incubations ??
          await ref.read(incubationRepositoryProvider).getByBreedingPairIds([
            breedingPairId,
          ]);
      if (loadedIncubations.isEmpty) return;

      final loadedEggs =
          eggs ?? await _getEggsForIncubations(loadedIncubations);

      final scheduler = ref.read(notificationSchedulerProvider);
      for (final incubation in loadedIncubations) {
        await scheduler.cancelIncubationMilestones(incubation.id);
      }

      // Keep legacy cancellation by incubationId and cancel proper eggId-based schedules.
      final turningReminderIds = <String>{
        for (final incubation in loadedIncubations) incubation.id,
        for (final egg in loadedEggs) egg.id,
      };
      for (final reminderId in turningReminderIds) {
        await scheduler.cancelEggTurningReminders(reminderId);
      }
    } catch (e) {
      AppLogger.warning('Failed to cancel breeding notifications: $e');
    }
  }

  /// Deletes (soft-delete) a breeding pair.
  Future<void> deleteBreeding(String id) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final pairRepo = ref.read(breedingPairRepositoryProvider);
      final incubationRepo = ref.read(incubationRepositoryProvider);
      final eggRepo = ref.read(eggRepositoryProvider);

      try {
        final incubations = await incubationRepo.getByBreedingPairIds([id]);
        final eggs = await _getEggsForIncubations(incubations);

        await _cancelBreedingNotifications(
          id,
          incubations: incubations,
          eggs: eggs,
        );

        for (final egg in eggs) {
          await eggRepo.remove(egg.id);
        }
        for (final incubation in incubations) {
          await incubationRepo.remove(incubation.id);
        }
      } catch (e) {
        AppLogger.warning(
          'Failed to clean related incubation/egg records before deleting breeding $id: $e',
        );
      }

      await pairRepo.remove(id);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('BreedingFormNotifier', e, st);
      Sentry.captureException(e, stackTrace: st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<Egg>> _getEggsForIncubations(List<Incubation> incubations) async {
    final incubationIds = incubations.map((i) => i.id).toList();
    if (incubationIds.isEmpty) return const <Egg>[];

    final eggRepo = ref.read(eggRepositoryProvider);
    return eggRepo.getByIncubationIds(incubationIds);
  }

  Future<List<Incubation>> _closeActiveIncubations({
    required String breedingPairId,
    required IncubationStatus status,
    required DateTime closedAt,
  }) async {
    final incubationRepo = ref.read(incubationRepositoryProvider);
    final incubations = await incubationRepo.getByBreedingPairIds([
      breedingPairId,
    ]);

    for (final incubation in incubations) {
      if (incubation.status != IncubationStatus.active) continue;
      await incubationRepo.save(
        incubation.copyWith(
          status: status,
          endDate: incubation.endDate ?? closedAt,
          updatedAt: closedAt,
        ),
      );
    }

    return incubations;
  }

  /// Resets form state for a new operation.
  void reset() {
    state = const BreedingFormState();
  }

  bool _isSupabaseUnavailableError(Object error) {
    final message = error.toString();
    return message.contains('You must initialize the supabase instance') ||
        message.contains('provider that is in error state');
  }
}
