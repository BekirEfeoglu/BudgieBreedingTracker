part of 'genealogy_providers.dart';

/// Offspring: birds and chicks that are children of a given bird.
/// Bird offspring found via fatherId/motherId filter (always succeeds).
/// Chick offspring found via breeding pair → incubation → egg → chick chain
/// (wrapped in try-catch for graceful degradation).
final offspringProvider =
    FutureProvider.family<({List<Bird> birds, List<Chick> chicks}), String>((
      ref,
      birdId,
    ) async {
      final userId = ref.watch(currentUserIdProvider);
      final birdRepo = ref.read(birdRepositoryProvider);

      // 1. Get all birds and find direct offspring (parent filter)
      final allBirds = await birdRepo.getAll(userId);
      final offspringBirds = allBirds
          .where((b) => b.fatherId == birdId || b.motherId == birdId)
          .toList();

      // 2. Find chick offspring via batch chain: pairs → incubations → eggs → chicks
      final offspringChicks = <Chick>[];
      try {
        final pairRepo = ref.read(breedingPairRepositoryProvider);
        final parentPairs = await pairRepo.getByBirdId(birdId);

        if (parentPairs.isNotEmpty) {
          final incubationRepo = ref.read(incubationRepositoryProvider);
          final eggRepo = ref.read(eggRepositoryProvider);
          final chickRepo = ref.read(chickRepositoryProvider);

          final allIncubations = await incubationRepo.getByBreedingPairIds(
            parentPairs.map((p) => p.id).toList(),
          );
          final allEggs = await eggRepo.getByIncubationIds(
            allIncubations.map((i) => i.id).toList(),
          );
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
final chickAncestorsProvider = FutureProvider.family<Map<String, Bird>, String>(
  (ref, chickId) async {
    final userId = ref.watch(currentUserIdProvider);
    final chickRepo = ref.read(chickRepositoryProvider);
    final eggRepo = ref.read(eggRepositoryProvider);
    final incubationRepo = ref.read(incubationRepositoryProvider);
    final pairRepo = ref.read(breedingPairRepositoryProvider);
    final birdRepo = ref.read(birdRepositoryProvider);
    final maxDepth = ref.watch(pedigreeDepthProvider);

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
      name:
          chick.name ??
          'chicks.unnamed_chick'.tr(
            args: [chick.ringNumber ?? chick.id.substring(0, 6)],
          ),
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
  },
);

/// View mode for pedigree tree display: tree (interactive) or list (flat).
enum TreeViewMode { tree, list }

/// Notifier for tree view mode toggle.
class TreeViewModeNotifier extends Notifier<TreeViewMode> {
  @override
  TreeViewMode build() => TreeViewMode.tree;
}

/// Provider for tree/list view mode in genealogy screen.
final treeViewModeProvider =
    NotifierProvider<TreeViewModeNotifier, TreeViewMode>(
      TreeViewModeNotifier.new,
    );

/// Repairs promoted birds with null parent IDs via chick → egg → pair chain.
final repairOrphanBirdsProvider = FutureProvider<int>((ref) async {
  final userId = ref.read(currentUserIdProvider);
  final birdRepo = ref.read(birdRepositoryProvider);
  final chickRepo = ref.read(chickRepositoryProvider);
  final eggRepo = ref.read(eggRepositoryProvider);
  final incubationRepo = ref.read(incubationRepositoryProvider);
  final pairRepo = ref.read(breedingPairRepositoryProvider);

  // Pre-fetch all entities into maps to avoid N+1 getById calls
  final (allBirds, allChicks, allEggs, allIncubations, allPairs) = await (
    birdRepo.getAll(userId),
    chickRepo.getAll(userId),
    eggRepo.getAll(userId),
    incubationRepo.getAll(userId),
    pairRepo.getAll(userId),
  ).wait;

  final eggMap = {for (final e in allEggs) e.id: e};
  final incubationMap = {for (final i in allIncubations) i.id: i};
  final pairMap = {for (final p in allPairs) p.id: p};

  final promotedChickMap = <String, Chick>{};
  for (final chick in allChicks) {
    if (chick.birdId != null) {
      promotedChickMap[chick.birdId!] = chick;
    }
  }

  int repairedCount = 0;
  final birdsToSave = <Bird>[];

  for (final bird in allBirds) {
    if (bird.fatherId != null || bird.motherId != null) continue;

    final chick = promotedChickMap[bird.id];
    if (chick == null || chick.eggId == null) continue;

    final egg = eggMap[chick.eggId!];
    if (egg == null || egg.incubationId == null) continue;

    final incubation = incubationMap[egg.incubationId!];
    if (incubation == null || incubation.breedingPairId == null) continue;

    final pair = pairMap[incubation.breedingPairId!];
    if (pair == null) continue;

    birdsToSave.add(
      bird.copyWith(
        fatherId: pair.maleId,
        motherId: pair.femaleId,
        updatedAt: DateTime.now(),
      ),
    );
    repairedCount++;
    AppLogger.info(
      'Repaired bird ${bird.name} (${bird.id}): '
      'father=${pair.maleId}, mother=${pair.femaleId}',
    );
  }

  if (birdsToSave.isNotEmpty) {
    await birdRepo.saveAll(birdsToSave);
  }

  return repairedCount;
});
