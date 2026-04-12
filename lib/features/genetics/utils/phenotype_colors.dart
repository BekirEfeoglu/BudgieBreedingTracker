import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';

/// Mutation ID → color mapping with priority ordering.
///
/// Entries are ordered by visual prominence: compound effects first,
/// then individual mutations from most distinctive to most common.
/// The map doubles as both color lookup and priority source — iteration
/// order of a Dart `Map` literal is insertion order.
const mutationIdColorMap = <String, Color>{
  'ino': AppColors.phenotypeLutino,
  'pallid': AppColors.phenotypeLacewing,
  'texas_clearbody': AppColors.phenotypeTexas,
  'cinnamon': AppColors.phenotypeCinnamon,
  'opaline': AppColors.phenotypeOpaline,
  'pearly': AppColors.phenotypeSpangle,
  'spangle': AppColors.phenotypeSpangle,
  'greywing': AppColors.phenotypeGreywing,
  'clearwing': AppColors.phenotypeClearwing,
  'recessive_pied': AppColors.phenotypePied,
  'dominant_pied': AppColors.phenotypePied,
  'clearflight_pied': AppColors.phenotypePied,
  'dutch_pied': AppColors.phenotypePied,
  'dark_factor': AppColors.phenotypeDarkFactor,
  'violet': AppColors.phenotypeViolet,
  'turquoise': AppColors.phenotypeViolet,
  'aqua': AppColors.phenotypeViolet,
  'goldenface': AppColors.phenotypeLutino,
  'bluefactor_1': AppColors.budgieBlue,
  'bluefactor_2': AppColors.budgieBlue,
  'grey': AppColors.phenotypeGrey,
  'anthracite': AppColors.phenotypeGrey,
  'blue': AppColors.budgieBlue,
  'yellowface_type1': AppColors.budgieBlue,
  'yellowface_type2': AppColors.budgieBlue,
  'dilute': AppColors.phenotypeDilute,
  'fallow_english': AppColors.phenotypeFallow,
  'fallow_german': AppColors.phenotypeFallow,
  'slate': AppColors.phenotypeSlate,
  'crested_tufted': AppColors.phenotypeCrested,
  'crested_half_circular': AppColors.phenotypeCrested,
  'crested_full_circular': AppColors.phenotypeCrested,
  'saddleback': AppColors.phenotypeSaddleback,
  'dominant_clearbody': AppColors.phenotypeTexas,
  'blackface': AppColors.phenotypeGrey,
};

/// Blue-series mutation IDs (used for Albino vs Lutino compound detection).
const _blueSeriesIds = {
  'blue',
  'yellowface_type1',
  'yellowface_type2',
  'goldenface',
  'aqua',
  'turquoise',
  'bluefactor_1',
  'bluefactor_2',
};

/// Maps mutation IDs to indicator colors with epistasis-aware compound detection.
///
/// Preferred over [phenotypeColor] when mutation IDs are available, as it is
/// locale-independent and uses stable identifiers.
Color phenotypeColorFromMutations(List<String> visualMutationIds) {
  if (visualMutationIds.isEmpty) return AppColors.neutral500;

  final ids = visualMutationIds.toSet();

  // Compound phenotype detection (epistasis-aware)
  final hasIno = ids.contains('ino');
  if (hasIno) {
    final hasCinnamon = ids.contains('cinnamon');
    if (hasCinnamon) return AppColors.phenotypeLacewing; // Lacewing
    final hasPallid = ids.contains('pallid');
    if (hasPallid) return AppColors.phenotypeLacewing; // PallidIno (Lacewing)
    final isBlue = ids.any(_blueSeriesIds.contains);
    if (isBlue) return AppColors.phenotypeAlbino; // Albino / Creamino
    return AppColors.phenotypeLutino; // Lutino
  }

  // Violet + blue + dark_factor = Visual Violet
  if (ids.contains('violet') && ids.any(_blueSeriesIds.contains)) {
    return AppColors.phenotypeViolet;
  }

  // Grey compound: grey + blue-series = Grey, grey alone = Grey-Green
  if (ids.contains('grey')) {
    return AppColors.phenotypeGrey;
  }

  // Individual mutation: O(1) lookup using map insertion-order iteration
  for (final MapEntry(key: id, value: color) in mutationIdColorMap.entries) {
    if (ids.contains(id)) return color;
  }

  return AppColors.neutral500;
}

/// Fallback keyword→color mapping for phenotype strings.
/// Used only when mutation IDs are not available (e.g., legacy history entries).
final _phenotypeColorMap = <(String, Color)>[
  ('albino', AppColors.phenotypeAlbino),
  ('lutino', AppColors.phenotypeLutino),
  ('lacewing', AppColors.phenotypeLacewing),
  ('pallid', AppColors.phenotypeLacewing),
  ('creamino', AppColors.phenotypeLutino),
  ('cinnamon', AppColors.phenotypeCinnamon),
  ('opaline', AppColors.phenotypeOpaline),
  ('pearly', AppColors.phenotypeSpangle),
  ('spangle', AppColors.phenotypeSpangle),
  ('greywing', AppColors.phenotypeGreywing),
  ('clearwing', AppColors.phenotypeClearwing),
  ('pied', AppColors.phenotypePied),
  ('dark factor', AppColors.phenotypeDarkFactor),
  ('violet', AppColors.phenotypeViolet),
  ('turquoise', AppColors.phenotypeViolet),
  ('aqua', AppColors.phenotypeViolet),
  ('goldenface', AppColors.phenotypeLutino),
  ('blue factor', AppColors.budgieBlue),
  ('grey', AppColors.phenotypeGrey),
  ('anthracite', AppColors.phenotypeGrey),
  ('blue', AppColors.budgieBlue),
  ('green', AppColors.budgieGreen),
  ('dilute', AppColors.phenotypeDilute),
  ('fallow', AppColors.phenotypeFallow),
  ('slate', AppColors.phenotypeSlate),
  ('crested', AppColors.phenotypeCrested),
  ('saddleback', AppColors.phenotypeSaddleback),
  ('texas', AppColors.phenotypeTexas),
  ('carrier', AppColors.neutral400),
  ('normal', AppColors.neutral500),
];

/// Maps phenotype keywords to indicator colors (string-based fallback).
///
/// Expects raw English phenotype names (e.g. "Albino", "Blue Opaline").
/// Prefer [phenotypeColorFromMutations] when mutation IDs are available.
Color phenotypeColor(String phenotype) {
  final lower = phenotype.toLowerCase();
  for (final (keyword, color) in _phenotypeColorMap) {
    if (lower.contains(keyword)) return color;
  }
  return AppColors.neutral500;
}
