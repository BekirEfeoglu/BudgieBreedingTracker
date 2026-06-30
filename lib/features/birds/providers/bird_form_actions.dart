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
      warning: null,
      isSuccess: false,
      isBirdLimitReached: false,
      remainingBirds: null,
      lastAction: BirdFormAction.save,
    );
    String? uploadedPhotoUrl;
    var birdPersisted = false;
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
          // Track the uploaded object so we can compensate (delete it) if the
          // bird row save itself fails. Once the bird row is persisted with
          // photoUrl pointing at this object, it must NOT be deleted — see
          // birdPersisted below.
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
      // Past this point the bird row exists and owns `photoUrl` — any later
      // failure must be reported as a non-blocking warning, not a hard
      // error, so the user never retries into a duplicate bird, and the
      // compensating cleanup below must not delete the storage object the
      // now-persisted bird references.
      birdPersisted = true;

      String? warning;
      if (photoUrl != null && photoFile != null) {
        try {
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
        } catch (e, st) {
          AppLogger.error(
            'BirdFormNotifier photo gallery row save (bird already persisted)',
            e,
            st,
          );
          warning = 'birds.photo_gallery_save_partial'.tr();
        }
      }

      // Calculate remaining birds for soft upsell — non-critical, must not
      // fail a bird creation that already succeeded.
      int? remaining;
      if (!isPremium) {
        try {
          final afterCount = await repo.getCount(userId);
          remaining = AppConstants.freeTierMaxBirds - afterCount;
        } catch (e, st) {
          AppLogger.error(
            'BirdFormNotifier remaining-count calc (non-critical)',
            e,
            st,
          );
        }
      }

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        warning: warning,
        remainingBirds: remaining,
        lastAction: BirdFormAction.save,
      );
    } catch (e, st) {
      AppLogger.error('BirdFormNotifier', e, st);
      reportIfUnexpected(e, st);
      // Compensating cleanup: only delete the uploaded storage object if the
      // bird row was never persisted. Once persisted, bird.photoUrl owns
      // that object — deleting it here would leave a dangling reference on
      // a bird the user doesn't know exists (they were told this failed).
      if (!birdPersisted && uploadedPhotoUrl != null) {
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
      warning: null,
      isSuccess: false,
      isBirdLimitReached: false,
      remainingBirds: null,
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
