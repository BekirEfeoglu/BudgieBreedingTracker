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

      // Cascade order is intentional: side-effects first (notifications,
      // calendar), then data deletes in dependency order (children → parent).
      // Each step swallows per-item failures with eagerError: false so a
      // single bad row never strands the rest of the cascade. Surviving
      // children remain soft-deletable on retry — soft-delete is idempotent.
      var partial = false;

      // Best-effort: notifications & calendar can fail without blocking the
      // primary delete. They simply won't be cleaned up until a later sync.
      await _helper.cancelBreedingNotifications(
        id,
        incubations: incubations,
        eggs: eggs,
      );

      // Detach chicks from soon-to-be-deleted eggs/clutches so they survive
      // as standalone records. Chicks are live entities with their own
      // lifecycle — losing them on parent-pair delete would be data loss.
      final eggIds = eggs.map((e) => e.id).toList();
      if (eggIds.isNotEmpty) {
        try {
          final chicks = await chickRepo.getByEggIds(eggIds);
          if (chicks.isNotEmpty) {
            final now = DateTime.now();
            final results = await Future.wait(
              chicks.map(
                (chick) => chickRepo
                    .save(
                      chick.copyWith(
                        eggId: null,
                        clutchId: null,
                        updatedAt: now,
                      ),
                    )
                    .then<Object?>((_) => null)
                    .catchError((Object e, StackTrace st) {
                      AppLogger.warning(
                        'Failed to detach chick ${chick.id} during cascade '
                        'delete of pair $id: $e',
                      );
                      return e;
                    }),
              ),
              eagerError: false,
            );
            if (results.any((r) => r != null)) partial = true;
          }
        } catch (e, st) {
          AppLogger.warning('Chick detach phase failed for pair $id: $e');
          AppLogger.error('BreedingFormNotifier.deleteBreeding', e, st);
          partial = true;
        }
      }

      partial = await _removeAllResilient(
            entities: eggs,
            label: 'egg',
            remove: (egg) => eggRepo.remove(egg.id),
          ) ||
          partial;
      partial = await _removeAllResilient(
            entities: incubations,
            label: 'incubation',
            remove: (inc) => incubationRepo.remove(inc.id),
          ) ||
          partial;

      try {
        await pairRepo.remove(id);
      } catch (e, st) {
        // Pair remove is the last step — if it fails after children were
        // cleaned, the user can retry and the children stay soft-deleted.
        AppLogger.error(
          '[BreedingFormNotifier] Pair remove failed in cascade',
          e,
          st,
        );
        reportIfUnexpected(e, st);
        state = state.copyWith(
          isLoading: false,
          error: 'errors.delete_failed'.tr(),
        );
        return;
      }

      // Drop calendar entries that reference this pair so they don't keep
      // pointing at a deleted entity. Best-effort only.
      try {
        await ref.read(eventRepositoryProvider).removeByBreedingPairIds([id]);
      } catch (e) {
        AppLogger.warning('Failed to delete calendar events for pair $id: $e');
        partial = true;
      }

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        warning: partial ? 'errors.background_tasks_partial'.tr() : null,
      );
    } catch (e, st) {
      AppLogger.error('BreedingFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Best-effort bulk remove. Returns true if any item failed; the rest are
  /// still attempted (`eagerError: false`). Each failure is logged but does
  /// not abort the cascade — retry is safe because soft-delete is idempotent.
  Future<bool> _removeAllResilient<T>({
    required Iterable<T> entities,
    required String label,
    required Future<void> Function(T) remove,
  }) async {
    if (entities.isEmpty) return false;
    final results = await Future.wait(
      entities.map(
        (e) => remove(e)
            .then<Object?>((_) => null)
            .catchError((Object error, StackTrace st) {
              AppLogger.warning(
                'Failed to remove $label during cascade: $error',
              );
              return error;
            }),
      ),
      eagerError: false,
    );
    return results.any((r) => r != null);
  }
}
