import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/photo_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/free_tier_limit_providers.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/sentry_error_filter.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:budgie_breeding_tracker/domain/services/birds/bird_lifecycle_service.dart';

part 'bird_form_actions.dart';

/// Form state and actions for creating/editing birds.
final birdFormStateProvider = NotifierProvider<BirdFormNotifier, BirdFormState>(
  BirdFormNotifier.new,
);

/// Source of the most recent state change. Allows BirdDetailScreen and
/// BirdFormScreen to filter their listeners when both are simultaneously
/// subscribed to the shared global notifier — without this, an edit pop'd
/// from form back to detail would double-fire success toasts.
enum BirdFormAction { none, save, statusChange, delete }

/// State for the bird form.
class BirdFormState {
  static const Object _unset = Object();

  final bool isLoading;
  final String? error;
  final String? warning;
  final bool isSuccess;
  final bool isBirdLimitReached;
  final int? remainingBirds;
  final BirdFormAction lastAction;

  const BirdFormState({
    this.isLoading = false,
    this.error,
    this.warning,
    this.isSuccess = false,
    this.isBirdLimitReached = false,
    this.remainingBirds,
    this.lastAction = BirdFormAction.none,
  });

  // error/warning/remainingBirds use an _unset sentinel so an intermediate
  // copyWith (e.g. isLoading: true) can't silently null out a value the
  // caller didn't intend to touch, and so passing an explicit `null` can
  // actually clear it (a plain `?? this.x` fallback can never do that) —
  // see egg_actions_notifier.dart for the same pattern.
  BirdFormState copyWith({
    bool? isLoading,
    Object? error = _unset,
    Object? warning = _unset,
    bool? isSuccess,
    bool? isBirdLimitReached,
    Object? remainingBirds = _unset,
    BirdFormAction? lastAction,
  }) {
    return BirdFormState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      warning: identical(warning, _unset) ? this.warning : warning as String?,
      isSuccess: isSuccess ?? this.isSuccess,
      isBirdLimitReached: isBirdLimitReached ?? this.isBirdLimitReached,
      remainingBirds: identical(remainingBirds, _unset)
          ? this.remainingBirds
          : remainingBirds as int?,
      lastAction: lastAction ?? this.lastAction,
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
    // Reset isSuccess / isBirdLimitReached on every action start so the
    // form/detail screen listeners don't re-fire stale "saved successfully"
    // toasts or limit dialogs from the previous action — see bulk-amplifier
    // bug in the post-fix audit.
    state = state.copyWith(
      isLoading: true,
      error: null,
      warning: null,
      isSuccess: false,
      isBirdLimitReached: false,
      remainingBirds: null,
    );
    try {
      final repo = ref.read(birdRepositoryProvider);
      await repo.remove(id);

      // Destructive parent rule: close active incubations when bird is deleted
      final cleanupOk = await ref
          .read(birdLifecycleServiceProvider)
          .cancelActiveBreedingsForBird(id);

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        warning: cleanupOk ? null : 'errors.background_tasks_partial'.tr(),
        lastAction: BirdFormAction.delete,
      );
    } catch (e, st) {
      AppLogger.error('BirdFormNotifier.deleteBird', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Marks a bird as dead.
  Future<void> markAsDead(String id, {DateTime? deathDate}) async {
    if (state.isLoading) return;
    // Reset isSuccess / isBirdLimitReached on every action start so the
    // form/detail screen listeners don't re-fire stale "saved successfully"
    // toasts or limit dialogs from the previous action — see bulk-amplifier
    // bug in the post-fix audit.
    state = state.copyWith(
      isLoading: true,
      error: null,
      warning: null,
      isSuccess: false,
      isBirdLimitReached: false,
      remainingBirds: null,
    );
    try {
      final repo = ref.read(birdRepositoryProvider);
      final bird = await repo.getById(id);
      var cleanupOk = true;
      if (bird != null) {
        await repo.save(
          bird.copyWith(
            status: BirdStatus.dead,
            deathDate: (deathDate ?? DateTime.now()).toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );

        // Destructive parent rule: close active incubations when bird is dead
        cleanupOk = await ref
            .read(birdLifecycleServiceProvider)
            .cancelActiveBreedingsForBird(id);
      } else {
        state = state.copyWith(isLoading: false, error: 'birds.not_found'.tr());
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        warning: cleanupOk ? null : 'errors.background_tasks_partial'.tr(),
        lastAction: BirdFormAction.statusChange,
      );
    } catch (e, st) {
      AppLogger.error('BirdFormNotifier.markAsDead', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Marks a bird as sold.
  Future<void> markAsSold(String id, {DateTime? soldDate}) async {
    if (state.isLoading) return;
    // Reset isSuccess / isBirdLimitReached on every action start so the
    // form/detail screen listeners don't re-fire stale "saved successfully"
    // toasts or limit dialogs from the previous action — see bulk-amplifier
    // bug in the post-fix audit.
    state = state.copyWith(
      isLoading: true,
      error: null,
      warning: null,
      isSuccess: false,
      isBirdLimitReached: false,
      remainingBirds: null,
    );
    try {
      final repo = ref.read(birdRepositoryProvider);
      final bird = await repo.getById(id);
      var cleanupOk = true;
      if (bird != null) {
        await repo.save(
          bird.copyWith(
            status: BirdStatus.sold,
            soldDate: (soldDate ?? DateTime.now()).toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );

        // Destructive parent rule: close active incubations when bird is sold
        cleanupOk = await ref
            .read(birdLifecycleServiceProvider)
            .cancelActiveBreedingsForBird(id);
      } else {
        state = state.copyWith(isLoading: false, error: 'birds.not_found'.tr());
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        warning: cleanupOk ? null : 'errors.background_tasks_partial'.tr(),
        lastAction: BirdFormAction.statusChange,
      );
    } catch (e, st) {
      AppLogger.error('BirdFormNotifier.markAsSold', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Marks a bird as gifted.
  Future<void> markAsGifted(String id, {DateTime? giftedDate}) async {
    if (state.isLoading) return;
    // Reset isSuccess / isBirdLimitReached on every action start so the
    // form/detail screen listeners don't re-fire stale "saved successfully"
    // toasts or limit dialogs from the previous action — see bulk-amplifier
    // bug in the post-fix audit.
    state = state.copyWith(
      isLoading: true,
      error: null,
      warning: null,
      isSuccess: false,
      isBirdLimitReached: false,
      remainingBirds: null,
    );
    try {
      final repo = ref.read(birdRepositoryProvider);
      final bird = await repo.getById(id);
      var cleanupOk = true;
      if (bird != null) {
        await repo.save(
          bird.copyWith(
            status: BirdStatus.gifted,
            soldDate: (giftedDate ?? DateTime.now()).toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );

        // Destructive parent rule: close active incubations when bird is gifted
        cleanupOk = await ref
            .read(birdLifecycleServiceProvider)
            .cancelActiveBreedingsForBird(id);
      } else {
        state = state.copyWith(isLoading: false, error: 'birds.not_found'.tr());
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        warning: cleanupOk ? null : 'errors.background_tasks_partial'.tr(),
        lastAction: BirdFormAction.statusChange,
      );
    } catch (e, st) {
      AppLogger.error('BirdFormNotifier.markAsGifted', e, st);
      reportIfUnexpected(e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  /// Resets form state for a new operation.
  void reset() {
    state = const BirdFormState();
  }
}
