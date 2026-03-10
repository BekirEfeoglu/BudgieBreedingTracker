import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

/// Internal prefix used to embed custom color name inside notes field.
const birdFormColorPrefix = 'color:';

/// Extracts the custom color note embedded at the start of the notes field.
String? extractColorNote(String? notes) {
  if (notes == null || !notes.startsWith(birdFormColorPrefix)) return null;
  final eol = notes.indexOf('\n');
  return eol == -1
      ? notes.substring(birdFormColorPrefix.length)
      : notes.substring(birdFormColorPrefix.length, eol);
}

/// Returns the notes body without the color-note prefix line.
String? notesBody(String? notes) {
  if (notes == null || !notes.startsWith(birdFormColorPrefix)) return notes;
  final eol = notes.indexOf('\n');
  if (eol == -1) return null;
  final body = notes.substring(eol + 1);
  return body.isEmpty ? null : body;
}

/// Builds the combined notes string from color note and user notes.
String? buildNotes({
  required BirdColor? colorMutation,
  required String colorNoteText,
  required String notesText,
}) {
  final colorNote = colorNoteText.trim();
  final notes = notesText.trim();
  if (colorMutation == BirdColor.other && colorNote.isNotEmpty) {
    return notes.isEmpty
        ? '$birdFormColorPrefix$colorNote'
        : '$birdFormColorPrefix$colorNote\n$notes';
  }
  return notes.isEmpty ? null : notes;
}

/// Normalizes genotype selections for the selected [gender].
///
/// Female birds are hemizygous for sex-linked loci, so this function:
/// - forces sex-linked allele states to `visual`
/// - keeps only one selected mutation per sex-linked locus
ParentGenotype normalizeGenotypeForGender({
  required ParentGenotype genotype,
  required BirdGender gender,
}) {
  final normalizedMutations = Map<String, AlleleState>.from(genotype.mutations);
  if (gender != BirdGender.female) {
    return ParentGenotype(mutations: normalizedMutations, gender: gender);
  }

  final keptMutationByLocus = <String, String>{};

  for (final entry in genotype.mutations.entries.toList()) {
    final mutation = MutationDatabase.getById(entry.key);
    if (mutation?.isSexLinked != true) continue;

    final locusId = mutation!.locusId;
    if (locusId != null) {
      final keptMutationId = keptMutationByLocus[locusId];
      if (keptMutationId == null) {
        keptMutationByLocus[locusId] = entry.key;
      } else if (keptMutationId != entry.key) {
        normalizedMutations.remove(entry.key);
        continue;
      }
    }

    if (normalizedMutations[entry.key] != AlleleState.visual) {
      normalizedMutations[entry.key] = AlleleState.visual;
    }
  }

  return ParentGenotype(mutations: normalizedMutations, gender: gender);
}
