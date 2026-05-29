part of 'bird_form_providers.dart';

mixin _BirdFormActions on Notifier<BirdFormState>, SentryErrorFilter {
  String? _normalizeOptionalText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  Future<bool> _hasRingNumberConflict({
    required String userId,
    required String? ringNumber,
    String? excludeBirdId,
  }) async {
    final normalizedRing = _normalizeOptionalText(ringNumber)?.toLowerCase();
    if (normalizedRing == null) return false;

    final repo = ref.read(birdRepositoryProvider);
    return repo.hasRingNumber(userId, normalizedRing, excludeId: excludeBirdId);
  }

  Future<String?> _validateParents({
    required Species species,
    required String? fatherId,
    required String? motherId,
    String? excludeBirdId,
  }) async {
    final repo = ref.read(birdRepositoryProvider);

    if (excludeBirdId != null &&
        (fatherId == excludeBirdId || motherId == excludeBirdId)) {
      return 'birds.not_found'.tr();
    }

    if (fatherId != null) {
      final father = await repo.getById(fatherId);
      if (father == null) return 'birds.not_found'.tr();
      if (father.gender != BirdGender.male) return 'birds.invalid_father'.tr();
      if (father.species != species) {
        return 'birds.parent_species_mismatch'.tr();
      }
    }

    if (motherId != null) {
      final mother = await repo.getById(motherId);
      if (mother == null) return 'birds.not_found'.tr();
      if (mother.gender != BirdGender.female) {
        return 'birds.invalid_mother'.tr();
      }
      if (mother.species != species) {
        return 'birds.parent_species_mismatch'.tr();
      }
    }

    return null;
  }

  String? _mapIntegrityError(Object error) {
    final message = switch (error) {
      AppException() => error.message,
      _ => error.toString(),
    }.toLowerCase();

    if (message.contains('bird_parent_species_mismatch')) {
      return 'birds.parent_species_mismatch'.tr();
    }
    if (message.contains('bird_invalid_father_gender')) {
      return 'birds.invalid_father'.tr();
    }
    if (message.contains('bird_invalid_mother_gender')) {
      return 'birds.invalid_mother'.tr();
    }
    if (message.contains('bird_parent_self_reference') ||
        message.contains('bird_father_not_found') ||
        message.contains('bird_mother_not_found')) {
      return 'birds.not_found'.tr();
    }
    return null;
  }

  Future<void> createBird({
    required String userId,
    required String name,
    required BirdGender gender,
    Species species = Species.unknown,
    BirdColor? colorMutation,
    String? ringNumber,
    DateTime? birthDate,
    String? fatherId,
    String? motherId,
    String? cageNumber,
    String? notes,
    List<String>? mutations,
    Map<String, String>? genotypeInfo,
    XFile? photoFile,
  }) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      error: null,
      isSuccess: false,
      lastAction: BirdFormAction.save,
    );
    String? uploadedPhotoUrl;
    try {
      final repo = ref.read(birdRepositoryProvider);
      final normalizedRingNumber = _normalizeOptionalText(ringNumber);
      final normalizedCageNumber = _normalizeOptionalText(cageNumber);
      final parentError = await _validateParents(
        species: species,
        fatherId: fatherId,
        motherId: motherId,
      );
      if (parentError != null) {
        state = state.copyWith(isLoading: false, error: parentError);
        return;
      }

      // Free tier bird limit check
      final isPremium = ref.read(effectivePremiumProvider);
      if (!isPremium) {
        try {
          await ref.read(freeTierLimitServiceProvider).guardBirdLimit(userId);
        } on FreeTierLimitException catch (e) {
          state = state.copyWith(
            isLoading: false,
            error: 'premium.bird_limit_reached'.tr(args: ['${e.limit}']),
            isBirdLimitReached: true,
          );
          return;
        }
      }

      if (await _hasRingNumberConflict(
        userId: userId,
        ringNumber: normalizedRingNumber,
      )) {
        state = state.copyWith(
          isLoading: false,
          error: 'birds.ring_number_not_unique'.tr(),
        );
        return;
      }

      final birdId = const Uuid().v7();
      String? photoUrl;
      if (photoFile != null) {
        try {
          photoUrl = await ref
              .read(photoRepositoryProvider)
              .uploadBirdPhoto(userId: userId, birdId: birdId, file: photoFile);
          // Track the uploaded object so we can compensate (delete it) if a
          // later step — the bird row save or the Photo row save — fails.
          // Otherwise the object leaks in storage with no DB row pointing to it.
          uploadedPhotoUrl = photoUrl;
        } catch (e, st) {
          AppLogger.error('BirdFormNotifier photo upload', e, st);
          state = state.copyWith(
            isLoading: false,
            error: 'birds.photo_upload_error'.tr(),
          );
          return;
        }
      }

      final bird = Bird(
        id: birdId,
        userId: userId,
        name: name,
        gender: gender,
        species: species,
        status: BirdStatus.alive,
        photoUrl: photoUrl,
        colorMutation: colorMutation,
        ringNumber: normalizedRingNumber,
        birthDate: birthDate,
        fatherId: fatherId,
        motherId: motherId,
        cageNumber: normalizedCageNumber,
        notes: notes,
        mutations: mutations,
        genotypeInfo: genotypeInfo,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );
      await repo.save(bird);
      if (photoUrl != null && photoFile != null) {
        await ref
            .read(photoRepositoryProvider)
            .save(
              Photo(
                id: const Uuid().v7(),
                userId: userId,
                entityType: PhotoEntityType.bird,
                entityId: birdId,
                fileName: photoFile.name,
                filePath: photoUrl,
                isPrimary: true,
                createdAt: DateTime.now().toUtc(),
                updatedAt: DateTime.now().toUtc(),
              ),
            );
      }

      // Calculate remaining birds for soft upsell
      int? remaining;
      if (!isPremium) {
        final afterCount = await repo.getCount(userId);
        remaining = AppConstants.freeTierMaxBirds - afterCount;
      }

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        remainingBirds: remaining,
        lastAction: BirdFormAction.save,
      );
    } catch (e, st) {
      AppLogger.error('BirdFormNotifier', e, st);
      reportIfUnexpected(e, st);
      // Compensating cleanup: if persistence failed after the photo was
      // already uploaded, delete the orphaned storage object so it doesn't
      // leak. Best-effort — a cleanup failure must not mask the original
      // error shown to the user.
      if (uploadedPhotoUrl != null) {
        try {
          await ref
              .read(photoRepositoryProvider)
              .deleteStorageForPhoto(
                Photo(
                  id: '',
                  userId: userId,
                  entityType: PhotoEntityType.bird,
                  entityId: '',
                  fileName: '',
                  filePath: uploadedPhotoUrl,
                ),
              );
        } catch (cleanupError, cleanupSt) {
          AppLogger.error(
            'BirdFormNotifier photo cleanup after save failure',
            cleanupError,
            cleanupSt,
          );
        }
      }
      state = state.copyWith(
        isLoading: false,
        error: _mapIntegrityError(e) ?? 'errors.unknown'.tr(),
      );
    }
  }

  Future<void> updateBird(Bird bird) async {
    if (state.isLoading) return;
    state = state.copyWith(
      isLoading: true,
      error: null,
      isSuccess: false,
      lastAction: BirdFormAction.save,
    );
    try {
      final repo = ref.read(birdRepositoryProvider);
      final normalizedRingNumber = _normalizeOptionalText(bird.ringNumber);
      final normalizedCageNumber = _normalizeOptionalText(bird.cageNumber);
      final parentError = await _validateParents(
        species: bird.species,
        fatherId: bird.fatherId,
        motherId: bird.motherId,
        excludeBirdId: bird.id,
      );
      if (parentError != null) {
        state = state.copyWith(isLoading: false, error: parentError);
        return;
      }

      if (await _hasRingNumberConflict(
        userId: bird.userId,
        ringNumber: normalizedRingNumber,
        excludeBirdId: bird.id,
      )) {
        state = state.copyWith(
          isLoading: false,
          error: 'birds.ring_number_not_unique'.tr(),
        );
        return;
      }

      await repo.save(
        bird.copyWith(
          ringNumber: normalizedRingNumber,
          cageNumber: normalizedCageNumber,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        lastAction: BirdFormAction.save,
      );
    } catch (e, st) {
      AppLogger.error('BirdFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(
        isLoading: false,
        error: _mapIntegrityError(e) ?? 'errors.unknown'.tr(),
      );
    }
  }
}
