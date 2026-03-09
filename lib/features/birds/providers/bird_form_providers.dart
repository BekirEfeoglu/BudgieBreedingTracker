import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
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

      // Free tier bird limit check
      final isPremium = ref.read(isPremiumProvider);
      if (!isPremium) {
        final existingBirds = await repo.getAll(userId);
        if (existingBirds.length >= AppConstants.freeTierMaxBirds) {
          state = state.copyWith(
            isLoading: false,
            error: 'premium.bird_limit_reached'.tr(
              args: ['${AppConstants.freeTierMaxBirds}'],
            ),
            isBirdLimitReached: true,
          );
          return;
        }
      }

      final bird = Bird(
        id: const Uuid().v4(),
        userId: userId,
        name: name,
        gender: gender,
        species: species,
        status: BirdStatus.alive,
        colorMutation: colorMutation,
        ringNumber: ringNumber,
        birthDate: birthDate,
        fatherId: fatherId,
        motherId: motherId,
        cageNumber: cageNumber,
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
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Updates an existing bird.
  Future<void> updateBird(Bird bird) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(birdRepositoryProvider);
      await repo.save(bird.copyWith(updatedAt: DateTime.now()));
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('BirdFormNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
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
      state = state.copyWith(isLoading: false, error: e.toString());
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
      state = state.copyWith(isLoading: false, error: e.toString());
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
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Resets form state for a new operation.
  void reset() {
    state = const BirdFormState();
  }
}
