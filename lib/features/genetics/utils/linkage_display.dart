import 'package:easy_localization/easy_localization.dart';

import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/linkage_catalog.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_localizer.dart';

/// Localized display name for a linked mutation [id] (e.g. `'ino'`) via
/// [MutationDatabase] + [PhenotypeLocalizer]. Falls back to the raw id if the
/// mutation isn't found.
String linkageMutationName(String id) {
  final record = MutationDatabase.getById(id);
  if (record == null) return id;
  return PhenotypeLocalizer.localizePhenotype(record.name);
}

/// Localized evidence suffix for a linkage distance, or `''` for measured
/// distances (which need no qualifier). Keeps derived/estimated rates from
/// reading as directly-measured values in the UI.
String linkageEvidenceSuffix(LinkageEvidence evidence) {
  return switch (evidence) {
    LinkageEvidence.measured => '',
    LinkageEvidence.derived => ' (${'genetics.linkage_derived'.tr()})',
    LinkageEvidence.estimated => ' (${'genetics.linkage_estimated'.tr()})',
  };
}

/// The tightest known [LinkageCatalog] pair for which [father] is a male
/// heterozygous (carrier or split) at both loci, or `null` when no such pair
/// exists.
typedef ActiveLinkagePair = ({String id1, String id2, LinkagePairInfo info});

/// Returns the tightest Z-linkage pair eligible for an explicit phase
/// control on [father]'s genotype.
///
/// A pair is eligible when [father] is male and heterozygous
/// ([AlleleState.carrier] or [AlleleState.split]) at both loci of a known
/// [LinkageCatalog] pair. Mirrors the engine's own tightest-linkage
/// selection (`mendelian_calculator.dart`'s `tryLinkPair` priority order),
/// which always resolves to the globally tightest pair among the father's
/// heterozygous linkage participants since only four Z-linkage tokens exist.
/// Two heterozygous alleles at the *same* locus (e.g. `pallid` + `pearly`,
/// both normalizing to the `ino` token) are not a linked pair and are
/// excluded.
///
/// Mirrors the engine's compound ino-locus heterozygote exclusion
/// (`mendelian_calculator.dart`'s `inoLocusHetAllele` resolution): when
/// [father] is heterozygous at two or more *distinct* ino-locus alleles
/// (`ino`, `pallid`, `pearly`, `texas_clearbody`), the engine skips ino-locus
/// Z-linkage entirely for that cross — the allelic series calculator handles
/// it instead. A single heterozygous ino-locus allele still participates in
/// linkage normally; non-ino pairs (opaline-cinnamon, opaline-slate,
/// cinnamon-slate) are unaffected either way.
ActiveLinkagePair? activeLinkagePairForFather(ParentGenotype father) {
  if (father.gender != BirdGender.male) return null;

  final heterozygousIds = father.mutations.entries
      .where(
        (entry) =>
            entry.value == AlleleState.carrier ||
            entry.value == AlleleState.split,
      )
      .map((entry) => entry.key)
      .where((id) => LinkageCatalog.normalizeToken(id) != null)
      .toList();

  final hetInoLocusAlleleCount = heterozygousIds
      .where(
        (id) =>
            MutationDatabase.getById(id)?.locusId ==
            GeneticsConstants.locusIno,
      )
      .toSet()
      .length;
  final excludeInoLocus = hetInoLocusAlleleCount >= 2;

  ActiveLinkagePair? tightest;
  for (var i = 0; i < heterozygousIds.length; i++) {
    for (var j = i + 1; j < heterozygousIds.length; j++) {
      final id1 = heterozygousIds[i];
      final id2 = heterozygousIds[j];
      if (excludeInoLocus &&
          (LinkageCatalog.normalizeToken(id1) == LinkageCatalog.inoLocusToken ||
              LinkageCatalog.normalizeToken(id2) ==
                  LinkageCatalog.inoLocusToken)) {
        continue;
      }
      final info = LinkageCatalog.lookup(id1, id2);
      if (info == null) continue;
      if (tightest == null ||
          info.recombinationRate < tightest.info.recombinationRate) {
        tightest = (id1: id1, id2: id2, info: info);
      }
    }
  }
  return tightest;
}
