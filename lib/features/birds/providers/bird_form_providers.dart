import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/free_tier_limit_providers.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:uuid/uuid.dart';

/// Form state and actions for creating/editing birds.
final birdFormStateProvider = NotifierProvider<BirdFormNotifier, BirdFormState>(
  BirdFormNotifier.new,
);

/// State for the bird form.
class BirdFormState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final bool isBirdLimitReached;
  final int? remainingBirds;

  const BirdFormState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.isBirdLimitReached = false,
    this.remainingBirds,
  });

  BirdFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    bool? isBirdLimitReached,
    int? remainingBirds,
  }) {
    return BirdFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
      isBirdLimitReached: isBirdLimitReached ?? false,
      remainingBirds: remainingBirds,
    );
  }
}

/// Notifier for bird form operations.
class BirdFormNotifier extends Notifier<BirdFormState> {
  @override
  BirdFormState build() => const BirdFormState();

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
    return repo.hasRingNumber(
      userId,
      normalizedRing,
      excludeId: excludeBirdId,
    );
  }

  /// Creates a new bird.
  Future<void> createBird({
    required String userId,
    required String name,
    required BirdGender gender,
    Species species = Species.budgie,
    BirdColor? colorMutation,
    String? ringNumber,
    DateTime? birthDate,
    String? fatherId,
    String? motherId,
    String? cageNumber,
    String? notes,
    List<String>? mutations,
    Map<String, String>? genotypeInfo,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(birdRepositoryProvider);
      final normalizedRingNumber = _normalizeOptionalText(ringNumber);
      final normalizedCageNumber = _normalizeOptionalText(cageNumber);

      // Free tier bird limit check
      final isPremium = ref.read(effectivePremiumProvider);
      if (!isPremium) {
        try {
          await ref.read(freeTierLimitServiceProvider).guardBirdLimit(userId);
        } on FreeTierLimitException catch (e) {
          state = state.copyWith(
            isLoading: false,
            error: 'premium.bird_limit_reached'.tr(
              args: ['${e.limit}'],
            ),
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

      final bird = Bird(
        id: const Uuid().v4(),
        userId: userId,
        name: name,
        gender: gender,
        species: species,
        status: BirdStatus.alive,
        colorMutation: colorMutation,
        ringNumber: normalizedRingNumber,
        birthDate: birthDate,
        fatherId: fatherId,
        motherId: motherId,
        cageNumber: normalizedCageNumber,
        notes: notes,
        mutations: mutations,
        genotypeInfo: genotypeInfo,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.save(bird);

      // Calculate remaining birds for soft upsell
      int? remaining;
      if (!isPremium) {
        final afterCount = (await repo.getAll(userId)).length;
        remaining = AppConstants.freeTierMaxBirds - afterCount;
      }

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        remainingBirds: remaining,
      );
    } catch (e) {
      AppLogger.error('BirdFormNotifier', e, StackTrace.current);
      Sentry.captureException(e, stackTrace: StackTrace.current);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Updates an existing bird.
  Future<void> updateBird(Bird bird) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(birdRepositoryProvider);
      final normalizedRingNumber = _normalizeOptionalText(bird.ringNumber);
      final normalizedCageNumber = _normalizeOptionalText(bird.cageNumber);

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
          updatedAt: DateTime.now(),
        ),
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('BirdFormNotifier', e, StackTrace.current);
      Sentry.captureException(e, stackTrace: StackTrace.current);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Soft-deletes a bird.
  Future<void> deleteBird(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(birdRepositoryProvider);
      await repo.remove(id);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('BirdFormNotifier', e, StackTrace.current);
      Sentry.captureException(e, stackTrace: StackTrace.current);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Marks a bird as dead.
  Future<void> markAsDead(String id, {DateTime? deathDate}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(birdRepositoryProvider);
      final bird = await repo.getById(id);
      if (bird != null) {
        await repo.save(
          bird.copyWith(
            status: BirdStatus.dead,
            deathDate: deathDate ?? DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('BirdFormNotifier', e, StackTrace.current);
      Sentry.captureException(e, stackTrace: StackTrace.current);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Marks a bird as sold.
  Future<void> markAsSold(String id, {DateTime? soldDate}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(birdRepositoryProvider);
      final bird = await repo.getById(id);
      if (bird != null) {
        await repo.save(
          bird.copyWith(
            status: BirdStatus.sold,
            soldDate: soldDate ?? DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('BirdFormNotifier', e, StackTrace.current);
      Sentry.captureException(e, stackTrace: StackTrace.current);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Resets form state for a new operation.
  void reset() {
    state = const BirdFormState();
  }
}
