import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/date_utils.dart' as date_utils;
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/providers/bird_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/inbreeding_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/species_incubation_config.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/free_tier_limit_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_settings_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_notification_helpers.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/sentry_error_filter.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:uuid/uuid.dart';

part 'breeding_form_actions.dart';

const _breedingCandidateBirdId = '__breeding_candidate__';

class BreedingCandidateInbreeding {
  final double coefficient;
  final InbreedingRisk risk;
  final Set<String> commonAncestorIds;
  final bool depthLimited;

  const BreedingCandidateInbreeding({
    required this.coefficient,
    required this.risk,
    required this.commonAncestorIds,
    this.depthLimited = false,
  });

  static const none = BreedingCandidateInbreeding(
    coefficient: 0,
    risk: InbreedingRisk.none,
    commonAncestorIds: {},
  );

  bool get shouldShow => risk != InbreedingRisk.none;

  bool get shouldConfirm => coefficient >= GeneticsConstants.inbreedingModerate;
}

BreedingCandidateInbreeding calculateBreedingCandidateInbreeding({
  required List<Bird> birds,
  required Bird? maleBird,
  required Bird? femaleBird,
}) {
  if (maleBird == null || femaleBird == null) {
    return BreedingCandidateInbreeding.none;
  }

  final ancestors = <String, Bird>{
    for (final bird in birds) bird.id: bird,
    maleBird.id: maleBird,
    femaleBird.id: femaleBird,
  };
  ancestors[_breedingCandidateBirdId] = Bird(
    id: _breedingCandidateBirdId,
    userId: maleBird.userId,
    name: _breedingCandidateBirdId,
    gender: BirdGender.unknown,
    species: maleBird.species,
    fatherId: maleBird.id,
    motherId: femaleBird.id,
  );

  const calculator = InbreedingCalculator();
  final detail = calculator.calculateDetailed(
    birdId: _breedingCandidateBirdId,
    ancestors: ancestors,
  );

  return BreedingCandidateInbreeding(
    coefficient: detail.coefficient,
    risk: calculator.assessRisk(detail.coefficient),
    commonAncestorIds: calculator.findCommonAncestors(
      birdId: _breedingCandidateBirdId,
      ancestors: ancestors,
    ),
    depthLimited: detail.depthLimited,
  );
}

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
  // Sentinel marker that lets [copyWith] distinguish "field not provided"
  // (preserve current value) from "explicit null" (clear the field).
  // Without this, every `copyWith(isLoading: true)` was silently nulling
  // any pending `error` / `warning` because the parameters defaulted to
  // null and the body assigned them directly.
  static const Object _unset = Object();

  final bool isLoading;
  final String? error;
  final String? warning;
  final bool isSuccess;
  final bool isBreedingLimitReached;
  final bool isIncubationLimitReached;

  const BreedingFormState({
    this.isLoading = false,
    this.error,
    this.warning,
    this.isSuccess = false,
    this.isBreedingLimitReached = false,
    this.isIncubationLimitReached = false,
  });

  BreedingFormState copyWith({
    bool? isLoading,
    Object? error = _unset,
    Object? warning = _unset,
    bool? isSuccess,
    bool? isBreedingLimitReached,
    bool? isIncubationLimitReached,
  }) {
    return BreedingFormState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      warning: identical(warning, _unset) ? this.warning : warning as String?,
      isSuccess: isSuccess ?? this.isSuccess,
      // Limit reach flags remain transient by design: setters pass true
      // explicitly, omission resets to false. The form screen listener
      // calls `reset()` once the dialog is shown.
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
    String? userId,
  }) async {
    final birdRepo = ref.read(birdRepositoryProvider);
    final maleBird = await birdRepo.getById(maleId);
    final femaleBird = await birdRepo.getById(femaleId);
    if (maleBird == null || femaleBird == null) {
      state = state.copyWith(isLoading: false, error: 'birds.not_found'.tr());
      return null;
    }
    // Ownership check: both birds must belong to the user creating
    // the pair. RLS would reject the remote push, but the local pair
    // would persist as a permanent sync-error row until manually
    // removed. Validating here avoids that orphaned state entirely.
    if (userId != null &&
        (maleBird.userId != userId || femaleBird.userId != userId)) {
      state = state.copyWith(isLoading: false, error: 'birds.not_found'.tr());
      return null;
    }
    if (maleBird.gender != BirdGender.male) {
      state = state.copyWith(
        isLoading: false,
        error: 'breeding.invalid_male'.tr(),
      );
      return null;
    }
    if (femaleBird.gender != BirdGender.female) {
      state = state.copyWith(
        isLoading: false,
        error: 'breeding.invalid_female'.tr(),
      );
      return null;
    }
    if (maleBird.status != BirdStatus.alive ||
        femaleBird.status != BirdStatus.alive) {
      state = state.copyWith(
        isLoading: false,
        error: 'breeding.birds_must_be_alive'.tr(),
      );
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

  Future<void> _updateIncubationSpeciesForPair({
    required String pairId,
    required Species species,
  }) async {
    final incubationRepo = ref.read(incubationRepositoryProvider);
    final eggRepo = ref.read(eggRepositoryProvider);
    final scheduler = ref.read(notificationSchedulerProvider);
    final settings = ref.read(notificationToggleSettingsProvider);
    final incubations = await incubationRepo.getByBreedingPair(pairId);
    for (final incubation in incubations) {
      if (incubation.species == species) continue;
      final previousSpecies = incubation.species;
      final startDate = incubation.startDate;
      final expectedHatchDate = startDate == null
          ? incubation.expectedHatchDate
          : DateTime.utc(
              startDate.year,
              startDate.month,
              startDate.day,
            ).add(Duration(days: incubationDaysForSpecies(species)));

      // Drop reminders scheduled against the OLD species first — their
      // id range (day count × turning hours) is species-specific, so
      // doing this AFTER the save would only cancel the new range and
      // leak the previous one.
      try {
        await scheduler.cancelIncubationMilestones(incubation.id);
        final eggs = await eggRepo.getByIncubation(incubation.id);
        for (final egg in eggs) {
          await scheduler.cancelEggTurningReminders(
            egg.id,
            species: previousSpecies,
          );
        }
      } catch (e, st) {
        // Stale reminder cancellation is a best-effort cleanup before the
        // species change writes. Capturing stack for forensic Sentry
        // breadcrumb without rolling back the species update.
        AppLogger.error(
          '[BreedingForm] cancel stale reminders for ${incubation.id}',
          e,
          st,
        );
      }

      await incubationRepo.save(
        incubation.copyWith(
          species: species,
          expectedHatchDate: expectedHatchDate,
          updatedAt: DateTime.now(),
        ),
      );

      // Reschedule under the new species. Failures shouldn't undo the
      // save — surface as a warning in the calling flow if needed.
      try {
        if (startDate != null) {
          await scheduler.scheduleIncubationMilestones(
            incubationId: incubation.id,
            startDate: startDate,
            label: 'breeding.pair_label'.tr(
              args: [
                pairId.length <= 6 ? pairId : pairId.substring(0, 6),
              ],
            ),
            species: species,
            settings: settings,
          );
          final eggs = await eggRepo.getByIncubation(incubation.id);
          for (final egg in eggs) {
            await scheduler.scheduleEggTurningReminders(
              eggId: egg.id,
              startDate: egg.layDate,
              eggLabel: 'eggs.egg_label'.tr(
                args: ['${egg.eggNumber ?? 1}'],
              ),
              species: species,
              settings: settings,
            );
          }
        }
      } catch (e, st) {
        AppLogger.error(
          '[BreedingForm] reschedule reminders for ${incubation.id} after species change',
          e,
          st,
        );
      }
    }
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
        userId: userId,
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

      // Normalize incubation start to UTC midnight so dayDiff/percentage
      // math is DST-safe and matches IncubationX.computedExpectedHatchDate.
      final normalizedStart = date_utils.DateUtils.utcMidnight(pairingDate);
      final expectedHatch = normalizedStart.add(
        Duration(days: incubationDaysForSpecies(maleBird.species)),
      );

      final incubation = Incubation(
        id: incubationId,
        userId: userId,
        species: maleBird.species,
        status: IncubationStatus.active,
        breedingPairId: pairId,
        startDate: normalizedStart,
        expectedHatchDate: expectedHatch,
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

      // Side effects: schedule notifications + generate calendar milestones.
      // Failures must not undo the successful primary mutation — the
      // helpers swallow exceptions and log warnings internally, so we
      // safely await both in parallel.
      await Future.wait([
        _helper.scheduleBreedingNotifications(
          pairId,
          incubationId,
          normalizedStart,
          maleBird.species,
        ),
        _helper.generateCalendarEvents(
          userId,
          pairId,
          normalizedStart,
          maleBird.species,
          incubationId: incubationId,
        ),
      ]);

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
      Species? validatedSpecies;
      if (pair.maleId != null && pair.femaleId != null) {
        final validated = await _validatePairBirds(
          maleId: pair.maleId!,
          femaleId: pair.femaleId!,
          userId: pair.userId,
        );
        if (validated == null) return;
        validatedSpecies = validated.maleBird.species;
      }
      // Normalize pairingDate to UTC midnight (matches createBreeding) so
      // edit/save can't introduce a local-time drift that breaks day-diff
      // math downstream.
      final normalized = pair.pairingDate == null
          ? pair
          : pair.copyWith(
              pairingDate: date_utils.DateUtils.utcMidnight(pair.pairingDate!),
            );
      await repo.save(normalized.copyWith(updatedAt: DateTime.now()));
      if (validatedSpecies != null) {
        await _updateIncubationSpeciesForPair(
          pairId: pair.id,
          species: validatedSpecies,
        );
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

  /// Resets form state for a new operation.
  void reset() {
    state = const BreedingFormState();
  }

  /// Clears just the error field so a re-emit of the same state won't
  /// replay the SnackBar in the detail screen listener.
  void clearError() {
    if (state.error == null) return;
    state = state.copyWith(error: null);
  }
}
