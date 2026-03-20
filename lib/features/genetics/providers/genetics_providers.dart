import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/lethal_combination_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_colors.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/genetic_charts.dart';

part 'genetics_parent_providers.dart';
part 'genetics_punnett_providers.dart';
part 'genetics_analysis_providers.dart';
part 'genetics_provider_helpers.dart';

/// Singleton instance of the Mendelian calculator.
final mendelianCalculatorProvider = Provider<MendelianCalculator>((ref) {
  return const MendelianCalculator();
});

/// Calculated offspring results from current genotype selections.
final offspringResultsProvider = Provider<List<OffspringResult>?>((ref) {
  final father = ref.watch(fatherGenotypeProvider);
  final mother = ref.watch(motherGenotypeProvider);

  if (father.isEmpty && mother.isEmpty) return null;

  final calculator = ref.watch(mendelianCalculatorProvider);

  return calculator.calculateFromGenotypes(father: father, mother: mother);
});
