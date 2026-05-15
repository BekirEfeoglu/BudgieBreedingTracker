part of 'breeding_form_providers.dart';

extension BreedingFormActions on BreedingFormNotifier {
  Future<void> cancelBreeding(String id) async {
    if (state.isLoading) return;
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
    if (state.isLoading) return;
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
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final pairRepo = ref.read(breedingPairRepositoryProvider);
      final incubationRepo = ref.read(incubationRepositoryProvider);
      final eggRepo = ref.read(eggRepositoryProvider);
      final chickRepo = ref.read(chickRepositoryProvider);

      final incubations = await incubationRepo.getByBreedingPairIds([id]);
      final eggs = await _helper.getEggsForIncubations(incubations);

      await _helper.cancelBreedingNotifications(
        id,
        incubations: incubations,
        eggs: eggs,
      );

      // Detach chicks from soon-to-be-deleted eggs/clutches so they survive
      // as standalone records (chicks are live entities with their own lifecycle).
      final eggIds = eggs.map((e) => e.id).toList();
      if (eggIds.isNotEmpty) {
        final chicks = await chickRepo.getByEggIds(eggIds);
        if (chicks.isNotEmpty) {
          final now = DateTime.now();
          await Future.wait(
            chicks.map(
              (chick) => chickRepo.save(
                chick.copyWith(
                  eggId: null,
                  clutchId: null,
                  updatedAt: now,
                ),
              ),
            ),
          );
        }
      }

      await Future.wait(eggs.map((egg) => eggRepo.remove(egg.id)));
      await Future.wait(
        incubations.map((inc) => incubationRepo.remove(inc.id)),
      );

      await pairRepo.remove(id);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('BreedingFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }
}
