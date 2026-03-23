import 'dart:convert';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

/// Parses stored results JSON back to OffspringResult list.
List<OffspringResult> parseHistoryResults(String resultsJson) {
  try {
    final decoded = jsonDecode(resultsJson);
    if (decoded is! List) return [];

    final parsed = <OffspringResult>[];
    for (final rawEntry in decoded) {
      if (rawEntry is! Map) continue;
      final json = <String, dynamic>{};
      for (final entry in rawEntry.entries) {
        final key = entry.key;
        if (key is String) {
          json[key] = entry.value;
        }
      }
      final phenotype = json['phenotype'] as String? ?? '';
      parsed.add(
        OffspringResult(
          phenotype: phenotype,
          probability: (json['probability'] as num?)?.toDouble() ?? 0,
          genotype: json['genotype'] as String?,
          sex: _parseOffspringSex(json['sex'] as String?),
          isCarrier:
              json['isCarrier'] as bool? ?? _hasLegacyCarrierSuffix(phenotype),
          compoundPhenotype: json['compoundPhenotype'] as String?,
          visualMutations: _parseStringList(json['visualMutations']),
          carriedMutations: _parseStringList(json['carriedMutations']),
          maskedMutations: _parseStringList(json['maskedMutations']),
          lethalCombinationIds: _parseStringList(json['lethalCombinationIds']),
          doubleFactorIds: _parseStringList(json['doubleFactorIds']).toSet(),
        ),
      );
    }
    return parsed;
  } catch (e, st) {
    AppLogger.error('[GeneticsHistory] Failed to parse history results', e, st);
    return [];
  }
}

OffspringSex _parseOffspringSex(String? value) {
  return switch (value) {
    'male' => OffspringSex.male,
    'female' => OffspringSex.female,
    _ => OffspringSex.both,
  };
}

List<String> _parseStringList(dynamic raw) {
  if (raw is! List) return const [];
  return raw.whereType<String>().toList();
}

bool _hasLegacyCarrierSuffix(String phenotype) {
  return RegExp(r'\bcarrier\)', caseSensitive: false).hasMatch(phenotype);
}

/// Converts stored genotype map back to ParentGenotype.
///
/// Resolves legacy mutation IDs (lutino→ino, albino→ino, etc.)
/// for backward compatibility with saved history entries.
ParentGenotype parseStoredGenotype(
  Map<String, String> stored,
  BirdGender gender,
) {
  final mutations = <String, AlleleState>{};
  for (final entry in stored.entries) {
    final resolvedId = MutationDatabase.resolveId(entry.key);
    final state = switch (entry.value) {
      'visual' => AlleleState.visual,
      'carrier' => AlleleState.carrier,
      'split' => AlleleState.split,
      _ => AlleleState.visual,
    };
    mutations[resolvedId] = state;
  }
  return ParentGenotype(mutations: mutations, gender: gender);
}
