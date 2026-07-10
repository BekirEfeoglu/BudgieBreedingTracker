import 'package:easy_localization/easy_localization.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/linkage_catalog.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
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
