part of 'breeding_form_providers.dart';

extension BreedingFormActions on BreedingFormNotifier {
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
        await _helper.cancelBreedingNotifications(
          id,
          incubations: incubations,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'breeding.not_found'.tr(),
        );
        return;
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('BreedingFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

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
        await _helper.cancelBreedingNotifications(
          id,
          incubations: incubations,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'breeding.not_found'.tr(),
        );
        return;
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('BreedingFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  Future<void> deleteBreeding(String id) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final pairRepo = ref.read(breedingPairRepositoryProvider);
      final incubationRepo = ref.read(incubationRepositoryProvider);
      final eggRepo = ref.read(eggRepositoryProvider);

      try {
        final incubations = await incubationRepo.getByBreedingPairIds([id]);
        final eggs =
            await _helper.getEggsForIncubations(incubations);

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
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }
}
