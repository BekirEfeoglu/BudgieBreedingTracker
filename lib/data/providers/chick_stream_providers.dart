import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
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
  } catch (e, st) {
    AppLogger.error('Failed to load chick parents', e, st);
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
    StreamProvider.family<Map<String, ChickParentsInfo>, String>((ref, userId) {
      final eggRepo = ref.watch(eggRepositoryProvider);
      final incubationRepo = ref.watch(incubationRepositoryProvider);
      final clutchRepo = ref.watch(clutchRepositoryProvider);
      final pairRepo = ref.watch(breedingPairRepositoryProvider);
      final birdRepo = ref.watch(birdRepositoryProvider);

      return _watchChickParentsByEgg(
        eggs: eggRepo.watchAll(userId),
        incubations: incubationRepo.watchAll(userId),
        clutches: clutchRepo.watchAll(userId),
        pairs: pairRepo.watchAll(userId),
        birds: birdRepo.watchAll(userId),
      );
    });

Stream<Map<String, ChickParentsInfo>> _watchChickParentsByEgg({
  required Stream<List<Egg>> eggs,
  required Stream<List<Incubation>> incubations,
  required Stream<List<Clutch>> clutches,
  required Stream<List<BreedingPair>> pairs,
  required Stream<List<Bird>> birds,
}) async* {
  try {
    yield* _combineLatest5<
      List<Egg>,
      List<Incubation>,
      List<Clutch>,
      List<BreedingPair>,
      List<Bird>,
      Map<String, ChickParentsInfo>
    >(
      eggs,
      incubations,
      clutches,
      pairs,
      birds,
      (eggs, incubations, clutches, pairs, birds) => _buildParentsByEgg(
        eggs: eggs,
        incubations: incubations,
        clutches: clutches,
        pairs: pairs,
        birds: birds,
      ),
    );
  } catch (e, st) {
    AppLogger.error('Failed to batch load chick parents', e, st);
    yield {};
  }
}

Map<String, ChickParentsInfo> _buildParentsByEgg({
  required List<Egg> eggs,
  required List<Incubation> incubations,
  required List<Clutch> clutches,
  required List<BreedingPair> pairs,
  required List<Bird> birds,
}) {
  final incubationById = {
    for (final incubation in incubations) incubation.id: incubation,
  };
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
}

Stream<R> _combineLatest5<A, B, C, D, E, R>(
  Stream<A> streamA,
  Stream<B> streamB,
  Stream<C> streamC,
  Stream<D> streamD,
  Stream<E> streamE,
  R Function(A a, B b, C c, D d, E e) combine,
) {
  late final StreamController<R> controller;
  StreamSubscription<A>? subscriptionA;
  StreamSubscription<B>? subscriptionB;
  StreamSubscription<C>? subscriptionC;
  StreamSubscription<D>? subscriptionD;
  StreamSubscription<E>? subscriptionE;
  A? latestA;
  B? latestB;
  C? latestC;
  D? latestD;
  E? latestE;
  var hasA = false;
  var hasB = false;
  var hasC = false;
  var hasD = false;
  var hasE = false;
  var doneA = false;
  var doneB = false;
  var doneC = false;
  var doneD = false;
  var doneE = false;

  void emitIfReady() {
    if (!hasA || !hasB || !hasC || !hasD || !hasE) return;
    try {
      controller.add(
        combine(
          latestA as A,
          latestB as B,
          latestC as C,
          latestD as D,
          latestE as E,
        ),
      );
    } catch (e, st) {
      AppLogger.error('Failed to combine chick parents stream values', e, st);
      controller.addError(e, st);
    }
  }

  void closeIfDone() {
    if (!doneA || !doneB || !doneC || !doneD || !doneE) return;
    if (!controller.isClosed) {
      unawaited(controller.close());
    }
  }

  controller = StreamController<R>(
    onListen: () {
      subscriptionA = streamA.listen(
        (value) {
          latestA = value;
          hasA = true;
          emitIfReady();
        },
        onError: controller.addError,
        onDone: () {
          doneA = true;
          closeIfDone();
        },
      );
      subscriptionB = streamB.listen(
        (value) {
          latestB = value;
          hasB = true;
          emitIfReady();
        },
        onError: controller.addError,
        onDone: () {
          doneB = true;
          closeIfDone();
        },
      );
      subscriptionC = streamC.listen(
        (value) {
          latestC = value;
          hasC = true;
          emitIfReady();
        },
        onError: controller.addError,
        onDone: () {
          doneC = true;
          closeIfDone();
        },
      );
      subscriptionD = streamD.listen(
        (value) {
          latestD = value;
          hasD = true;
          emitIfReady();
        },
        onError: controller.addError,
        onDone: () {
          doneD = true;
          closeIfDone();
        },
      );
      subscriptionE = streamE.listen(
        (value) {
          latestE = value;
          hasE = true;
          emitIfReady();
        },
        onError: controller.addError,
        onDone: () {
          doneE = true;
          closeIfDone();
        },
      );
    },
    onPause: () {
      subscriptionA?.pause();
      subscriptionB?.pause();
      subscriptionC?.pause();
      subscriptionD?.pause();
      subscriptionE?.pause();
    },
    onResume: () {
      subscriptionA?.resume();
      subscriptionB?.resume();
      subscriptionC?.resume();
      subscriptionD?.resume();
      subscriptionE?.resume();
    },
    onCancel: () async {
      await Future.wait<void>([
        subscriptionA?.cancel() ?? Future<void>.value(),
        subscriptionB?.cancel() ?? Future<void>.value(),
        subscriptionC?.cancel() ?? Future<void>.value(),
        subscriptionD?.cancel() ?? Future<void>.value(),
        subscriptionE?.cancel() ?? Future<void>.value(),
      ]);
    },
  );

  return controller.stream;
}
