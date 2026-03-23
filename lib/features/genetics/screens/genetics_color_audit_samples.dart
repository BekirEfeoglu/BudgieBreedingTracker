/// Sample data for the genetics color audit screen.
///
/// Organized into 3 boards covering 36 phenotypes:
/// - Primary: base colors (green + blue series, ino)
/// - Advanced: wing/body modifiers (cinnamon, opaline, spangle, dilute, etc.)
/// - Compound: complex combinations and rare variants
class AuditSample {
  final String title;
  final String note;
  final String phenotype;
  final List<String> visualMutations;

  const AuditSample({
    required this.title,
    required this.note,
    required this.phenotype,
    required this.visualMutations,
  });
}

// ---------------------------------------------------------------------------
// Board 1: Base color spectrum (12 samples)
// ---------------------------------------------------------------------------
const primaryAuditSamples = <AuditSample>[
  // Green series
  AuditSample(
    title: 'Light Green',
    note: 'Base green (WBO 375)',
    phenotype: 'Light Green',
    visualMutations: [],
  ),
  AuditSample(
    title: 'Dark Green',
    note: 'Single dark factor',
    phenotype: 'Dark Green',
    visualMutations: ['dark_factor'],
  ),
  AuditSample(
    title: 'Olive',
    note: 'Double dark factor',
    phenotype: 'Olive',
    visualMutations: ['dark_factor'],
  ),
  AuditSample(
    title: 'Grey-Green',
    note: 'Grey modifier',
    phenotype: 'Grey-Green',
    visualMutations: ['grey'],
  ),

  // Blue series
  AuditSample(
    title: 'Skyblue',
    note: 'Base blue (WBO 310)',
    phenotype: 'Skyblue',
    visualMutations: ['blue'],
  ),
  AuditSample(
    title: 'Cobalt',
    note: 'Single dark factor',
    phenotype: 'Cobalt',
    visualMutations: ['blue', 'dark_factor'],
  ),
  AuditSample(
    title: 'Mauve',
    note: 'Double dark factor',
    phenotype: 'Mauve',
    visualMutations: ['blue', 'dark_factor'],
  ),
  AuditSample(
    title: 'Grey',
    note: 'Grey modifier',
    phenotype: 'Grey',
    visualMutations: ['blue', 'grey'],
  ),
  AuditSample(
    title: 'Violet',
    note: 'Visual violet',
    phenotype: 'Visual Violet Skyblue',
    visualMutations: ['blue', 'violet'],
  ),
  AuditSample(
    title: 'Aqua',
    note: 'Turquoise family',
    phenotype: 'Aqua',
    visualMutations: ['aqua'],
  ),

  // Ino
  AuditSample(
    title: 'Lutino',
    note: 'Yellow + red eye',
    phenotype: 'Lutino',
    visualMutations: ['ino'],
  ),
  AuditSample(
    title: 'Albino',
    note: 'White + red eye',
    phenotype: 'Albino',
    visualMutations: ['ino', 'blue'],
  ),
];

