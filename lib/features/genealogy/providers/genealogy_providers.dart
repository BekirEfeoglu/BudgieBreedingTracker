import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

typedef GenealogySelection = ({String id, bool isChick});

class SelectedEntityForTreeNotifier extends Notifier<GenealogySelection?> {
  @override
  GenealogySelection? build() => null;
}

final selectedEntityForTreeProvider =
    NotifierProvider<SelectedEntityForTreeNotifier, GenealogySelection?>(SelectedEntityForTreeNotifier.new);

/// Notifier for pedigree depth: configurable 3-8 generations (default 5).
class PedigreeDepthNotifier extends Notifier<int> {
  @override
  int build() => 5;
}

final pedigreeDepthProvider =
    NotifierProvider<PedigreeDepthNotifier, int>(PedigreeDepthNotifier.new);

/// Initializes pedigree depth from SharedPreferences.
Future<void> initPedigreeDepth(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  final depth = (prefs.getInt(AppPreferences.keyPedigreeDepth) ?? 5).clamp(3, 8);
  ref.read(pedigreeDepthProvider.notifier).state = depth;
}

/// Persists pedigree depth and updates provider.
Future<void> setPedigreeDepth(WidgetRef ref, int depth) async {
  final clamped = depth.clamp(3, 8);
  ref.read(pedigreeDepthProvider.notifier).state = clamped;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(AppPreferences.keyPedigreeDepth, clamped);
}

/// Fetches ancestor birds using a single getAll() + local map traversal.
/// Much faster than N individual getById() calls.
final ancestorsProvider =
    FutureProvider.family<Map<String, Bird>, String>((ref, birdId) async {
  final userId = ref.read(currentUserIdProvider);
  final repo = ref.read(birdRepositoryProvider);
  final maxDepth = ref.read(pedigreeDepthProvider);

  // Single query: get all birds for this user and build a lookup map
  final allBirds = await repo.getAll(userId);
  final birdMap = {for (final b in allBirds) b.id: b};

  final ancestors = <String, Bird>{};

  void collectAncestors(String? id, int depth) {
    if (id == null || depth > maxDepth || ancestors.containsKey(id)) return;
    final bird = birdMap[id];
    if (bird == null) return;
    ancestors[id] = bird;
    collectAncestors(bird.fatherId, depth + 1);
    collectAncestors(bird.motherId, depth + 1);
  }

  final rootBird = birdMap[birdId];
  if (rootBird != null) {
    ancestors[birdId] = rootBird;
    collectAncestors(rootBird.fatherId, 1);
    collectAncestors(rootBird.motherId, 1);
  }

  return ancestors;
});

/// Offspring: birds and chicks that are children of a given bird.
/// Bird offspring found via fatherId/motherId filter (always succeeds).
/// Chick offspring found via breeding pair → incubation → egg → chick chain
/// (wrapped in try-catch for graceful degradation).
final offspringProvider = FutureProvider.family<
    ({List<Bird> birds, List<Chick> chicks}), String>((ref, birdId) async {
  final userId = ref.read(currentUserIdProvider);
  final birdRepo = ref.read(birdRepositoryProvider);

  // 1. Get all birds and find direct offspring (parent filter)
  final allBirds = await birdRepo.getAll(userId);
  final offspringBirds = allBirds
      .where((b) => b.fatherId == birdId || b.motherId == birdId)
      .toList();

  // 2. Find chick offspring via batch chain: pairs → incubations → eggs → chicks
  // Wrapped in try-catch so bird offspring always returns even if this fails.
  final offspringChicks = <Chick>[];
  try {
    final pairRepo = ref.read(breedingPairRepositoryProvider);
    final parentPairs = await pairRepo.getByBirdId(birdId);

    if (parentPairs.isNotEmpty) {
      final incubationRepo = ref.read(incubationRepositoryProvider);
      final eggRepo = ref.read(eggRepositoryProvider);
      final chickRepo = ref.read(chickRepositoryProvider);

      // Batch: all incubations for all pairs (1 query)
      final allIncubations = await incubationRepo.getByBreedingPairIds(
        parentPairs.map((p) => p.id).toList(),
      );

      // Batch: all eggs for all incubations (1 query)
      final allEggs = await eggRepo.getByIncubationIds(
        allIncubations.map((i) => i.id).toList(),
      );

      // Batch: all chicks for all eggs (1 query)
      final allChicks = await chickRepo.getByEggIds(
        allEggs.map((e) => e.id).toList(),
      );

      for (final chick in allChicks) {
        if (chick.birdId == null) {
          offspringChicks.add(chick);
        }
      }
    }
  } catch (e) {
    AppLogger.warning('Failed to resolve chick offspring: $e');
  }

  return (birds: offspringBirds, chicks: offspringChicks);
});

