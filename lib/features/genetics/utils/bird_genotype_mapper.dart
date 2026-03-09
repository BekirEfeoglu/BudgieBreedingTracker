import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

/// Shared mapping helpers between Bird records and genetics genotype state.
abstract final class BirdGenotypeMapper {
  /// Converts a persisted [Bird] to [ParentGenotype].
  ///
  /// Priority:
  /// 1. Explicit [Bird.mutations] + [Bird.genotypeInfo]
  /// 2. Fallback from [Bird.colorMutation]
  static ParentGenotype birdToGenotype(Bird bird) {
    final mutations = <String, AlleleState>{};

    if (bird.mutations != null && bird.mutations!.isNotEmpty) {
      for (final mutationId in bird.mutations!) {
        final stateValue = bird.genotypeInfo?[mutationId];
        mutations[mutationId] = switch (stateValue) {
          'carrier' => AlleleState.carrier,
          'split' => AlleleState.split,
          _ => AlleleState.visual,
        };
      }
    } else {
      final fallback = genotypeFromColor(
        gender: bird.gender,
        color: bird.colorMutation,
      );
      mutations.addAll(fallback.mutations);
    }

    return ParentGenotype(mutations: mutations, gender: bird.gender);
  }

  /// Builds a best-effort genotype from a single [BirdColor].
  ///
  /// Ambiguous labels (like generic pied) intentionally map to no mutation IDs.
  static ParentGenotype genotypeFromColor({
    required BirdGender gender,
    required BirdColor? color,
  }) {
    if (color == null) {
      return ParentGenotype.empty(gender: gender);
    }

    final mutationIds = colorToMutationIds(color);
    final mutations = <String, AlleleState>{
      for (final id in mutationIds) id: AlleleState.visual,
    };
    return ParentGenotype(mutations: mutations, gender: gender);
  }

  /// Maps [BirdColor] to mutation IDs where mapping is unambiguous.
  static List<String> colorToMutationIds(BirdColor color) {
    return switch (color) {
      BirdColor.blue => ['blue'],
      BirdColor.grey => ['grey'],
      BirdColor.violet => ['violet'],
      BirdColor.lutino => ['ino'],
      BirdColor.albino => ['ino', 'blue'],
      BirdColor.cinnamon => ['cinnamon'],
      BirdColor.opaline => ['opaline'],
      BirdColor.spangle => ['spangle'],
      BirdColor.clearwing => ['clearwing'],
      BirdColor.pied ||
      BirdColor.green ||
      BirdColor.yellow ||
      BirdColor.white ||
      BirdColor.other ||
      BirdColor.unknown => const [],
    };
  }

  /// Serializes genotype mutation keys for [Bird.mutations] payload.
  static List<String>? mutationIdsFromGenotype(ParentGenotype genotype) {
    if (genotype.mutations.isEmpty) return null;
    return genotype.mutations.keys.toList();
  }

  /// Serializes genotype allele states for [Bird.genotypeInfo] payload.
  static Map<String, String>? genotypeInfoFromGenotype(
    ParentGenotype genotype,
  ) {
    if (genotype.mutations.isEmpty) return null;
    return {
      for (final entry in genotype.mutations.entries)
        entry.key: entry.value.name,
    };
  }
}
