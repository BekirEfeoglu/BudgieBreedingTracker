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
      // If detach fails for a chick we MUST NOT delete its parent egg —
      // otherwise the chick row is left referencing a soft-deleted egg
      // (dangling FK that re-asserts on next sync pull).
      final eggIds = eggs.map((e) => e.id).toList();
      final blockedEggIds = <String>{};
      if (eggIds.isNotEmpty) {
        try {
          final chicks = await chickRepo.getByEggIds(eggIds);
          if (chicks.isNotEmpty) {
            final now = DateTime.now();
            final results = await Future.wait(
              chicks.map(
                (chick) async {
                  try {
                    await chickRepo.save(
                      chick.copyWith(
                        eggId: null,
                        clutchId: null,
                        updatedAt: now,
                      ),
                    );
                    return null;
                  } catch (e, st) {
                    AppLogger.warning(
                      'Failed to detach chick ${chick.id} during cascade '
                      'delete of pair $id: $e',
                    );
                    AppLogger.error(
                      'BreedingFormNotifier.deleteBreeding.detach',
                      e,
                      st,
                    );
                    // Remember which egg still has a live chick reference;
                    // we skip its removal below to avoid dangling FK.
                    final blockedEggId = chick.eggId;
                    if (blockedEggId != null) {
                      blockedEggIds.add(blockedEggId);
                    }
                    return e;
                  }
                },
              ),
              eagerError: false,
            );
            if (results.any((r) => r != null)) partial = true;
          }
        } catch (e, st) {
          AppLogger.warning('Chick detach phase failed for pair $id: $e');
          AppLogger.error('BreedingFormNotifier.deleteBreeding', e, st);
          partial = true;
          // Defensive: any partial-listing failure also blocks egg deletion
          // so we don't strand chicks we never inspected.
          blockedEggIds.addAll(eggIds);
        }
      }

      final eggsToRemove = blockedEggIds.isEmpty
          ? eggs
          : eggs.where((egg) => !blockedEggIds.contains(egg.id)).toList();
      if (eggsToRemove.length != eggs.length) partial = true;

      // Incubations whose eggs we skipped must also be skipped, otherwise
      // the surviving egg.incubationId points to a soft-deleted parent —
      // same dangling-FK pattern as the chick case above.
      final blockedIncubationIds = <String>{
        for (final egg in eggs)
          if (blockedEggIds.contains(egg.id) && egg.incubationId != null)
            egg.incubationId!,
      };
      final incubationsToRemove = blockedIncubationIds.isEmpty
          ? incubations
          : incubations
              .where((inc) => !blockedIncubationIds.contains(inc.id))
              .toList();
      if (incubationsToRemove.length != incubations.length) partial = true;

      partial = await _removeAllResilient(
            entities: eggsToRemove,
            label: 'egg',
            remove: (egg) => eggRepo.remove(egg.id),
          ) ||
          partial;
      partial = await _removeAllResilient(
            entities: incubationsToRemove,
            label: 'incubation',
            remove: (inc) => incubationRepo.remove(inc.id),
          ) ||
          partial;

      // If any child is still live, block the pair remove too — otherwise
      // the surviving incubation.breedingPairId dangles. Surface a clear
      // warning so the user knows to retry once children clear.
      if (blockedIncubationIds.isNotEmpty || blockedEggIds.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: false,
          warning: 'errors.background_tasks_partial'.tr(),
          error: 'errors.delete_failed'.tr(),
        );
        return;
      }

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
      } catch (e, st) {
        AppLogger.error(
          '[BreedingFormActions] delete calendar events for pair $id',
          e,
          st,
        );
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
