import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_notification_helpers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/free_tier_limit_providers.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
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
  late final BreedingNotificationHelper _helper;

  @override
  BreedingFormState build() {
    _helper = BreedingNotificationHelper(ref);
    return const BreedingFormState();
  }

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
      final isPremium = ref.read(effectivePremiumProvider);
      if (!isPremium) {
        try {
          await ref
              .read(freeTierLimitServiceProvider)
              .guardBreedingPairLimit(userId);
        } on FreeTierLimitException {
          state = state.copyWith(
            isLoading: false,
            error: 'premium.breeding_limit_reached'.tr(
              args: ['${AppConstants.freeTierMaxBreedingPairs}'],
            ),
            isBreedingLimitReached: true,
          );
          return;
        }

        try {
          await ref
              .read(freeTierLimitServiceProvider)
              .guardIncubationLimit(userId);
        } on FreeTierLimitException {
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
        expectedHatchDate: pairingDate.add(const Duration(days: IncubationConstants.incubationPeriodDays)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await pairRepo.save(pair);
      try {
        await incubationRepo.save(incubation);
      } catch (e) {
        // Rollback: remove the orphaned pair
        await pairRepo.remove(pairId);
        rethrow;
      }

      _helper.scheduleBreedingNotifications(pairId, incubationId, pairingDate);
      _helper.generateCalendarEvents(userId, pairId, pairingDate);

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('BreedingFormNotifier', e, StackTrace.current);
      Sentry.captureException(e, stackTrace: StackTrace.current);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
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
      Sentry.captureException(e, stackTrace: StackTrace.current);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
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

        final incubations = await _helper.closeActiveIncubations(
          breedingPairId: id,
          status: IncubationStatus.cancelled,
          closedAt: now,
        );
        await _helper.cancelBreedingNotifications(id, incubations: incubations);
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('BreedingFormNotifier', e, StackTrace.current);
      Sentry.captureException(e, stackTrace: StackTrace.current);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
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

        final incubations = await _helper.closeActiveIncubations(
          breedingPairId: id,
          status: IncubationStatus.completed,
          closedAt: now,
        );
        await _helper.cancelBreedingNotifications(id, incubations: incubations);
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('BreedingFormNotifier', e, StackTrace.current);
      Sentry.captureException(e, stackTrace: StackTrace.current);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
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
        final eggs = await _helper.getEggsForIncubations(incubations);

        await _helper.cancelBreedingNotifications(
          id,
          incubations: incubations,
          eggs: eggs,
        );

        await Future.wait(eggs.map((egg) => eggRepo.remove(egg.id)));
        await Future.wait(
          incubations.map((inc) => incubationRepo.remove(inc.id)),
        );
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
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Resets form state for a new operation.
  void reset() {
    state = const BreedingFormState();
  }
}
