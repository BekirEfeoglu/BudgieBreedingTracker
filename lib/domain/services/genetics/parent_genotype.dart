import 'dart:collection';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';

/// Allele state for a single mutation locus in a parent bird.
enum AlleleState {
  /// Homozygous mutant (aa) - visually shows the mutation.
  visual,

  /// Heterozygous (Aa) - carries but does not show (autosomal recessive).
  /// For sex-linked: male only (Z*Z+).
  carrier,

  /// Split for two different sex-linked alleles on each Z chromosome.
  /// Male only (e.g., Z_ino/Z_cin = Lacewing split).
  split;

  String get abbreviation => switch (this) {
    AlleleState.visual => 'V',
    AlleleState.carrier => 'T',
    AlleleState.split => 'S',
  };
}

/// Represents the complete genotype of a parent bird for genetics calculation.
///
/// Maps each selected mutation ID to its [AlleleState], along with the
/// bird's gender (important for sex-linked inheritance).
class ParentGenotype {
  /// Map of mutation ID to its allele state (unmodifiable).
  final Map<String, AlleleState> mutations;

  /// Gender of the parent bird.
  final BirdGender gender;

  /// Creates a genotype wrapping the given mutations in an unmodifiable view.
  ParentGenotype({
    required Map<String, AlleleState> mutations,
    required this.gender,
  }) : mutations = UnmodifiableMapView(Map.of(mutations));

  /// Creates an empty genotype for the given gender.
  const ParentGenotype.empty({required this.gender}) : mutations = const {};

  /// Whether this parent has any mutations selected.
  bool get isEmpty => mutations.isEmpty;

  /// Whether this parent has any mutations selected.
  bool get isNotEmpty => mutations.isNotEmpty;

  /// All mutation IDs that are visually expressed.
  Set<String> get visualMutations => mutations.entries
      .where((e) => e.value == AlleleState.visual)
      .map((e) => e.key)
      .toSet();

  /// All mutation IDs that are carried (heterozygous).
  Set<String> get carrierMutations => mutations.entries
      .where((e) => e.value == AlleleState.carrier)
      .map((e) => e.key)
      .toSet();

  /// All mutation IDs (regardless of allele state).
  Set<String> get allMutationIds => mutations.keys.toSet();

  /// Whether the parent visually expresses the given mutation.
  bool hasVisual(String mutationId) =>
      mutations[mutationId] == AlleleState.visual;

  /// Whether the parent carries (but doesn't show) the given mutation.
  bool hasCarrier(String mutationId) =>
      mutations[mutationId] == AlleleState.carrier;

  /// Gets the allele state for a mutation, or null if not present.
  AlleleState? getState(String mutationId) => mutations[mutationId];

  /// Whether adding [mutationId] would exceed the allelic locus limit.
  ///
  /// Diploid organisms have at most 2 alleles per locus.
  /// Females are hemizygous at sex-linked loci (max 1 allele).
  bool canAddMutation(String mutationId) {
    if (mutations.containsKey(mutationId)) return true; // updating existing
    final record = MutationDatabase.getById(mutationId);
    if (record?.locusId == null) return true; // independent mutation
    final currentAtLocus = getMutationsAtLocus(record!.locusId!);
    final maxAlleles = (record.isSexLinked && gender == BirdGender.female)
        ? 1
        : 2;
    return currentAtLocus.length < maxAlleles;
  }

  /// Returns a copy with the given mutation added or updated.
  ParentGenotype withMutation(String mutationId, AlleleState state) {
    return ParentGenotype(
      mutations: {...mutations, mutationId: state},
      gender: gender,
    );
  }

  /// Returns a copy with the mutation added only if locus limit allows.
  ///
  /// Returns `this` unchanged if adding would violate the 2-allele limit.
  ParentGenotype withMutationIfValid(String mutationId, AlleleState state) {
    if (!canAddMutation(mutationId)) return this;
    return withMutation(mutationId, state);
  }

  /// Returns a copy with the given mutation removed.
  ParentGenotype withoutMutation(String mutationId) {
    final updated = Map<String, AlleleState>.from(mutations)
      ..remove(mutationId);
    return ParentGenotype(mutations: updated, gender: gender);
  }

  /// Returns a copy with the allele state toggled for the given mutation.
  /// For autosomal recessive: visual (aa) → carrier (Aa) → visual
  /// For autosomal dominant/incomplete dominant: visual (DF/AA) → carrier (SF/Aa) → visual
  /// For sex-linked male: visual → carrier → split → visual
  ///
  /// Birds with [BirdGender.unknown] are treated as autosomal-only
  /// (sex-linked toggle falls back to visual↔carrier).
  ParentGenotype toggleState(String mutationId, {bool isSexLinked = false}) {
    final current = mutations[mutationId];
    if (current == null) return this;

    final AlleleState next;
    if (isSexLinked && gender == BirdGender.male) {
      // Males can be visual, carrier, or split for sex-linked
      next = switch (current) {
        AlleleState.visual => AlleleState.carrier,
        AlleleState.carrier => AlleleState.split,
        AlleleState.split => AlleleState.visual,
      };
    } else if (isSexLinked && gender == BirdGender.female) {
      // Females are hemizygous for sex-linked: always visual
      next = AlleleState.visual;
    } else {
      // Autosomal (or unknown gender fallback): toggle between visual and carrier
      next = switch (current) {
        AlleleState.visual => AlleleState.carrier,
        AlleleState.carrier => AlleleState.visual,
        AlleleState.split => AlleleState.visual,
      };
    }

    return withMutation(mutationId, next);
  }

  /// Returns a copy with all mutations cleared.
  ParentGenotype clear() => ParentGenotype.empty(gender: gender);

  /// Returns the mutation IDs belonging to the given allelic series [locusId].
  /// Useful for checking how many alleles the user selected at one locus.
  List<String> getMutationsAtLocus(String locusId) {
    return mutations.keys.where((id) {
      final record = MutationDatabase.getById(id);
      return record?.locusId == locusId;
    }).toList();
  }

  /// Returns the count of selected mutations at a given allelic locus.
  int countAtLocus(String locusId) => getMutationsAtLocus(locusId).length;
}
