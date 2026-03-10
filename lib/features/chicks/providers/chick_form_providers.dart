import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_settings_providers.dart';
import 'package:uuid/uuid.dart';

/// State for the chick form.
class ChickFormState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const ChickFormState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  ChickFormState copyWith({bool? isLoading, String? error, bool? isSuccess}) {
    return ChickFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Notifier for chick form operations.
class ChickFormNotifier extends Notifier<ChickFormState> {
  @override
  ChickFormState build() => const ChickFormState();

  /// Creates a new chick.
  Future<void> createChick({
    required String userId,
    String? name,
    BirdGender gender = BirdGender.unknown,
    ChickHealthStatus healthStatus = ChickHealthStatus.healthy,
    String? clutchId,
    String? eggId,
    required DateTime hatchDate,
    double? hatchWeight,
    String? ringNumber,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(chickRepositoryProvider);
      final chick = Chick(
        id: const Uuid().v4(),
        userId: userId,
        name: name,
        gender: gender,
        healthStatus: healthStatus,
        clutchId: clutchId,
        eggId: eggId,
        hatchDate: hatchDate,
        hatchWeight: hatchWeight,
        ringNumber: ringNumber,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.save(chick);

      // Schedule chick care reminders (feeding every 4 hours for 14 days)
      try {
        final scheduler = ref.read(notificationSchedulerProvider);
        final settings = ref.read(notificationToggleSettingsProvider);
        await scheduler.scheduleChickCareReminder(
          chickId: chick.id,
          chickLabel:
              name ??
              'chicks.unnamed_chick'.tr(
                args: [ringNumber ?? chick.id.substring(0, 6)],
              ),
          startDate: hatchDate,
          intervalHours: 4,
          durationDays: 14,
          settings: settings,
        );
      } catch (e) {
        AppLogger.warning('Failed to schedule chick care reminders: $e');
      }

      // Auto-generate chick milestone calendar events
      try {
        final calendarGen = ref.read(calendarEventGeneratorProvider);
        await calendarGen.generateChickEvents(
          userId: userId,
          hatchDate: hatchDate,
          chickLabel:
              name ??
              'chicks.unnamed_chick'.tr(
                args: [ringNumber ?? chick.id.substring(0, 6)],
              ),
        );
      } catch (e) {
        if (_isSupabaseUnavailableError(e)) {
          AppLogger.info(
            'Skipping chick calendar generation: Supabase is not initialized',
          );
        } else {
          AppLogger.warning('Failed to generate chick calendar events: $e');
        }
      }

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('ChickFormNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Updates an existing chick.
  Future<void> updateChick(Chick chick) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(chickRepositoryProvider);
      await repo.save(chick.copyWith(updatedAt: DateTime.now()));
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('ChickFormNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Soft-deletes a chick.
  Future<void> deleteChick(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(chickRepositoryProvider);
      await repo.remove(id);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('ChickFormNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Marks a chick as weaned.
  Future<void> markAsWeaned(String id, {DateTime? weanDate}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(chickRepositoryProvider);
      final chick = await repo.getById(id);
      if (chick != null) {
        await repo.save(
          chick.copyWith(
            weanDate: weanDate ?? DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('ChickFormNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Marks a chick as deceased.
  Future<void> markAsDeceased(String id, {DateTime? deathDate}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(chickRepositoryProvider);
      final chick = await repo.getById(id);
      if (chick != null) {
        await repo.save(
          chick.copyWith(
            healthStatus: ChickHealthStatus.deceased,
            deathDate: deathDate ?? DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('ChickFormNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Promotes a chick to a Bird. Creates a new Bird and sets chick.birdId.
  /// Resolves parent IDs from the breeding pair via egg → incubation → pair.
  Future<void> promoteToBird(Chick chick) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final birdRepo = ref.read(birdRepositoryProvider);
      final chickRepo = ref.read(chickRepositoryProvider);

      // Resolve parent IDs from breeding pair chain
      String? fatherId;
      String? motherId;
      if (chick.eggId != null) {
        try {
          final eggRepo = ref.read(eggRepositoryProvider);
          final egg = await eggRepo.getById(chick.eggId!);
          if (egg != null && egg.incubationId != null) {
            final incubationRepo = ref.read(incubationRepositoryProvider);
            final incubation = await incubationRepo.getById(egg.incubationId!);
            if (incubation != null && incubation.breedingPairId != null) {
              final pairRepo = ref.read(breedingPairRepositoryProvider);
              final pair = await pairRepo.getById(incubation.breedingPairId!);
              if (pair != null) {
                fatherId = pair.maleId;
                motherId = pair.femaleId;
              }
            }
          }
        } catch (e) {
          AppLogger.warning(
            'Failed to resolve parents for chick promotion: $e',
          );
        }
      }

      final birdId = const Uuid().v4();
      final bird = Bird(
        id: birdId,
        userId: chick.userId,
        name:
            chick.name ??
            'chicks.unnamed_chick'.tr(
              args: [chick.ringNumber ?? chick.id.substring(0, 6)],
            ),
        gender: chick.gender,
        species: Species.budgie,
        status: BirdStatus.alive,
        ringNumber: chick.ringNumber,
        birthDate: chick.hatchDate,
        photoUrl: chick.photoUrl,
        notes: chick.notes,
        fatherId: fatherId,
        motherId: motherId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await birdRepo.save(bird);
      await chickRepo.save(
        chick.copyWith(
          birdId: birdId,
          weanDate: chick.weanDate ?? DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('ChickFormNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Resets form state for a new operation.
  void reset() {
    state = const ChickFormState();
  }

  bool _isSupabaseUnavailableError(Object error) {
    final message = error.toString();
    return message.contains('You must initialize the supabase instance') ||
        message.contains('provider that is in error state');
  }
}

/// Form state and actions for creating/editing chicks.
final chickFormStateProvider =
    NotifierProvider<ChickFormNotifier, ChickFormState>(ChickFormNotifier.new);
