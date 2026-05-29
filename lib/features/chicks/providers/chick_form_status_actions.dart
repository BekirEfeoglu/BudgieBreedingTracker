part of 'chick_form_providers.dart';

/// Extension on [ChickFormNotifier] for status change and promotion actions.
extension ChickFormStatusActions on ChickFormNotifier {
  /// Marks a chick as weaned.
  Future<void> markAsWeaned(String id, {DateTime? weanDate}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, warning: null);
    try {
      final repo = ref.read(chickRepositoryProvider);
      final chick = await repo.getById(id);
      var sideEffectError = false;
      if (chick != null) {
        await repo.save(
          chick.copyWith(
            weanDate: weanDate ?? DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        sideEffectError = await _cancelChickReminders(
          ref,
          id,
          cancelCare: true,
          cancelBanding: false,
        );
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

  /// Marks a chick as deceased.
  Future<void> markAsDeceased(String id, {DateTime? deathDate}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, warning: null);
    try {
      final repo = ref.read(chickRepositoryProvider);
      final chick = await repo.getById(id);
      var sideEffectError = false;
      if (chick != null) {
        await repo.save(
          chick.copyWith(
            healthStatus: ChickHealthStatus.deceased,
            deathDate: deathDate ?? DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        sideEffectError = await _cancelChickReminders(
          ref,
          id,
          cancelCare: true,
          cancelBanding: true,
        );
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

  /// Promotes a chick to a Bird. Creates a new Bird and sets chick.birdId.
  /// Resolves parent IDs from the breeding pair via egg → incubation → pair.
  Future<void> promoteToBird(Chick chick) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      error: null,
      warning: null,
      isSuccess: false,
    );
    try {
      final birdRepo = ref.read(birdRepositoryProvider);
      final chickRepo = ref.read(chickRepositoryProvider);

      if (chick.birdId != null) {
        state = state.copyWith(isLoading: false, isSuccess: true);
        return;
      }

      // Resolve parent IDs from breeding pair chain
      final (:fatherId, :motherId) = await _resolveParentIds(ref, chick.eggId);

      final chickLabel =
          chick.name ??
          'chicks.unnamed_chick'.tr(
            args: [chick.ringNumber ?? chick.id.substring(0, 6)],
          );
      final sourceEgg = chick.eggId == null
          ? null
          : await ref.read(eggRepositoryProvider).getById(chick.eggId!);
      final species = sourceEgg == null
          ? Species.unknown
          : await resolveEggSpecies(ref, sourceEgg);

      final birdId = const Uuid().v7();
      final bird = Bird(
        id: birdId,
        userId: chick.userId,
        name: chickLabel,
        gender: chick.gender,
        species: species,
        status: BirdStatus.alive,
        ringNumber: chick.ringNumber,
        birthDate: chick.hatchDate,
        photoUrl: chick.photoUrl,
        notes: chick.notes,
        fatherId: fatherId,
        motherId: motherId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await birdRepo.save(bird);
      try {
        await chickRepo.save(
          chick.copyWith(
            birdId: birdId,
            weanDate: chick.weanDate ?? DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } catch (e, st) {
        try {
          await birdRepo.remove(birdId);
        } catch (rollbackError, rollbackSt) {
          AppLogger.error(
            'Failed to rollback promoted bird',
            rollbackError,
            rollbackSt,
          );
        }
        Error.throwWithStackTrace(e, st);
      }

      final sideEffectError = await _cancelChickReminders(
        ref,
        chick.id,
        cancelCare: true,
        cancelBanding: true,
      );

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
}

Future<bool> _cancelChickReminders(
  Ref ref,
  String chickId, {
  required bool cancelCare,
  required bool cancelBanding,
}) async {
  var sideEffectError = false;
  final scheduler = ref.read(notificationSchedulerProvider);
  if (cancelCare) {
    try {
      await scheduler.cancelChickCareReminders(chickId);
    } catch (e, st) {
      // Best-effort side effect: AppLogger.warning has no stackTrace param,
      // so append it to the message to retain it for diagnosis.
      AppLogger.warning('Failed to cancel chick care reminders: $e\n$st');
      sideEffectError = true;
    }
  }
  if (cancelBanding) {
    try {
      await scheduler.cancelBandingReminders(chickId);
    } catch (e, st) {
      AppLogger.warning('Failed to cancel banding reminders: $e\n$st');
      sideEffectError = true;
    }
  }
  return sideEffectError;
}

/// Resolves father/mother IDs by traversing egg → incubation → breeding pair.
///
/// A missing link in the chain (no egg, no incubation, no pair) is an
/// *expected* outcome — the chick simply has no derivable parents, so we
/// return `(null, null)` without logging. A thrown exception, by contrast, is
/// an unexpected repository failure that silently degrades the promoted bird's
/// pedigree, so it is logged at error level with its stack trace (which also
/// adds a Sentry breadcrumb) before falling back to null parents.
Future<({String? fatherId, String? motherId})> _resolveParentIds(
  Ref ref,
  String? eggId,
) async {
  if (eggId == null) return (fatherId: null, motherId: null);
  try {
    final egg = await ref.read(eggRepositoryProvider).getById(eggId);
    if (egg == null || egg.incubationId == null) {
      return (fatherId: null, motherId: null);
    }
    final incubation = await ref
        .read(incubationRepositoryProvider)
        .getById(egg.incubationId!);
    if (incubation == null || incubation.breedingPairId == null) {
      return (fatherId: null, motherId: null);
    }
    final pair = await ref
        .read(breedingPairRepositoryProvider)
        .getById(incubation.breedingPairId!);
    if (pair == null) return (fatherId: null, motherId: null);
    return (fatherId: pair.maleId, motherId: pair.femaleId);
  } catch (e, st) {
    AppLogger.error(
      'Failed to resolve parents for chick promotion (eggId: $eggId)',
      e,
      st,
    );
    return (fatherId: null, motherId: null);
  }
}
