import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';

/// Stream of all genetics history entries for the current user.
final geneticsHistoryStreamProvider =
    StreamProvider.family<List<GeneticsHistory>, String>((ref, userId) {
  final dao = ref.watch(geneticsHistoryDaoProvider);
  return dao.watchAll(userId);
});

/// Single genetics history entry by ID.
final geneticsHistoryByIdProvider =
    StreamProvider.family<GeneticsHistory?, String>((ref, id) {
  final dao = ref.watch(geneticsHistoryDaoProvider);
  return dao.watchById(id);
});

/// Notifier for saving and deleting genetics history entries.
class GeneticsHistorySaveNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Saves the current calculation to history.
  Future<bool> saveCurrentCalculation({String? notes}) async {
    state = const AsyncLoading();
    try {
      final father = ref.read(fatherGenotypeProvider);
      final mother = ref.read(motherGenotypeProvider);
      final results = ref.read(offspringResultsProvider);
      final userId = ref.read(currentUserIdProvider);

      if (results == null || results.isEmpty) {
        state = const AsyncData(null);
        return false;
      }

      final history = GeneticsHistory(
        id: const Uuid().v4(),
        userId: userId,
        fatherGenotype: _genotypeToMap(father),
        motherGenotype: _genotypeToMap(mother),
        resultsJson: jsonEncode(_resultsToJson(results)),
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final dao = ref.read(geneticsHistoryDaoProvider);
      await dao.insertItem(history);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Deletes a history entry by soft delete.
  Future<void> deleteEntry(String id) async {
    state = const AsyncLoading();
    try {
      final dao = ref.read(geneticsHistoryDaoProvider);
      await dao.softDelete(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  static Map<String, String> _genotypeToMap(ParentGenotype genotype) {
    return genotype.mutations.map(
      (key, value) => MapEntry(key, value.name),
    );
  }

  static List<Map<String, dynamic>> _resultsToJson(
      List<OffspringResult> results) {
    return results
        .map((r) => {
              'phenotype': r.phenotype,
              'probability': r.probability,
              'genotype': r.genotype,
              'sex': r.sex.name,
              'isCarrier': r.isCarrier,
              if (r.compoundPhenotype != null)
                'compoundPhenotype': r.compoundPhenotype,
              if (r.visualMutations.isNotEmpty)
                'visualMutations': r.visualMutations,
              if (r.carriedMutations.isNotEmpty)
                'carriedMutations': r.carriedMutations,
              if (r.maskedMutations.isNotEmpty)
                'maskedMutations': r.maskedMutations,
              if (r.lethalCombinationIds.isNotEmpty)
                'lethalCombinationIds': r.lethalCombinationIds,
            })
        .toList();
  }
}

final geneticsHistorySaveProvider =
    NotifierProvider<GeneticsHistorySaveNotifier, AsyncValue<void>>(
        GeneticsHistorySaveNotifier.new);

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
          lethalCombinationIds: _parseStringList(
            json['lethalCombinationIds'],
          ),
        ),
      );
    }
    return parsed;
  } catch (_) {
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
    Map<String, String> stored, BirdGender gender) {
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
