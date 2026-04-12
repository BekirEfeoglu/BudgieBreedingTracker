import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_data_compounds.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_data_primary.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_data_sex_linked.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_types.dart';

// Re-export sub-modules so existing deep imports keep working.
export 'package:budgie_breeding_tracker/domain/services/genetics/mutation_data_compounds.dart';
export 'package:budgie_breeding_tracker/domain/services/genetics/mutation_data_primary.dart';
export 'package:budgie_breeding_tracker/domain/services/genetics/mutation_data_sex_linked.dart';

/// Static catalog of budgie (Melopsittacus undulatus) mutations currently
/// modelled by the app.
abstract class MutationData {
  /// All known budgie mutations.
  static const List<BudgieMutationRecord> allMutations = [
    ...MutationDataPrimary.coreMutations,
    ...MutationDataSexLinked.sexLinkedAndRareMutations,
    ...MutationDataCompounds.yellowfaceMutations,
  ];

  /// Legacy ID → current ID mapping for backward compatibility with saved data.
  static const legacyIdMap = MutationDataCompounds.legacyIdMap;
}
