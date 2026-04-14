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
      if (chick != null) {
        await repo.save(
          chick.copyWith(
            weanDate: weanDate ?? DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
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
        try {
          final scheduler = ref.read(notificationSchedulerProvider);
          await scheduler.cancelBandingReminders(id);
        } catch (e) {
          AppLogger.warning('Failed to cancel banding reminders: $e');
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
      await chickRepo.save(
        chick.copyWith(
          birdId: birdId,
          weanDate: chick.weanDate ?? DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('ChickFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }
}

/// Resolves father/mother IDs by traversing egg → incubation → breeding pair.
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
  } catch (e) {
    AppLogger.warning('Failed to resolve parents for chick promotion: $e');
    return (fatherId: null, motherId: null);
  }
}
