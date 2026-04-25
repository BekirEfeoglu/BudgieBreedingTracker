import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/photo_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/free_tier_limit_providers.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/sentry_error_filter.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

part 'bird_form_actions.dart';

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
      isBirdLimitReached: isBirdLimitReached ?? this.isBirdLimitReached,
      remainingBirds: remainingBirds ?? this.remainingBirds,
    );
  }
}

/// Notifier for bird form operations.
class BirdFormNotifier extends Notifier<BirdFormState>
    with SentryErrorFilter, _BirdFormActions {
  @override
  BirdFormState build() => const BirdFormState();

  /// Soft-deletes a bird.
  Future<void> deleteBird(String id) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(birdRepositoryProvider);
      await repo.remove(id);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('BirdFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Marks a bird as dead.
  Future<void> markAsDead(String id, {DateTime? deathDate}) async {
    if (state.isLoading) return;
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
      } else {
        state = state.copyWith(isLoading: false, error: 'birds.not_found'.tr());
        return;
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('BirdFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Marks a bird as sold.
  Future<void> markAsSold(String id, {DateTime? soldDate}) async {
    if (state.isLoading) return;
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
      } else {
        state = state.copyWith(isLoading: false, error: 'birds.not_found'.tr());
        return;
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('BirdFormNotifier', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Resets form state for a new operation.
  void reset() {
    state = const BirdFormState();
  }
}
