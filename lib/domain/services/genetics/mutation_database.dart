// Re-export types and data so existing imports keep working.
export 'package:budgie_breeding_tracker/domain/services/genetics/mutation_types.dart';
export 'package:budgie_breeding_tracker/domain/services/genetics/mutation_data.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_data.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_types.dart';

/// Curated reference database of budgie (Melopsittacus undulatus) mutations.
///
/// Contains the mutations currently modelled by the calculator with
/// inheritance patterns, allele symbols, and visual effects.
abstract class MutationDatabase {
  /// All known budgie mutations.
  static const List<BudgieMutationRecord> allMutations =
      MutationData.allMutations;

  /// Index for fast ID lookup (lazily built).
  static Map<String, BudgieMutationRecord>? _index;

  static Map<String, BudgieMutationRecord> get _mutationIndex {
    return _index ??= {for (final m in allMutations) m.id: m};
  }

  /// Get all mutations.
  static List<BudgieMutationRecord> getAll() => allMutations;

  /// Find a mutation by its unique ID.
  /// Also resolves legacy IDs from older saved data.
  static BudgieMutationRecord? getById(String id) =>
      _mutationIndex[id] ?? _mutationIndex[MutationData.legacyIdMap[id]];

  /// Get mutations by inheritance type.
  static List<BudgieMutationRecord> getByInheritanceType(InheritanceType type) {
    return allMutations.where((m) => m.inheritanceType == type).toList();
  }

  /// Get mutations by category.
  static List<BudgieMutationRecord> getByCategory(String category) {
    return allMutations.where((m) => m.category == category).toList();
  }

  /// Get all unique categories.
  static List<String> getCategories() {
    return allMutations.map((m) => m.category).toSet().toList()..sort();
  }

  /// Get sex-linked mutations only.
  static List<BudgieMutationRecord> getSexLinked() {
    return allMutations.where((m) => m.isSexLinked).toList();
  }

  /// Get autosomal mutations only.
  static List<BudgieMutationRecord> getAutosomal() {
    return allMutations.where((m) => m.isAutosomal).toList();
  }

  /// Find a mutation by name (case-insensitive).
  static BudgieMutationRecord? getByName(String name) {
    final lowerName = name.toLowerCase();
    for (final m in allMutations) {
      if (m.name.toLowerCase() == lowerName) return m;
    }
    return null;
  }

  /// Search mutations by keyword in name or description.
  static List<BudgieMutationRecord> search(String query) {
    final lowerQuery = query.toLowerCase();
    return allMutations.where((m) {
      return m.name.toLowerCase().contains(lowerQuery) ||
          m.description.toLowerCase().contains(lowerQuery) ||
          m.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get the total count of mutations in the database.
  static int get count => allMutations.length;

  /// Returns all mutations belonging to the given allelic series [locusId].
  static List<BudgieMutationRecord> getByLocusId(String locusId) {
    return allMutations.where((m) => m.locusId == locusId).toList();
  }

  /// Returns all unique allelic series locus IDs in the database.
  static Set<String> getAllelicLocusIds() {
    return allMutations
        .where((m) => m.locusId != null)
        .map((m) => m.locusId!)
        .toSet();
  }

  /// Resolves a potentially legacy ID to the current canonical ID.
  /// Returns the input ID if no mapping exists.
  static String resolveId(String id) => MutationData.legacyIdMap[id] ?? id;
}
