/// Z-chromosome linkage rates for sex-linked mutations.
/// Gene order: Opaline — Cinnamon — Ino — Slate.
typedef MutationLinkageEntry = ({String label, int centiMorgans});

const mutationLinkageMap = <String, List<MutationLinkageEntry>>{
  'opaline': [
    (label: 'Ino', centiMorgans: 30),
    (label: 'Cinnamon', centiMorgans: 34),
    (label: 'Slate', centiMorgans: 40),
  ],
  'cinnamon': [
    (label: 'Ino', centiMorgans: 3),
    (label: 'Slate', centiMorgans: 5),
    (label: 'Opaline', centiMorgans: 34),
  ],
  'ino': [
    (label: 'Slate', centiMorgans: 2),
    (label: 'Cinnamon', centiMorgans: 3),
    (label: 'Opaline', centiMorgans: 30),
  ],
  'slate': [
    (label: 'Ino', centiMorgans: 2),
    (label: 'Cinnamon', centiMorgans: 5),
    (label: 'Opaline', centiMorgans: 40),
  ],
  // Pearly, Pallid & Texas Clearbody share the ino locus position.
  'pearly': [
    (label: 'Slate', centiMorgans: 2),
    (label: 'Cinnamon', centiMorgans: 3),
    (label: 'Opaline', centiMorgans: 30),
  ],
  'pallid': [
    (label: 'Slate', centiMorgans: 2),
    (label: 'Cinnamon', centiMorgans: 3),
    (label: 'Opaline', centiMorgans: 30),
  ],
  'texas_clearbody': [
    (label: 'Slate', centiMorgans: 2),
    (label: 'Cinnamon', centiMorgans: 3),
    (label: 'Opaline', centiMorgans: 30),
  ],
};
