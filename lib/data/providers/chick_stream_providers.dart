import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

typedef ChickParentsInfo = ({
  String? maleName,
  String? femaleName,
  String? maleId,
  String? femaleId,
});

/// All chicks for a user (live stream).
final chicksStreamProvider = StreamProvider.family<List<Chick>, String>((
  ref,
  userId,
) {
  final repo = ref.watch(chickRepositoryProvider);
  return repo.watchAll(userId);
});

/// Single chick by ID (live stream).
final chickByIdProvider = StreamProvider.family<Chick?, String>((ref, id) {
  final repo = ref.watch(chickRepositoryProvider);
  return repo.watchById(id);
});

/// Parent bird info for a chick (looked up via egg → incubation → breeding pair).
/// Takes the chick's eggId and returns parent names.
final chickParentsProvider = FutureProvider.family<ChickParentsInfo?, String?>((
  ref,
  eggId,
) async {
  if (eggId == null) return null;

  try {
    final eggRepo = ref.read(eggRepositoryProvider);
    final egg = await eggRepo.getById(eggId);
    if (egg == null || egg.incubationId == null) return null;

    final incubationRepo = ref.read(incubationRepositoryProvider);
    final incubation = await incubationRepo.getById(egg.incubationId!);
    if (incubation == null || incubation.breedingPairId == null) return null;

    final pairRepo = ref.read(breedingPairRepositoryProvider);
    final pair = await pairRepo.getById(incubation.breedingPairId!);
    if (pair == null) return null;

    final birdRepo = ref.read(birdRepositoryProvider);
    String? maleName;
    String? femaleName;

    if (pair.maleId != null) {
      final male = await birdRepo.getById(pair.maleId!);
      maleName = male?.name ?? male?.ringNumber;
    }
    if (pair.femaleId != null) {
      final female = await birdRepo.getById(pair.femaleId!);
      femaleName = female?.name ?? female?.ringNumber;
    }

    return (
      maleName: maleName,
      femaleName: femaleName,
      maleId: pair.maleId,
      femaleId: pair.femaleId,
    );
  } catch (e) {
    AppLogger.error('Failed to load chick parents', e);
    return null;
  }
});

/// Batched parent lookup map keyed by eggId.
///
/// Avoids per-card chained lookups in list/grid screens.
final chickParentsByEggProvider =
    FutureProvider.family<Map<String, ChickParentsInfo>, String>((
      ref,
      userId,
    ) async {
      try {
        final eggRepo = ref.read(eggRepositoryProvider);
        final incubationRepo = ref.read(incubationRepositoryProvider);
        final pairRepo = ref.read(breedingPairRepositoryProvider);
        final birdRepo = ref.read(birdRepositoryProvider);

        final (eggs, incubations, pairs, birds) = await (
          eggRepo.getAll(userId),
          incubationRepo.getAll(userId),
          pairRepo.getAll(userId),
          birdRepo.getAll(userId),
        ).wait;

        final incubationById = {for (final inc in incubations) inc.id: inc};
        final pairById = {for (final pair in pairs) pair.id: pair};
        final birdById = {for (final bird in birds) bird.id: bird};

        final result = <String, ChickParentsInfo>{};
        for (final egg in eggs) {
          final incubationId = egg.incubationId;
          if (incubationId == null) continue;

          final pairId = incubationById[incubationId]?.breedingPairId;
          if (pairId == null) continue;

          final pair = pairById[pairId];
          if (pair == null) continue;

          final male = pair.maleId != null ? birdById[pair.maleId!] : null;
          final female = pair.femaleId != null
              ? birdById[pair.femaleId!]
              : null;

          result[egg.id] = (
            maleName: male?.name ?? male?.ringNumber,
            femaleName: female?.name ?? female?.ringNumber,
            maleId: pair.maleId,
            femaleId: pair.femaleId,
          );
        }
        return result;
      } catch (e, st) {
        AppLogger.error('Failed to batch load chick parents', e, st);
        return {};
      }
    });
