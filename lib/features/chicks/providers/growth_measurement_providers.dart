import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:uuid/uuid.dart';

/// Growth measurements for a specific chick (live stream).
final growthMeasurementsStreamProvider =
    StreamProvider.family<List<GrowthMeasurement>, String>((ref, chickId) {
  final repo = ref.watch(growthMeasurementRepositoryProvider);
  return repo.watchByChick(chickId);
});

/// Latest measurement for a chick.
final latestMeasurementProvider =
    FutureProvider.family<GrowthMeasurement?, String>((ref, chickId) {
  final repo = ref.watch(growthMeasurementRepositoryProvider);
  return repo.getLatest(chickId);
});

/// State for growth measurement actions.
class GrowthMeasurementActionsState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const GrowthMeasurementActionsState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  GrowthMeasurementActionsState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return GrowthMeasurementActionsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Notifier for growth measurement operations.
class GrowthMeasurementActionsNotifier
    extends Notifier<GrowthMeasurementActionsState> {
  @override
  GrowthMeasurementActionsState build() =>
      const GrowthMeasurementActionsState();

  /// Adds a new growth measurement.
  Future<void> addMeasurement({
    required String chickId,
    required String userId,
    required double weight,
    required DateTime measurementDate,
    double? height,
    double? wingLength,
    double? tailLength,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(growthMeasurementRepositoryProvider);
      final measurement = GrowthMeasurement(
        id: const Uuid().v4(),
        chickId: chickId,
        userId: userId,
        weight: weight,
        measurementDate: measurementDate,
        height: height,
        wingLength: wingLength,
        tailLength: tailLength,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.save(measurement);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('GrowthMeasurementActionsNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Deletes a growth measurement (hard delete).
  Future<void> deleteMeasurement(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(growthMeasurementRepositoryProvider);
      await repo.remove(id);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      AppLogger.error('GrowthMeasurementActionsNotifier', e, StackTrace.current);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Resets the action state.
  void reset() {
    state = const GrowthMeasurementActionsState();
  }
}

/// Actions notifier for growth measurement CRUD operations.
final growthMeasurementActionsProvider =
    NotifierProvider<GrowthMeasurementActionsNotifier,
        GrowthMeasurementActionsState>(
        GrowthMeasurementActionsNotifier.new);
