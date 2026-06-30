part of 'egg_actions_providers.dart';

class EggActionsState {
  static const Object _unset = Object();

  final bool isLoading;
  final String? error;
  final String? warning;
  final bool isSuccess;
  final bool chickCreated;

  const EggActionsState({
    this.isLoading = false,
    this.error,
    this.warning,
    this.isSuccess = false,
    this.chickCreated = false,
  });

  EggActionsState copyWith({
    bool? isLoading,
    Object? error = _unset,
    Object? warning = _unset,
    bool? isSuccess,
    bool? chickCreated,
  }) {
    return EggActionsState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      warning: identical(warning, _unset) ? this.warning : warning as String?,
      isSuccess: isSuccess ?? this.isSuccess,
      chickCreated: chickCreated ?? this.chickCreated,
    );
  }
}

class EggActionsNotifier extends Notifier<EggActionsState> {
  @override
  EggActionsState build() => const EggActionsState();

  /// Adds a new egg to an incubation.
  Future<void> addEgg({
    required String incubationId,
    required DateTime layDate,
    required int eggNumber,
    String? notes,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      error: null,
      warning: null,
      isSuccess: false,
      chickCreated: false,
    );
    try {
      final repo = ref.read(eggRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);

      // Verify incubation belongs to the current user before writing.
      // Without this, a stale deep-link or crafted incubationId could
      // create a local egg owned by another user, producing a permanent
      // sync-error row when the push is rejected by RLS (audit K11).
      final incubationRepo = ref.read(incubationRepositoryProvider);
      final incubation = await incubationRepo.getById(incubationId);
      if (incubation == null || incubation.userId != userId) {
        state = state.copyWith(
          isLoading: false,
          error: 'eggs.invalid_incubation'.tr(),
        );
        return;
      }

      final sideEffectErrors = <String>[];
      final existingEggs = await repo.getByIncubation(incubationId);

      final egg = Egg(
        id: const Uuid().v7(),
        userId: userId,
        incubationId: incubationId,
        layDate: layDate,
        eggNumber: eggNumber,
        status: EggStatus.laid,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.save(egg);
      final species = await resolveEggSpecies(ref, egg);
      final startedIncubation = await _startIncubationFromFirstEgg(
        incubationId: incubationId,
        layDate: layDate,
        species: species,
        isFirstEgg: existingEggs.isEmpty,
      );

      if (startedIncubation != null) {
        // First egg defines the incubation start date, so schedule milestones immediately.
        try {
          final scheduler = ref.read(notificationSchedulerProvider);
          final settings = ref.read(notificationToggleSettingsProvider);
          await scheduler.scheduleIncubationMilestones(
            incubationId: startedIncubation.id,
            startDate: layDate,
            label: 'breeding.incubation_process'.tr(),
            species: species,
            settings: settings,
          );
        } catch (e) {
          AppLogger.warning('Failed to schedule incubation reminders: $e');
          sideEffectErrors.add('incubation_reminder');
        }

        final pairId = startedIncubation.breedingPairId;
        if (pairId != null && pairId.isNotEmpty) {
          try {
            final calendarGen = ref.read(calendarEventGeneratorProvider);
            await calendarGen.generateIncubationEvents(
              userId: userId,
              breedingPairId: pairId,
              incubationId: incubationId,
              startDate: layDate,
              pairLabel: 'breeding.pair_label'.tr(args: [_shortId(pairId)]),
              species: species,
            );
          } catch (e) {
            if (isSupabaseUnavailableError(e)) {
              AppLogger.info(
                'Skipping incubation calendar generation: Supabase is not initialized',
              );
            } else {
              AppLogger.warning(
                'Failed to generate incubation calendar events: $e',
              );
              sideEffectErrors.add('incubation_calendar');
            }
          }
        }
      }

      // Schedule egg turning reminders
      try {
        final scheduler = ref.read(notificationSchedulerProvider);
        final settings = ref.read(notificationToggleSettingsProvider);
        await scheduler.scheduleEggTurningReminders(
          eggId: egg.id,
          startDate: layDate,
          eggLabel: 'eggs.egg_label'.tr(args: ['$eggNumber']),
          species: species,
          settings: settings,
        );
      } catch (e) {
        AppLogger.warning('Failed to schedule egg reminders: $e');
        sideEffectErrors.add('egg_reminder');
      }

      // Auto-generate expected hatch date calendar event
      try {
        final calendarGen = ref.read(calendarEventGeneratorProvider);
        await calendarGen.generateEggEvents(
          userId: userId,
          layDate: layDate,
          eggNumber: eggNumber,
          incubationId: incubationId,
          eggId: egg.id,
          species: species,
        );
      } catch (e) {
        if (isSupabaseUnavailableError(e)) {
          AppLogger.info(
            'Skipping egg calendar generation: Supabase is not initialized',
          );
        } else {
          AppLogger.warning('Failed to generate egg calendar event: $e');
          sideEffectErrors.add('egg_calendar');
        }
      }

      state = state.copyWith(
        isLoading: false,
        warning: sideEffectErrors.isNotEmpty
            ? 'errors.background_tasks_partial'.tr()
            : null,
        isSuccess: true,
      );
    } catch (e) {
      AppLogger.error('EggActionsNotifier', e, StackTrace.current);
      Sentry.captureException(e, stackTrace: StackTrace.current);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  Future<Incubation?> _startIncubationFromFirstEgg({
    required String incubationId,
    required DateTime layDate,
    required Species species,
    required bool isFirstEgg,
  }) async {
    if (!isFirstEgg) return null;

    final incubationRepo = ref.read(incubationRepositoryProvider);
    final incubation = await incubationRepo.getById(incubationId);
    if (incubation == null) return null;

    // Normalize lay date to UTC midnight so the incubation start aligns
    // with createBreeding's normalizedStart and dayDiff math stays DST-safe.
    final normalizedStart = date_utils.DateUtils.utcMidnight(layDate);
    final updated = incubation.copyWith(
      startDate: normalizedStart,
      expectedHatchDate: normalizedStart.add(
        Duration(days: incubation.totalIncubationDays(species: species)),
      ),
      updatedAt: DateTime.now(),
    );
    await incubationRepo.save(updated);
    return updated;
  }

  String _shortId(String id) => id.length <= 6 ? id : id.substring(0, 6);

  /// Updates the status of an existing egg.
  Future<void> updateEggStatus(Egg egg, EggStatus newStatus) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      error: null,
      warning: null,
      isSuccess: false,
      chickCreated: false,
    );
    try {
      final repo = ref.read(eggRepositoryProvider);

      // Verify the egg still exists before writing: `egg` may be a stale
      // snapshot held across an async UI gap (status sheet, confirmation
      // dialog). If it was deleted concurrently — e.g. its breeding pair was
      // removed while this call was in flight — `getById` returns null
      // because it filters `isDeleted`. Blindly writing the stale copy would
      // resurrect a soft-deleted row (and could re-trigger chick auto-create
      // against an already-removed incubation chain). Bail out instead.
      final stillExists = await repo.getById(egg.id) != null;
      if (!stillExists) {
        state = state.copyWith(
          isLoading: false,
          error: 'eggs.egg_not_found'.tr(),
        );
        return;
      }

      // Only stamp event dates when the status actually changes. Without
      // this guard, re-saving an already-hatched egg would reset its
      // hatchDate to today and the chick age math would silently drift.
      var updated = egg.copyWith(status: newStatus, updatedAt: DateTime.now());

      if (newStatus != egg.status) {
        if (newStatus == EggStatus.hatched) {
          updated = updated.copyWith(hatchDate: DateTime.now());
        } else if (newStatus == EggStatus.fertile) {
          updated = updated.copyWith(fertileCheckDate: DateTime.now());
        } else if (newStatus == EggStatus.discarded) {
          updated = updated.copyWith(discardDate: DateTime.now());
        }
      }

      await repo.save(updated);

      // Drop egg-turning reminders the moment the egg leaves an active
      // state — otherwise "turn egg #N" keeps firing every 4h for the
      // full 18-day window on hatched/damaged/discarded/infertile eggs.
      //
      // We cancel across EVERY species range rather than the egg's
      // currently-resolved species: the parent pair's species may have
      // changed since the reminders were scheduled, which would shift the
      // cancel target to a different notification-ID offset range and leak
      // the originally-scheduled reminders. The egg-turning ID slot is keyed
      // by eggId (stable) and offsets stay well under the per-entity slot
      // size, so the union of all species ranges safely covers whatever
      // range was used at schedule time. Duplicate cancels are idempotent.
      if (newStatus.isTerminal && !egg.status.isTerminal) {
        await _cancelEggTurningRemindersAllSpecies(egg.id);
      }

      // Automatically create chick when egg hatches
      var didCreateChick = false;
      var sideEffectError = false;
      var chickSaveFailed = false;
      if (newStatus == EggStatus.hatched) {
        final result = await _createChickFromHatchedEgg(updated);
        didCreateChick = result.created;
        sideEffectError = result.sideEffectError;
        chickSaveFailed = result.chickSaveFailed;
      }

      // Auto-complete the parent incubation once every egg has reached
      // a terminal status. Without this, completed clutches kept counting
      // against free-tier limits and showed as "in progress" forever.
      try {
        if (newStatus.isTerminal) {
          await _completeIncubationIfAllEggsTerminal(updated);
        }
      } catch (e) {
        // Non-blocking: the egg status change has already persisted.
        AppLogger.warning(
          'Failed to auto-complete incubation for egg ${egg.id}: $e',
        );
      }

      // chickSaveFailed wins over the milder side-effect warning because the
      // user has to act (egg is hatched in DB but no chick row exists).
      final warning = chickSaveFailed
          ? 'errors.chick_auto_create_failed'.tr()
          : (sideEffectError ? 'errors.background_tasks_partial'.tr() : null);

      state = state.copyWith(
        isLoading: false,
        warning: warning,
        isSuccess: true,
        chickCreated: didCreateChick,
      );
    } catch (e) {
      AppLogger.error('EggActionsNotifier', e, StackTrace.current);
      Sentry.captureException(e, stackTrace: StackTrace.current);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Creates a chick record automatically when an egg is marked as hatched.
  ///
  /// Returns:
  /// - [created]: true if a new chick row was inserted in this call.
  /// - [sideEffectError]: true if any non-critical side effect (notification
  ///   scheduling, calendar event generation) failed — surfaced as a warning.
  /// - [chickSaveFailed]: true if the chick row itself could not be saved.
  ///   The egg is already hatched in DB, so the egg-hatched state is NOT
  ///   rolled back; instead the caller surfaces a user-visible warning so the
  ///   user can add the chick manually.
  Future<({bool created, bool sideEffectError, bool chickSaveFailed})>
  _createChickFromHatchedEgg(Egg egg) async {
    final chickRepo = ref.read(chickRepositoryProvider);

    // Duplicate check is FAIL-CLOSED: `save` inserts a fresh v7-keyed chick
    // (it is NOT an upsert on eggId), so if this read throws we cannot tell
    // whether a chick already exists. Proceeding would risk inserting a
    // SECOND chick for the same egg on a transient read error. Instead we
    // bail with chickSaveFailed so the caller surfaces a warning and the user
    // can add the chick manually — at-most-once is safer than possibly-twice.
    try {
      final existing = await chickRepo.getByEggId(egg.id);
      if (existing != null) {
        AppLogger.info('Chick already exists for egg: ${egg.id}, skipping');
        return (created: false, sideEffectError: false, chickSaveFailed: false);
      }
    } catch (e, st) {
      AppLogger.error(
        'Duplicate-check read failed for egg ${egg.id}; skipping '
        'auto-create to avoid a duplicate chick',
        e,
        st,
      );
      Sentry.captureException(e, stackTrace: st);
      return (created: false, sideEffectError: false, chickSaveFailed: true);
    }

    final hatchDate = egg.hatchDate ?? DateTime.now();

    final chick = Chick(
      id: const Uuid().v7(),
      userId: egg.userId,
      eggId: egg.id,
      clutchId: egg.clutchId,
      hatchDate: hatchDate,
      gender: BirdGender.unknown,
      healthStatus: ChickHealthStatus.healthy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await chickRepo.save(chick);
    } catch (e, st) {
      AppLogger.error(
        'Failed to auto-create chick for hatched egg ${egg.id}',
        e,
        st,
      );
      Sentry.captureException(e, stackTrace: st);
      return (created: false, sideEffectError: false, chickSaveFailed: true);
    }

    try {
      final chickLabel = 'chicks.unnamed_chick'.tr(
        args: ['${egg.eggNumber ?? chick.id.substring(0, 6)}'],
      );
      var sideEffectError = false;

      // Schedule chick care reminders
      try {
        final scheduler = ref.read(notificationSchedulerProvider);
        final chickSettings = ref.read(notificationToggleSettingsProvider);
        await scheduler.scheduleChickCareReminder(
          chickId: chick.id,
          chickLabel: chickLabel,
          startDate: hatchDate,
          intervalHours: 4,
          durationDays: 14,
          settings: chickSettings,
        );
      } catch (e) {
        AppLogger.warning('Failed to schedule chick care reminders: $e');
        sideEffectError = true;
      }

      // Auto-generate chick milestone calendar events
      try {
        final calendarGen = ref.read(calendarEventGeneratorProvider);
        await calendarGen.generateChickEvents(
          userId: egg.userId,
          hatchDate: hatchDate,
          chickLabel: chickLabel,
          chickId: chick.id,
          bandingDay: 10,
        );
      } catch (e) {
        if (isSupabaseUnavailableError(e)) {
          AppLogger.info(
            'Skipping chick calendar generation: Supabase is not initialized',
          );
        } else {
          AppLogger.warning('Failed to generate chick calendar events: $e');
          sideEffectError = true;
        }
      }

      // Schedule banding reminders for auto-created chick
      try {
        final scheduler = ref.read(notificationSchedulerProvider);
        final chickSettings = ref.read(notificationToggleSettingsProvider);
        await scheduler.scheduleBandingReminders(
          chickId: chick.id,
          chickLabel: chickLabel,
          hatchDate: hatchDate,
          bandingDay: 10,
          settings: chickSettings,
        );
      } catch (e) {
        AppLogger.warning('Failed to schedule banding reminders: $e');
        sideEffectError = true;
      }

      AppLogger.info('Chick auto-created from hatched egg: ${egg.id}');
      return (
        created: true,
        sideEffectError: sideEffectError,
        chickSaveFailed: false,
      );
    } catch (e, st) {
      // Chick row was already persisted at this point; only side effects
      // (notifications, calendar) can have thrown unexpectedly here.
      AppLogger.error('Failed to schedule chick side effects', e, st);
      return (created: true, sideEffectError: true, chickSaveFailed: false);
    }
  }

  /// Transitions the parent incubation to [IncubationStatus.completed]
  /// when every sibling egg has reached a terminal status. The result
  /// (hatched / unsuccessful) is implicit in the egg statuses; we just
  /// flip the parent so it stops counting against free-tier limits and
  /// the UI stops showing it as in-progress.
  ///
  /// When this is the parent pair's last active incubation, the pair
  /// itself transitions to `completed`/`cancelled` too so the dashboard
  /// stops showing the pair as active and `guardBreedingPairLimit` no
  /// longer counts it (was stranding free-tier users with no remaining
  /// pair slots even after all their eggs hatched out).
  Future<void> _completeIncubationIfAllEggsTerminal(Egg trigger) async {
    final incubationId = trigger.incubationId;
    if (incubationId == null) return;

    final eggRepo = ref.read(eggRepositoryProvider);
    final siblings = await eggRepo.getByIncubation(incubationId);
    if (siblings.isEmpty) return;
    final allTerminal = siblings.every((e) => e.status.isTerminal);
    if (!allTerminal) return;

    final incubationRepo = ref.read(incubationRepositoryProvider);
    final incubation = await incubationRepo.getById(incubationId);
    if (incubation == null) return;
    if (incubation.status == IncubationStatus.completed) return;

    final anyHatched = siblings.any((e) => e.status == EggStatus.hatched);
    final now = DateTime.now();
    final newIncubationStatus = anyHatched
        ? IncubationStatus.completed
        : IncubationStatus.cancelled;
    await incubationRepo.save(
      incubation.copyWith(
        status: newIncubationStatus,
        endDate: incubation.endDate ?? now,
        updatedAt: now,
      ),
    );

    await _flipPairIfNoActiveIncubations(
      breedingPairId: incubation.breedingPairId,
      anyHatched: anyHatched,
      now: now,
    );
  }

  /// Flips the parent pair to `completed`/`cancelled` once all of its
  /// incubations have closed out. Stays `active` while any incubation is
  /// still in flight (multi-clutch pairs continue normally).
  Future<void> _flipPairIfNoActiveIncubations({
    required String? breedingPairId,
    required bool anyHatched,
    required DateTime now,
  }) async {
    if (breedingPairId == null) return;
    try {
      final incubationRepo = ref.read(incubationRepositoryProvider);
      final pairRepo = ref.read(breedingPairRepositoryProvider);

      final siblingIncubations = await incubationRepo.getByBreedingPairIds([
        breedingPairId,
      ]);
      final anyActive = siblingIncubations.any(
        (inc) => inc.status == IncubationStatus.active,
      );
      if (anyActive) return;

      final pair = await pairRepo.getById(breedingPairId);
      if (pair == null) return;
      if (pair.status != BreedingStatus.active &&
          pair.status != BreedingStatus.ongoing) {
        return;
      }
      final anyIncubationHatched =
          anyHatched ||
          siblingIncubations.any(
            (inc) => inc.status == IncubationStatus.completed,
          );
      await pairRepo.save(
        pair.copyWith(
          status: anyIncubationHatched
              ? BreedingStatus.completed
              : BreedingStatus.cancelled,
          separationDate: pair.separationDate ?? now,
          updatedAt: now,
        ),
      );
    } catch (e, st) {
      AppLogger.warning(
        'Failed to flip parent pair $breedingPairId after incubation '
        'completion: $e',
      );
      AppLogger.error('EggActionsNotifier._flipPair', e, st);
    }
  }

  /// Soft-deletes an egg.
  Future<void> deleteEgg(String id) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      error: null,
      warning: null,
      isSuccess: false,
      chickCreated: false,
    );
    try {
      final repo = ref.read(eggRepositoryProvider);

      // Captured before the delete purely to know which incubation to
      // re-evaluate below — _completeIncubationIfAllEggsTerminal re-fetches
      // the (now-current) sibling list itself, it only needs the incubationId.
      final egg = await repo.getById(id);

      await repo.remove(id);

      // Cancel scheduled turning reminders so they don't keep firing on
      // a deleted egg for the remainder of the incubation window. Cancel
      // across every species range: the parent pair's species may have
      // changed since the reminders were scheduled, so resolving a single
      // "current" species could miss the originally-scheduled ID range and
      // leak reminders. The slot is keyed by egg id, so the union of all
      // species ranges safely covers whatever range was used at schedule
      // time. Best-effort and idempotent.
      await _cancelEggTurningRemindersAllSpecies(id);

      // Soft-delete any calendar events that reference this egg so the
      // calendar doesn't keep displaying entries for a deleted entity.
      // Older rows (created before the eggId column existed) carry NULL
      // for eggId and won't match — they're already orphans on the
      // calendar side and stay until the next full sync reconciliation.
      try {
        await ref.read(eventRepositoryProvider).removeByEggIds([id]);
      } catch (e) {
        AppLogger.warning('Failed to delete calendar events for egg $id: $e');
      }

      // Deleting the last non-terminal egg can make "every remaining egg is
      // terminal" newly true (e.g. 2 hatched + 1 incubating egg, the
      // incubating one gets deleted). updateEggStatus already re-evaluates
      // this; deleteEgg must too, or the incubation — and its parent pair —
      // stay stuck `active` forever and keep counting against the free-tier
      // limit even though nothing is left to track.
      if (egg != null) {
        try {
          await _completeIncubationIfAllEggsTerminal(egg);
        } catch (e) {
          AppLogger.warning(
            'Failed to auto-complete incubation after deleting egg $id: $e',
          );
        }
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('EggActionsNotifier', e, StackTrace.current);
      Sentry.captureException(e, stackTrace: StackTrace.current);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Cancels egg-turning reminders for [eggId] across every species range.
  ///
  /// The reminder ID range depends on the species (`days × turningHours`),
  /// but the slot is keyed by [eggId] and offsets stay under the per-entity
  /// slot size, so iterating every species and cancelling each range covers
  /// whatever species was in effect at schedule time even if the parent
  /// pair's species changed afterwards. Best-effort: failures are logged and
  /// never block the calling flow.
  Future<void> _cancelEggTurningRemindersAllSpecies(String eggId) async {
    try {
      final scheduler = ref.read(notificationSchedulerProvider);
      for (final species in Species.values) {
        await scheduler.cancelEggTurningReminders(eggId, species: species);
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to cancel egg turning reminders for $eggId: $e',
      );
    }
  }

  /// Resets the action state.
  void reset() {
    state = const EggActionsState();
  }
}
