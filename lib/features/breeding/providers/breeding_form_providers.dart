import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/providers/bird_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/free_tier_limit_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_notification_helpers.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/sentry_error_filter.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:uuid/uuid.dart';

part 'breeding_form_actions.dart';

/// Male birds available for pairing (derived from birdsStreamProvider).
final maleBirdsProvider = Provider.family<List<Bird>, String>((ref, userId) {
  final birds = ref.watch(birdsStreamProvider(userId)).value ?? <Bird>[];
  return birds
      .where((b) => b.gender == BirdGender.male && b.status == BirdStatus.alive)
      .toList();
});

/// Female birds available for pairing (derived from birdsStreamProvider).
final femaleBirdsProvider = Provider.family<List<Bird>, String>((ref, userId) {
  final birds = ref.watch(birdsStreamProvider(userId)).value ?? <Bird>[];
  return birds
      .where(
        (b) => b.gender == BirdGender.female && b.status == BirdStatus.alive,
      )
      .toList();
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

class BreedingFormNotifier extends Notifier<BreedingFormState>
    with SentryErrorFilter {
  late final BreedingNotificationHelper _helper;

  @override
  BreedingFormState build() {
    _helper = BreedingNotificationHelper(ref);
    return const BreedingFormState();
  }

  Future<({Bird maleBird, Bird femaleBird})?> _validatePairBirds({
    required String maleId,
    required String femaleId,
  }) async {
    final birdRepo = ref.read(birdRepositoryProvider);
    final maleBird = await birdRepo.getById(maleId);
    final femaleBird = await birdRepo.getById(femaleId);
    if (maleBird == null || femaleBird == null) {
      state = state.copyWith(isLoading: false, error: 'birds.not_found'.tr());
      return null;
    }
    if (maleBird.species != femaleBird.species) {
      state = state.copyWith(
        isLoading: false,
        error: 'breeding.same_species_required'.tr(),
      );
      return null;
    }
    return (maleBird: maleBird, femaleBird: femaleBird);
  }

  String? _mapIntegrityError(Object error) {
    final message = switch (error) {
      AppException() => error.message,
      _ => error.toString(),
    }.toLowerCase();

    if (message.contains('breeding_pair_species_mismatch')) {
      return 'breeding.same_species_required'.tr();
    }
    if (message.contains('breeding_pair_invalid_male_gender')) {
      return 'breeding.invalid_male'.tr();
    }
    if (message.contains('breeding_pair_invalid_female_gender')) {
      return 'breeding.invalid_female'.tr();
    }
    if (message.contains('breeding_pair_male_not_found') ||
        message.contains('breeding_pair_female_not_found')) {
      return 'birds.not_found'.tr();
    }
    return null;
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
    if (state.isLoading) return;
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

      final validated = await _validatePairBirds(
        maleId: maleId,
        femaleId: femaleId,
      );
      if (validated == null) {
        return;
      }
      final maleBird = validated.maleBird;

      final pairId = const Uuid().v7();
      final incubationId = const Uuid().v7();

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
        species: maleBird.species,
        status: IncubationStatus.active,
        breedingPairId: pairId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await pairRepo.save(pair);
      try {
        await incubationRepo.save(incubation);
      } catch (e) {
        // Rollback: remove the orphaned pair
        try {
          await pairRepo.remove(pairId);
        } catch (rollbackError, rollbackSt) {
          AppLogger.error(
            '[BreedingFormNotifier] Rollback failed',
            rollbackError,
            rollbackSt,
          );
        }
        rethrow;
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('BreedingFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(
        isLoading: false,
        error: _mapIntegrityError(e) ?? 'errors.unknown'.tr(),
      );
    }
  }

  /// Updates an existing breeding pair.
  Future<void> updateBreeding(BreedingPair pair) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(breedingPairRepositoryProvider);
      if (pair.maleId != null && pair.femaleId != null) {
        final validated = await _validatePairBirds(
          maleId: pair.maleId!,
          femaleId: pair.femaleId!,
        );
        if (validated == null) return;
      }
      await repo.save(pair.copyWith(updatedAt: DateTime.now()));
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('BreedingFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(
        isLoading: false,
        error: _mapIntegrityError(e) ?? 'errors.unknown'.tr(),
      );
    }
  }

  /// Resets form state for a new operation.
  void reset() {
    state = const BreedingFormState();
  }
}
