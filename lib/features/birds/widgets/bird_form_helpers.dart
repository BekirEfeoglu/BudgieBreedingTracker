import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_form_providers.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/bird_genotype_mapper.dart';

export 'package:budgie_breeding_tracker/features/genetics/utils/bird_genotype_mapper.dart'
    show BirdGenotypeMapper;

/// Finds the next sequential name for a bird using the given [prefix].
///
/// E.g., if existing names are "Kus1", "Kus3", returns "Kus4".
String nextDefaultBirdName(String prefix, List<String> existingNames) {
  final regex = RegExp('^${RegExp.escape(prefix)}(\\d+)\$');
  var maxNumber = 0;
  for (final name in existingNames) {
    final match = regex.firstMatch(name.trim());
    if (match == null) continue;
    final current = int.tryParse(match.group(1)!);
    if (current != null && current > maxNumber) {
      maxNumber = current;
    }
  }
  return '$prefix${maxNumber + 1}';
}

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

/// Prepared genotype data for bird form submission.
class BirdGenotypeData {
  final List<String>? mutationIds;
  final Map<String, String>? genotypeInfo;

  const BirdGenotypeData({
    required this.mutationIds,
    required this.genotypeInfo,
  });
}

/// Prepares genotype, mutation IDs, and genotype info for saving a bird.
BirdGenotypeData prepareBirdGenotypeData({
  required ParentGenotype genotype,
  required BirdGender gender,
  required BirdColor? colorMutation,
}) {
  final selectedGenotype = normalizeGenotypeForGender(
    genotype: ParentGenotype(
      mutations: Map<String, AlleleState>.from(genotype.mutations),
      gender: gender,
    ),
    gender: gender,
  );
  final genotypeForSave = selectedGenotype.isNotEmpty
      ? selectedGenotype
      : BirdGenotypeMapper.genotypeFromColor(
          gender: gender,
          color: colorMutation,
        );
  return BirdGenotypeData(
    mutationIds: BirdGenotypeMapper.mutationIdsFromGenotype(genotypeForSave),
    genotypeInfo: BirdGenotypeMapper.genotypeInfoFromGenotype(genotypeForSave),
  );
}

/// Shows a success snack bar with optional premium limit warning, then pops.
void handleBirdFormSuccess(
  BuildContext context, {
  required int? remainingBirds,
}) {
  final snackBar =
      (remainingBirds != null && remainingBirds <= 5 && remainingBirds > 0)
      ? SnackBar(
          content: Text(
            'premium.limit_approaching_birds'.tr(args: ['$remainingBirds']),
          ),
          action: SnackBarAction(
            label: 'premium.try_free_trial'.tr(),
            onPressed: () => context.push(AppRoutes.premium),
          ),
        )
      : SnackBar(content: Text('common.saved_successfully'.tr()));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
  context.pop();
}

/// Shows the bird limit reached dialog with an upgrade CTA.
void showBirdLimitDialog(
  BuildContext context, {
  required String? errorMessage,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('premium.title'.tr()),
      content: Text(errorMessage ?? ''),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('common.cancel'.tr()),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            context.push(AppRoutes.premium);
          },
          child: Text('premium.upgrade_to_unlock'.tr()),
        ),
      ],
    ),
  );
}

/// Submits the bird form by delegating to the notifier.
void submitBirdForm({
  required BirdFormNotifier notifier,
  required String userId,
  required Bird? existingBird,
  required String name,
  required BirdGender gender,
  required Species species,
  required BirdColor? colorMutation,
  required ParentGenotype genotype,
  required String ringNumber,
  required String cageNumber,
  required DateTime? birthDate,
  required String? fatherId,
  required String? motherId,
  required String colorNoteText,
  required String notesText,
}) {
  final notes = buildNotes(
    colorMutation: colorMutation,
    colorNoteText: colorNoteText,
    notesText: notesText,
  );
  final gData = prepareBirdGenotypeData(
    genotype: genotype,
    gender: gender,
    colorMutation: colorMutation,
  );
  final ring = ringNumber.isEmpty ? null : ringNumber;
  final cage = cageNumber.isEmpty ? null : cageNumber;

  if (existingBird != null) {
    notifier.updateBird(
      existingBird.copyWith(
        name: name,
        gender: gender,
        species: species,
        colorMutation: colorMutation,
        ringNumber: ring,
        birthDate: birthDate,
        fatherId: fatherId,
        motherId: motherId,
        cageNumber: cage,
        notes: notes,
        mutations: gData.mutationIds,
        genotypeInfo: gData.genotypeInfo,
      ),
    );
  } else {
    notifier.createBird(
      userId: userId,
      name: name,
      gender: gender,
      species: species,
      colorMutation: colorMutation,
      ringNumber: ring,
      birthDate: birthDate,
      fatherId: fatherId,
      motherId: motherId,
      cageNumber: cage,
      notes: notes,
      mutations: gData.mutationIds,
      genotypeInfo: gData.genotypeInfo,
    );
  }
}
