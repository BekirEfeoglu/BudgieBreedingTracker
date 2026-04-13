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
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';

part 'genealogy_offspring_providers.dart';

typedef GenealogySelection = ({String id, bool isChick});

class SelectedEntityForTreeNotifier extends Notifier<GenealogySelection?> {
  @override
  GenealogySelection? build() => null;
}

final selectedEntityForTreeProvider =
    NotifierProvider<SelectedEntityForTreeNotifier, GenealogySelection?>(
      SelectedEntityForTreeNotifier.new,
    );

/// Notifier for pedigree depth: configurable 3-8 generations (default 5).
class PedigreeDepthNotifier extends Notifier<int> {
  @override
  int build() => 5;

  void setDepth(int depth) {
    state = depth.clamp(3, 8);
  }
}

final pedigreeDepthProvider = NotifierProvider<PedigreeDepthNotifier, int>(
  PedigreeDepthNotifier.new,
);

/// Initializes pedigree depth from SharedPreferences.
Future<void> initPedigreeDepth(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  final depth = (prefs.getInt(AppPreferences.keyPedigreeDepth) ?? 5).clamp(
    3,
    8,
  );
  ref.read(pedigreeDepthProvider.notifier).setDepth(depth);
}

/// Persists pedigree depth and updates provider.
Future<void> setPedigreeDepth(WidgetRef ref, int depth) async {
  final clamped = depth.clamp(3, 8);
  ref.read(pedigreeDepthProvider.notifier).setDepth(clamped);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(AppPreferences.keyPedigreeDepth, clamped);
}

/// Fetches ancestor birds using a single getAll() + local map traversal.
/// Much faster than N individual getById() calls.
final ancestorsProvider = FutureProvider.family<Map<String, Bird>, String>((
  ref,
  birdId,
) async {
  final userId = ref.watch(currentUserIdProvider);
  final repo = ref.read(birdRepositoryProvider);
  final maxDepth = ref.watch(pedigreeDepthProvider);

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
