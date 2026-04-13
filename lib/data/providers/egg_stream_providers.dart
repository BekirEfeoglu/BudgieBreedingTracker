import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

/// All eggs for a user (live stream).
///
/// Single source of truth - imported by home, breeding, and statistics.
final eggsStreamProvider = StreamProvider.family<List<Egg>, String>((
  ref,
  userId,
) {
  final repo = ref.watch(eggRepositoryProvider);
  return repo.watchAll(userId);
});

/// Eggs for a specific incubation (live stream).
final eggsForIncubationProvider = StreamProvider.family<List<Egg>, String>((
  ref,
  incubationId,
) {
  final repo = ref.watch(eggRepositoryProvider);
  return repo.watchByIncubation(incubationId);
});
