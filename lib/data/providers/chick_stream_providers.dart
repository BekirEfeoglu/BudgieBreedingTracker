import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_providers.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_url_resolver.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

typedef ChickParentsInfo = ({
  String? maleName,
  String? femaleName,
  String? maleId,
  String? femaleId,
  String? cageNumber,
});

/// All chicks for a user (live stream).
final chicksStreamProvider = StreamProvider.family<List<Chick>, String>((
  ref,
  userId,
) {
  final repo = ref.watch(chickRepositoryProvider);
  final resolver = ref.watch(storageUrlResolverProvider);
  return repo
      .watchAll(userId)
      .asyncMap(
        (chicks) => Future.wait(
          chicks.map((chick) => _resolveChickPhoto(chick, resolver)),
        ),
      );
});

/// Single chick by ID (live stream).
final chickByIdProvider = StreamProvider.family<Chick?, String>((ref, id) {
  final repo = ref.watch(chickRepositoryProvider);
  final resolver = ref.watch(storageUrlResolverProvider);
  return repo.watchById(id).asyncMap((chick) async {
    if (chick == null) return null;
    return _resolveChickPhoto(chick, resolver);
  });
});

Future<Chick> _resolveChickPhoto(
  Chick chick,
  StorageUrlResolver resolver,
) async {
  final photoUrl = await resolver.resolve(chick.photoUrl);
  return photoUrl == chick.photoUrl
      ? chick
      : chick.copyWith(photoUrl: photoUrl);
}

/// Parent bird info for a chick (looked up via egg → incubation/clutch → pair).
/// Takes the chick's eggId and returns parent names.
final chickParentsProvider = FutureProvider.family<ChickParentsInfo?, String?>((
  ref,
  eggId,
) async {
  if (eggId == null) return null;

  try {
    final eggRepo = ref.read(eggRepositoryProvider);
    final egg = await eggRepo.getById(eggId);
    if (egg == null) return null;

    return _resolveParentsForEgg(ref, egg);
  } catch (e) {
    AppLogger.error('Failed to load chick parents', e);
    return null;
  }
});

Future<ChickParentsInfo?> _resolveParentsForEgg(Ref ref, Egg egg) async {
  final incubationRepo = ref.read(incubationRepositoryProvider);
  final pairRepo = ref.read(breedingPairRepositoryProvider);

  BreedingPair? pair;
  Clutch? clutch;

  final incubationId = egg.incubationId;
  if (incubationId != null) {
    final incubation = await incubationRepo.getById(incubationId);
    final pairId = incubation?.breedingPairId;
    if (pairId != null) {
      pair = await pairRepo.getById(pairId);
    }
  }

  final clutchId = egg.clutchId;
  if (clutchId != null) {
    final clutchRepo = ref.read(clutchRepositoryProvider);
    clutch = await clutchRepo.getById(clutchId);
    final pairId = clutch?.breedingId;
    if (pair == null && pairId != null) {
      pair = await pairRepo.getById(pairId);
    }

    final clutchIncubationId = clutch?.incubationId;
    if (pair == null && clutchIncubationId != null) {
      final incubation = await incubationRepo.getById(clutchIncubationId);
      final incubationPairId = incubation?.breedingPairId;
      if (incubationPairId != null) {
        pair = await pairRepo.getById(incubationPairId);
      }
    }
  }

  final maleId = pair?.maleId ?? clutch?.maleBirdId;
  final femaleId = pair?.femaleId ?? clutch?.femaleBirdId;
  if (pair == null && maleId == null && femaleId == null) return null;

  final birdRepo = ref.read(birdRepositoryProvider);
  final male = maleId != null ? await birdRepo.getById(maleId) : null;
  final female = femaleId != null ? await birdRepo.getById(femaleId) : null;

  return (
    maleName: _birdDisplayName(male),
    femaleName: _birdDisplayName(female),
    maleId: maleId,
    femaleId: femaleId,
    cageNumber: pair?.cageNumber,
  );
}

String? _birdDisplayName(Bird? bird) => bird?.name ?? bird?.ringNumber;

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
        final clutchRepo = ref.read(clutchRepositoryProvider);
        final pairRepo = ref.read(breedingPairRepositoryProvider);
        final birdRepo = ref.read(birdRepositoryProvider);

        final (eggs, incubations, clutches, pairs, birds) = await (
          eggRepo.getAll(userId),
          incubationRepo.getAll(userId),
          clutchRepo.getAll(userId),
          pairRepo.getAll(userId),
          birdRepo.getAll(userId),
        ).wait;

        final incubationById = {for (final inc in incubations) inc.id: inc};
        final clutchById = {for (final clutch in clutches) clutch.id: clutch};
        final pairById = {for (final pair in pairs) pair.id: pair};
        final birdById = {for (final bird in birds) bird.id: bird};

        final result = <String, ChickParentsInfo>{};
        for (final egg in eggs) {
          final clutch = egg.clutchId == null ? null : clutchById[egg.clutchId];
          final incubationId = egg.incubationId ?? clutch?.incubationId;

          final pairId =
              (incubationId == null
                  ? null
                  : incubationById[incubationId]?.breedingPairId) ??
              clutch?.breedingId;

          final pair = pairId == null ? null : pairById[pairId];
          final maleId = pair?.maleId ?? clutch?.maleBirdId;
          final femaleId = pair?.femaleId ?? clutch?.femaleBirdId;
          if (pair == null && maleId == null && femaleId == null) continue;

          final male = maleId != null ? birdById[maleId] : null;
          final female = femaleId != null ? birdById[femaleId] : null;

          result[egg.id] = (
            maleName: _birdDisplayName(male),
            femaleName: _birdDisplayName(female),
            maleId: maleId,
            femaleId: femaleId,
            cageNumber: pair?.cageNumber,
          );
        }
        return result;
      } catch (e, st) {
        AppLogger.error('Failed to batch load chick parents', e, st);
        return {};
      }
    });