/// Resolves a chick's ancestor tree via egg → incubation → breeding pair chain.
final chickAncestorsProvider =
    FutureProvider.family<Map<String, Bird>, String>((ref, chickId) async {
  final userId = ref.read(currentUserIdProvider);
  final chickRepo = ref.read(chickRepositoryProvider);
  final eggRepo = ref.read(eggRepositoryProvider);
  final incubationRepo = ref.read(incubationRepositoryProvider);
  final pairRepo = ref.read(breedingPairRepositoryProvider);
  final birdRepo = ref.read(birdRepositoryProvider);
  final maxDepth = ref.read(pedigreeDepthProvider);

  final chick = await chickRepo.getById(chickId);
  if (chick == null) return {};

  // Resolve parents via egg → incubation → breeding pair chain
  String? fatherId;
  String? motherId;

  if (chick.eggId != null) {
    final egg = await eggRepo.getById(chick.eggId!);
    if (egg != null && egg.incubationId != null) {
      final incubation = await incubationRepo.getById(egg.incubationId!);
      if (incubation != null && incubation.breedingPairId != null) {
        final pair = await pairRepo.getById(incubation.breedingPairId!);
        if (pair != null) {
          fatherId = pair.maleId;
          motherId = pair.femaleId;
        }
      }
    }
  }

  // Create pseudo-Bird from Chick for root node display
  final pseudoBird = Bird(
    id: chick.id,
    userId: chick.userId,
    name: chick.name ??
        'chicks.unnamed_chick'.tr(args: [chick.ringNumber ?? chick.id.substring(0, 6)]),
    gender: chick.gender,
    ringNumber: chick.ringNumber,
    fatherId: fatherId,
    motherId: motherId,
    birthDate: chick.hatchDate,
    status: chick.healthStatus == ChickHealthStatus.deceased
        ? BirdStatus.dead
        : BirdStatus.alive,
  );

  // Build ancestor map using single getAll + local traversal
  final allBirds = await birdRepo.getAll(userId);
  final birdMap = {for (final b in allBirds) b.id: b};

  final ancestors = <String, Bird>{chick.id: pseudoBird};

  void collectAncestors(String? id, int depth) {
    if (id == null || depth > maxDepth || ancestors.containsKey(id)) return;
    final bird = birdMap[id];
    if (bird == null) return;
    ancestors[id] = bird;
    collectAncestors(bird.fatherId, depth + 1);
    collectAncestors(bird.motherId, depth + 1);
  }

  collectAncestors(fatherId, 1);
  collectAncestors(motherId, 1);

  return ancestors;
});

/// Repairs promoted birds with null parent IDs via chick → egg → pair chain.
final repairOrphanBirdsProvider = FutureProvider<int>((ref) async {
  final userId = ref.read(currentUserIdProvider);
  final birdRepo = ref.read(birdRepositoryProvider);
  final chickRepo = ref.read(chickRepositoryProvider);
  final eggRepo = ref.read(eggRepositoryProvider);
  final incubationRepo = ref.read(incubationRepositoryProvider);
  final pairRepo = ref.read(breedingPairRepositoryProvider);

  final allBirds = await birdRepo.getAll(userId);
  final allChicks = await chickRepo.getAll(userId);

  // Build a map of birdId → chick for quick lookup
  final promotedChickMap = <String, Chick>{};
  for (final chick in allChicks) {
    if (chick.birdId != null) {
      promotedChickMap[chick.birdId!] = chick;
    }
  }

  int repairedCount = 0;

  for (final bird in allBirds) {
    // Skip birds that already have parents
    if (bird.fatherId != null || bird.motherId != null) continue;

    // Find the chick that was promoted to this bird
    final chick = promotedChickMap[bird.id];
    if (chick == null || chick.eggId == null) continue;

    try {
      final egg = await eggRepo.getById(chick.eggId!);
      if (egg == null || egg.incubationId == null) continue;

      final incubation = await incubationRepo.getById(egg.incubationId!);
      if (incubation == null || incubation.breedingPairId == null) continue;

      final pair = await pairRepo.getById(incubation.breedingPairId!);
      if (pair == null) continue;

      // Update bird with resolved parent IDs
      await birdRepo.save(bird.copyWith(
        fatherId: pair.maleId,
        motherId: pair.femaleId,
        updatedAt: DateTime.now(),
      ));
      repairedCount++;
      AppLogger.info(
        'Repaired bird ${bird.name} (${bird.id}): '
        'father=${pair.maleId}, mother=${pair.femaleId}',
      );
    } catch (e) {
      AppLogger.warning('Failed to repair bird ${bird.id}: $e');
    }
  }

  return repairedCount;
});