// ---------------------------------------------------------------------------
// Board 2: Wing/body modifiers (12 samples)
// ---------------------------------------------------------------------------
const advancedAuditSamples = <AuditSample>[
  AuditSample(
    title: 'Cinnamon',
    note: 'Brown wing markings',
    phenotype: 'Cinnamon Skyblue',
    visualMutations: ['blue', 'cinnamon'],
  ),
  AuditSample(
    title: 'Opaline',
    note: 'Reduced head stripes',
    phenotype: 'Opaline Light Green',
    visualMutations: ['opaline'],
  ),
  AuditSample(
    title: 'Spangle',
    note: 'Reversed wing pattern',
    phenotype: 'Spangle Light Green',
    visualMutations: ['spangle'],
  ),
  AuditSample(
    title: 'DF Spangle',
    note: 'Near-white body',
    phenotype: 'Double Factor Spangle',
    visualMutations: ['blue', 'spangle'],
  ),
  AuditSample(
    title: 'Greywing',
    note: 'Grey wings + diluted',
    phenotype: 'Skyblue Greywing',
    visualMutations: ['blue', 'greywing'],
  ),
  AuditSample(
    title: 'Clearwing',
    note: 'Clear wing panels',
    phenotype: 'Clearwing Light Green',
    visualMutations: ['clearwing'],
  ),
  AuditSample(
    title: 'Dilute',
    note: 'Overall softened',
    phenotype: 'Dilute Skyblue',
    visualMutations: ['blue', 'dilute'],
  ),
  AuditSample(
    title: 'Pallid',
    note: 'Subtle dilution',
    phenotype: 'Pallid Skyblue',
    visualMutations: ['blue', 'pallid'],
  ),
  AuditSample(
    title: 'English Fallow',
    note: 'Warm taupe wings',
    phenotype: 'English Fallow Light Green',
    visualMutations: ['fallow_english'],
  ),
  AuditSample(
    title: 'Dom. Clearbody',
    note: '48% body lightening',
    phenotype: 'Dominant Clearbody Skyblue',
    visualMutations: ['blue', 'dominant_clearbody'],
  ),
  AuditSample(
    title: 'Texas Clearbody',
    note: '30% body lightening',
    phenotype: 'Skyblue Texas Clearbody',
    visualMutations: ['blue', 'texas_clearbody'],
  ),
  AuditSample(
    title: 'Saddleback',
    note: 'Mantle highlight',
    phenotype: 'Saddleback Light Green',
    visualMutations: ['saddleback'],
  ),
];

// ---------------------------------------------------------------------------
// Board 3: Compound & special phenotypes (12 samples)
// ---------------------------------------------------------------------------
const compoundAuditSamples = <AuditSample>[
  // Dark / special series
  AuditSample(
    title: 'Blackface',
    note: 'Black mask',
    phenotype: 'Blackface Light Green',
    visualMutations: ['blackface'],
  ),
  AuditSample(
    title: 'SF Anthracite',
    note: 'Deep green',
    phenotype: 'Light Green Single Factor Anthracite',
    visualMutations: ['anthracite'],
  ),
  AuditSample(
    title: 'DF Anthracite',
    note: 'Near-black body',
    phenotype: 'Double Factor Anthracite',
    visualMutations: ['anthracite'],
  ),
  AuditSample(
    title: 'Slate',
    note: 'Deep blue-grey',
    phenotype: 'Slate',
    visualMutations: ['slate'],
  ),

  // Yellowface / Goldenface
  AuditSample(
    title: 'YF Type II',
    note: 'Yellow body suffusion',
    phenotype: 'Yellowface Type II Skyblue',
    visualMutations: ['blue', 'yellowface_type2'],
  ),
  AuditSample(
    title: 'Goldenface',
    note: 'Strong gold tint',
    phenotype: 'Goldenface Skyblue',
    visualMutations: ['blue', 'goldenface'],
  ),

  // Compound mutations
  AuditSample(
    title: 'Opaline Cinnamon',
    note: 'Combined modifiers',
    phenotype: 'Opaline Cinnamon Skyblue',
    visualMutations: ['blue', 'opaline', 'cinnamon'],
  ),
  AuditSample(
    title: 'Rec. Pied',
    note: 'Pied patches, no eye ring',
    phenotype: 'Recessive Pied Light Green',
    visualMutations: ['recessive_pied'],
  ),

  // Special phenotypes
  AuditSample(
    title: 'Creamino',
    note: 'Cream body',
    phenotype: 'Creamino',
    visualMutations: ['ino', 'blue', 'yellowface_type2'],
  ),
  AuditSample(
    title: 'Lacewing',
    note: 'Ino + cinnamon wings',
    phenotype: 'Lacewing',
    visualMutations: ['ino', 'cinnamon'],
  ),
  AuditSample(
    title: 'Dark-Eyed Clear',
    note: 'Pied + spangle clear',
    phenotype: 'Dark-Eyed Clear',
    visualMutations: ['recessive_pied', 'clearwing'],
  ),
  AuditSample(
    title: 'Green Slate',
    note: 'Muted grey-green',
    phenotype: 'Light Green Slate',
    visualMutations: ['slate'],
  ),
];
