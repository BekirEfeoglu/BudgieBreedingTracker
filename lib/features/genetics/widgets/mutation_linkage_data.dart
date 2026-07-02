import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_localizer.dart';

/// Z-chromosome linkage rates for sex-linked mutations.
/// Gene order: Opaline — Cinnamon — Ino — Slate.
typedef MutationLinkageEntry = ({String id, int centiMorgans});

const mutationLinkageMap = <String, List<MutationLinkageEntry>>{
  'opaline': [
    (id: 'ino', centiMorgans: 30),
    (id: 'cinnamon', centiMorgans: 34),
    (id: 'slate', centiMorgans: 40),
  ],
  'cinnamon': [
    (id: 'ino', centiMorgans: 3),
    (id: 'slate', centiMorgans: 5),
    (id: 'opaline', centiMorgans: 34),
  ],
  'ino': [
    (id: 'slate', centiMorgans: 2),
    (id: 'cinnamon', centiMorgans: 3),
    (id: 'opaline', centiMorgans: 30),
  ],
  'slate': [
    (id: 'ino', centiMorgans: 2),
    (id: 'cinnamon', centiMorgans: 5),
    (id: 'opaline', centiMorgans: 40),
  ],
  // Pearly, Pallid & Texas Clearbody share the ino locus position.
  'pearly': [
    (id: 'slate', centiMorgans: 2),
    (id: 'cinnamon', centiMorgans: 3),
    (id: 'opaline', centiMorgans: 30),
  ],
  'pallid': [
    (id: 'slate', centiMorgans: 2),
    (id: 'cinnamon', centiMorgans: 3),
    (id: 'opaline', centiMorgans: 30),
  ],
  'texas_clearbody': [
    (id: 'slate', centiMorgans: 2),
    (id: 'cinnamon', centiMorgans: 3),
    (id: 'opaline', centiMorgans: 30),
  ],
};

/// Localized display name for a linked mutation [id] (e.g. `'ino'`) via
/// [MutationDatabase] + [PhenotypeLocalizer]. Falls back to the raw id if the
/// mutation isn't found.
String linkageMutationName(String id) {
  final record = MutationDatabase.getById(id);
  if (record == null) return id;
  return PhenotypeLocalizer.localizePhenotype(record.name);
}
