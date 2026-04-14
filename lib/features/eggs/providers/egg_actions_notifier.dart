part of 'egg_providers.dart';

class EggActionsState {
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
    String? error,
    String? warning,
    bool? isSuccess,
    bool? chickCreated,
  }) {
    return EggActionsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      warning: warning,
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
    );
    try {
      final repo = ref.read(eggRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);
      final sideEffectErrors = <String>[];

      final egg = Egg(
        id: const Uuid().v7(),
        userId: userId,
        incubationId: incubationId,
        layDate: layDate,
        eggNumber: eggNumber,
        status: EggStatus.incubating,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.save(egg);
      final species = await resolveEggSpecies(ref, egg);

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

      var updated = egg.copyWith(status: newStatus, updatedAt: DateTime.now());

      if (newStatus == EggStatus.hatched) {
        updated = updated.copyWith(hatchDate: DateTime.now());
      } else if (newStatus == EggStatus.fertile) {
        updated = updated.copyWith(fertileCheckDate: DateTime.now());
      } else if (newStatus == EggStatus.discarded) {
        updated = updated.copyWith(discardDate: DateTime.now());
      }

      await repo.save(updated);

      // Automatically create chick when egg hatches
      var didCreateChick = false;
      var sideEffectError = false;
      if (newStatus == EggStatus.hatched) {
        final result = await _createChickFromHatchedEgg(updated);
        didCreateChick = result.created;
        sideEffectError = result.sideEffectError;
      }

      state = state.copyWith(
        isLoading: false,
        warning: sideEffectError
            ? 'errors.background_tasks_partial'.tr()
            : null,
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
  Future<({bool created, bool sideEffectError})> _createChickFromHatchedEgg(
    Egg egg,
  ) async {
    try {
      final chickRepo = ref.read(chickRepositoryProvider);

      // Duplicate check: skip if chick already exists for this egg
      final existing = await chickRepo.getByEggId(egg.id);
      if (existing != null) {
        AppLogger.info('Chick already exists for egg: ${egg.id}, skipping');
        return (created: false, sideEffectError: false);
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

      await chickRepo.save(chick);

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
      return (created: true, sideEffectError: sideEffectError);
    } catch (e) {
      AppLogger.error('Failed to auto-create chick from egg', e);
      return (created: false, sideEffectError: true);
    }
  }

  /// Soft-deletes an egg.
  Future<void> deleteEgg(String id) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(eggRepositoryProvider);
      await repo.remove(id);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('EggActionsNotifier', e, StackTrace.current);
      Sentry.captureException(e, stackTrace: StackTrace.current);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Resets the action state.
  void reset() {
    state = const EggActionsState();
  }
}
